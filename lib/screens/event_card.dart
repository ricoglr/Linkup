import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/entities.dart';
import 'event_detail_screen.dart';

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard({
    super.key,
    required this.event,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  int _participantCount = 0;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _loadParticipationStatus();
  }

  Future<void> _loadParticipationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool joined = prefs.getBool('joined_${widget.event.id}') ?? false;
    int participantCount =
        prefs.getInt('participantCount_${widget.event.id}') ?? 0;

    setState(() {
      _hasJoined = joined;
      _participantCount = participantCount;
    });
  }

  Future<void> _saveParticipationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('joined_${widget.event.id}', _hasJoined);
    await prefs.setInt(
        'participantCount_${widget.event.id}', _participantCount);
  }

  void _joinEvent() {
    setState(() {
      if (_hasJoined) {
        _participantCount -= 1;
        _hasJoined = false;
      } else {
        _participantCount += 1;
        _hasJoined = true;
      }
    });
    _saveParticipationStatus();
  }

  // Yeni seçenekler menüsünü oluştur
  void _showBottomSheetMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Düzenle'),
                onTap: () {
                  _editEvent();
                  Navigator.pop(context); // Menüden çık
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Sil'),
                onTap: () {
                  _deleteEvent();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Paylaş'),
                onTap: () {
                  _shareEvent();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Düzenle butonunun işlevi
  void _editEvent() {
    // Etkinlik düzenleme ekranına yönlendir
    print('Düzenleme ekranına yönlendiriliyor...');
  }

  // Silme butonunun işlevi
  void _deleteEvent() {
    // Etkinliği sil
    print('Etkinlik silindi...');
  }

  // Paylaşma butonunun işlevi
  void _shareEvent() {
    // Etkinliği paylaş
    print('Etkinlik paylaşıldı...');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  image: _buildImageDecoration(),
                ),
                child: widget.event.imageUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.event,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => _showBottomSheetMenu(context), // Menüyi aç
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.category, widget.event.category),
                _buildInfoRow(
                  Icons.calendar_today,
                  '${widget.event.date.day}/${widget.event.date.month}/${widget.event.date.year}',
                ),
                _buildInfoRow(Icons.location_on, widget.event.location),
                _buildInfoRow(Icons.phone, widget.event.contactPhone),
                const SizedBox(height: 8),
                Text(
                  widget.event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Katılımcı Sayısı: $_participantCount',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _joinEvent,
                  icon: Icon(
                    _hasJoined ? Icons.check : Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    _hasJoined ? 'Katıldım' : 'Katıl',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(
                          event: widget.event,
                          hasJoined: _hasJoined,
                          participantCount: _participantCount,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary),
                  child: Text(
                    'Detay',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage? _buildImageDecoration() {
    if (widget.event.imageUrl.isEmpty) return null;

    try {
      return DecorationImage(
        image: FileImage(File(widget.event.imageUrl)),
        fit: BoxFit.cover,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
