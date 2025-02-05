import 'dart:io';
import 'package:flutter/material.dart';
import '../constant/entities.dart';
import 'event_detail_screen.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import '../screens/add_event_screen.dart';

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
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  void _showBottomSheetMenu(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;
    final isOwner = widget.event.organizerId == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Düzenle'),
                  onTap: () {
                    Navigator.pop(context);
                    _editEvent();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete,
                      color: Theme.of(context).colorScheme.error),
                  title: Text(
                    'Sil',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Paylaş'),
                onTap: () {
                  Navigator.pop(context);
                  _shareEvent();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: const Text('Bu etkinliği silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await _eventService.deleteEvent(widget.event.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Etkinlik silindi')),
                );
              }
            },
            child: Text(
              'Sil',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _editEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(event: widget.event),
      ),
    );
  }

  void _shareEvent() {
    print('Etkinlik paylaşıldı...');
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;
    final isParticipating = widget.event.participants.contains(currentUserId);
    final participantCount = widget.event.participants.length;

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
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showBottomSheetMenu(context),
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
                  'Katılımcı Sayısı: $participantCount',
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
                  onPressed: () async {
                    if (isParticipating) {
                      await _eventService.leaveEvent(widget.event.id);
                    } else {
                      await _eventService.joinEvent(widget.event.id);
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    isParticipating ? Icons.check : Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    isParticipating ? 'Katıldım' : 'Katıl',
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
                        ),
                      ),
                    ).then((result) {
                      if (result != null && mounted) {
                        setState(() {
                          // _hasJoined = result['hasJoined'] ?? _hasJoined;
                          // _participantCount =
                          //     result['participantCount'] ?? _participantCount;
                        });
                      } else {
                        // _loadParticipationStatus();
                      }
                    });
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
