import 'package:flutter/material.dart';
import '../constant/entities.dart';
import '../services/event_service.dart';
import 'event_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<List<Event>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _eventsStream = EventService().getEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlikler'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bugün'),
            Tab(text: 'Bu Hafta'),
            Tab(text: 'Tümü'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventListForTab(0),
          _buildEventListForTab(1),
          _buildEventListForTab(2),
        ],
      ),
    );
  }

  Widget _buildEventListForTab(int tabIndex) {
    return StreamBuilder<List<Event>>(
      stream: _eventsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? [];
        List<Event> filteredEvents;

        final now = DateTime.now();
        if (tabIndex == 0) {
          // Bugün
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));
          filteredEvents = events.where((event) {
            final eventDateTime = _combineDateTime(event.date, event.time);
            return eventDateTime.isAfter(todayStart) &&
                eventDateTime.isBefore(todayEnd);
          }).toList();
        } else if (tabIndex == 1) {
          // Bu Hafta
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 7));
          filteredEvents = events.where((event) {
            final eventDateTime = _combineDateTime(event.date, event.time);
            return eventDateTime.isAfter(weekStart) &&
                eventDateTime.isBefore(weekEnd);
          }).toList();
        } else {
          // Tümü
          filteredEvents = events;
        }

        if (filteredEvents.isEmpty) {
          return const Center(child: Text('Etkinlik bulunamadı'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) =>
              EventCard(event: filteredEvents[index]),
        );
      },
    );
  }

  DateTime _combineDateTime(DateTime date, String time) {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
