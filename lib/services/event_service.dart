import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constant/entities.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Etkinlik oluşturma
  Future<void> createEvent(Event event) async {
    try {
      await _firestore.collection('events').add({
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'date': event.date,
        'time': event.time,
        'location': event.location,
        'category': event.category,
        'imageUrl': event.imageUrl,
        'organizerId': _auth.currentUser?.uid,
        'participants': event.participants,
        'createdAt': FieldValue.serverTimestamp(),
        'contactPhone': event.contactPhone,
        'organizationInfo': event.organizationInfo,
      });
    } catch (e) {
      throw Exception('Etkinlik oluşturulurken hata: $e');
    }
  }

  // Tüm etkinlikleri getirme
  Stream<List<Event>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          date: (data['date'] as Timestamp).toDate(),
          time: data['time'],
          location: data['location'],
          category: data['category'],
          imageUrl: data['imageUrl'],
          organizerId: data['organizerId'],
          participants: List<String>.from(data['participants'] ?? []),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          contactPhone: data['contactPhone'],
          organizationInfo: data['organizationInfo'],
        );
      }).toList();
    });
  }

  // Kullanıcının kendi etkinliklerini getirme
  Stream<List<Event>> getUserEvents() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          date: (data['date'] as Timestamp).toDate(),
          time: data['time'],
          location: data['location'],
          category: data['category'],
          imageUrl: data['imageUrl'],
          organizerId: data['organizerId'],
          participants: List<String>.from(data['participants'] ?? []),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          contactPhone: data['contactPhone'],
          organizationInfo: data['organizationInfo'],
        );
      }).toList();
    });
  }

  // Etkinliğe katılma
  Future<void> joinEvent(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    await _firestore.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayUnion([userId])
    });
  }

  // Etkinlikten ayrılma
  Future<void> leaveEvent(String eventId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    await _firestore.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayRemove([userId])
    });
  }

  // Kullanıcının etkinlik sayısını getirme
  Future<int> getUserEventCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final snapshot = await _firestore
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Etkinlik silinirken hata: $e');
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _firestore.collection('events').doc(event.id).update({
        'title': event.title,
        'description': event.description,
        'date': event.date,
        'time': event.time,
        'location': event.location,
        'category': event.category,
        'imageUrl': event.imageUrl,
        'contactPhone': event.contactPhone,
        'organizationInfo': event.organizationInfo,
      });
    } catch (e) {
      throw Exception('Etkinlik güncellenirken hata: $e');
    }
  }
}
