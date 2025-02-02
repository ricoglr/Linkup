class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final String imageUrl;
  final String organizerId;
  final List<String> participants;
  final DateTime createdAt;
  final String contactPhone;
  final String organizationInfo;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    required this.imageUrl,
    required this.organizerId,
    this.participants = const [],
    required this.createdAt,
    required this.contactPhone,
    required this.organizationInfo,
  });

  // Katılımcı sayısını döndüren bir yöntem
  int get participantCount => participants.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'category': category,
      'imageUrl': imageUrl,
      'organizerId': organizerId,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'contactPhone': contactPhone,
      'organizationInfo': organizationInfo,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      time: map['time'],
      location: map['location'],
      category: map['category'],
      imageUrl: map['imageUrl'],
      organizerId: map['organizerId'],
      participants: List<String>.from(map['participants']),
      createdAt: DateTime.parse(map['createdAt']),
      contactPhone: map['contactPhone'],
      organizationInfo: map['organizationInfo'],
    );
  }
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int requiredEvents;
  final String category;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredEvents,
    required this.category,
  });
}