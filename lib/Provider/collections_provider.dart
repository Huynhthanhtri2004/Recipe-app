import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CollectionsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> get collections => _collections;

  CollectionsProvider() {
    // Chỉ load collections khi user đã đăng nhập
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadCollections();
      } else {
        _collections = [];
        notifyListeners();
      }
    });
  }

  Future<void> _loadCollections() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('collections')
          .get();
      
      _collections = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading collections: $e');
      }
    }
  }

  Future<void> createCollection(String name, String description) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('collections')
          .add({
        'name': name,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'recipeIds': <String>[],
      });
      await _loadCollections();
    } catch (e) {
      if (kDebugMode) {
        print('Error creating collection: $e');
      }
    }
  }

  Future<void> addRecipeToCollection(String collectionId, String recipeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('collections')
          .doc(collectionId)
          .update({
        'recipeIds': FieldValue.arrayUnion([recipeId]),
      });
      await _loadCollections();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding recipe to collection: $e');
      }
    }
  }

  Future<void> removeRecipeFromCollection(String collectionId, String recipeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('collections')
          .doc(collectionId)
          .update({
        'recipeIds': FieldValue.arrayRemove([recipeId]),
      });
      await _loadCollections();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing recipe from collection: $e');
      }
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('collections')
          .doc(collectionId)
          .delete();
      await _loadCollections();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting collection: $e');
      }
    }
  }

  bool isRecipeInCollection(String collectionId, String recipeId) {
    final collection = _collections.firstWhere(
      (c) => c['id'] == collectionId,
      orElse: () => {'recipeIds': <String>[]},
    );
    return (collection['recipeIds'] as List<dynamic>).contains(recipeId);
  }
}
