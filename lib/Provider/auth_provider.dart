import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentSnapshot<Map<String, dynamic>>? _userDoc;
  String _role = 'user'; // default role
  bool _isLocked = false;

  DocumentSnapshot<Map<String, dynamic>>? get userDoc => _userDoc;
  String get role => _role;
  bool get isLocked => _isLocked;

  AuthProvider() {
    _auth.userChanges().listen((_) => _loadUserProfile());
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _userDoc = null;
      _role = 'user';
      _isLocked = false;
      notifyListeners();
      return;
    }

    try {
      final docRef = _firestore.collection('users').doc(currentUser.uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        // Seed minimal profile
        final data = {
          'uid': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'avatarUrl': currentUser.photoURL,
          'role': 'user',
          'dietaryPreferences': <String>[],
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await docRef.set(data, SetOptions(merge: true));
        _userDoc = await docRef.get();
      } else {
        _userDoc = snapshot;
      }

      _role = _userDoc?.data()?['role']?.toString().toLowerCase().trim() ?? 'user';
      _isLocked = (_userDoc?.data()?['status']?.toString() ?? 'active') != 'active';
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('AuthProvider load profile error: $e');
      }
    }
  }

  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return (doc.data()?['role']?.toString() ?? 'user').toLowerCase().trim();
      }
      return 'user';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user role: $e');
      }
      return 'user';
    }
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl, List<String>? dietaryPreferences}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final docRef = _firestore.collection('users').doc(currentUser.uid);
    final update = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (dietaryPreferences != null) 'dietaryPreferences': dietaryPreferences,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(update, SetOptions(merge: true));
    await _loadUserProfile();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userDoc = null;
    _role = 'user';
    _isLocked = false;
    notifyListeners();
  }
}


