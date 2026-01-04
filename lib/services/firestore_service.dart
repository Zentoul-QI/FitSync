import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> saveWorkout(String uid, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .add(data);
  }
}
