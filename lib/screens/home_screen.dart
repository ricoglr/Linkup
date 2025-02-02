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
  final EventService _eventService = EventService();
  List<Event> _events = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
    _eventService.addListener(_loadEvents);
  }

  @override
  void dispose() {
    _eventService.removeListener(_loadEvents);
    _tabController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    setState(() {
      _events = List.from(_eventService.events)
        ..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  // Mevcut event filtreleme metodları aynı kalacak
  List<Event> get _todayEvents {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _events.where((event) {
      final eventDateTime = _combineDateTime(event.date, event.time);
      return eventDateTime.isAfter(todayStart) &&
          eventDateTime.isBefore(todayEnd);
    }).toList()
      ..sort((a, b) => _combineDateTime(a.date, a.time)
          .compareTo(_combineDateTime(b.date, b.time)));
  }

  List<Event> get _thisWeekEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    return _events.where((event) {
      return event.date.isAfter(today) && event.date.isBefore(weekEnd);
    }).toList();
  }

  List<Event> get _allEvents {
    final now = DateTime.now();
    return _events.where((event) {
      final eventDateTime = _combineDateTime(event.date, event.time);
      return eventDateTime.isAfter(now);
    }).toList()
      ..sort((a, b) => _combineDateTime(a.date, a.time)
          .compareTo(_combineDateTime(b.date, b.time)));
  }

  List<Event> get _nextOneHoursEvents {
    final now = DateTime.now();
    final threeHoursLater = now.add(const Duration(hours: 1));

    return _events.where((event) {
      final eventDateTime = _combineDateTime(event.date, event.time);
      return eventDateTime.isAfter(now) &&
          eventDateTime.isBefore(threeHoursLater);
    }).toList()
      ..sort((a, b) => _combineDateTime(a.date, a.time)
          .compareTo(_combineDateTime(b.date, b.time)));
  }

  DateTime _combineDateTime(DateTime date, String timeStr) {
    final timeParts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Bottom bar ile aynı renk
    final barColor = isDark
        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
        : Theme.of(context).colorScheme.primary.withOpacity(0.2);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              centerTitle: true,
              backgroundColor: barColor,
              title: Text(
                'Etkinlikler',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Bugün'),
                  Tab(text: 'Bu Hafta'),
                  Tab(text: 'Tümü'),
                ],
              ),
            ),
          ];
        },
        body: CustomScrollView(
          slivers: [
            if (_nextOneHoursEvents.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Yaklaşan Etkinlikler',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _nextOneHoursEvents
                              .map((event) => Card(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.event,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${event.title} (${event.time})',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventList(_todayEvents),
                  _buildEventList(_thisWeekEvents),
                  _buildEventList(_allEvents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    return events.isEmpty
        ? Center(
            child: Text(
              'Etkinlik bulunmamaktadır',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return EventCard(event: events[index]);
            },
          );
  }
}
