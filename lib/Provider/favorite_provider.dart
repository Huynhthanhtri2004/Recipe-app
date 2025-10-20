import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoriteProvider extends ChangeNotifier {
  List<String> _favoriteIds = [];
  List<String> get favorites => _favoriteIds;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FavoriteProvider() {
    // Chỉ load favorites khi user đã đăng nhập
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadFavorites();
      } else {
        _favoriteIds = [];
        notifyListeners();
      }
    });
  }

  void toggleFavorite(DocumentSnapshot product) async {
    final productId = product.id;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      await _removeFavorite(uid, productId);
    } else {
      _favoriteIds.add(productId);
      await _addFavorite(uid, productId);
    }
    if (hasListeners) {
      notifyListeners();
    }
  }

  bool isExist(DocumentSnapshot product) {
    return _favoriteIds.contains(product.id);
  }

  Future<void> _addFavorite(String uid, String productId) async {
    try {
      await _firestore.collection('users').doc(uid).collection("favorites").doc(productId).set({
        'isFavorite': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding favorite: $e');
      }
    }
  }

  Future<void> _removeFavorite(String uid, String productId) async {
    try {
      await _firestore.collection('users').doc(uid).collection("favorites").doc(productId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing favorite: $e');
      }
    }
  }

  Future<void> loadFavorites() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _favoriteIds = [];
        notifyListeners();
        return;
      }
      final snapshot = await _firestore.collection('users').doc(uid).collection("favorites").get();
      _favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading favorites: $e');
      }
      // Đặt về trạng thái mặc định khi có lỗi
      _favoriteIds = [];
      notifyListeners();
    }
  }

  static FavoriteProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<FavoriteProvider>(context, listen: listen);
  }
}