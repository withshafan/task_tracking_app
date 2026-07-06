import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  // Save user data
  Future<void> saveUser(AppUser user) async {
    await _usersCollection.doc(user.id).set(user.toMap());
  }

  // Get a single user by ID
  Future<AppUser?> getUser(String userId) async {
    DocumentSnapshot doc = await _usersCollection.doc(userId).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Get all users (for admin to assign tasks)
  Stream<List<AppUser>> getAllUsers() {
    return _usersCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }
}
