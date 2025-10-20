import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Tạo tài khoản admin mới
  static Future<bool> createAdminAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Validate email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        if (kDebugMode) {
          print('❌ Invalid email format: $email');
        }
        return false;
      }
      
      // Validate password length
      if (password.length < 6) {
        if (kDebugMode) {
          print('❌ Password too short');
        }
        return false;
      }
      
      // Tạo user với Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật display name
      await userCredential.user?.updateDisplayName(displayName);

      // Tạo profile admin trong Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'role': 'admin',
        'status': 'active',
        'dietaryPreferences': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Admin account created successfully: $email');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating admin account: $e');
      }
      return false;
    }
  }

  /// Cập nhật role của user thành admin
  static Future<bool> promoteToAdmin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ User promoted to admin: $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error promoting user to admin: $e');
      }
      return false;
    }
  }

  /// Kiểm tra xem user có phải admin không
  static Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final role = doc.data()?['role']?.toString().toLowerCase().trim();
        return role == 'admin';
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking admin status: $e');
      }
      return false;
    }
  }

  /// Lấy danh sách tất cả admin
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting admins: $e');
      }
      return [];
    }
  }

  /// Debug: In ra thông tin user hiện tại
  static Future<void> debugCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ No user logged in');
        }
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (kDebugMode) {
          print('👤 Current User Info:');
          print('  - UID: ${user.uid}');
          print('  - Email: ${user.email}');
          print('  - Display Name: ${user.displayName}');
          print('  - Role: ${data['role']}');
          print('  - Status: ${data['status']}');
          print('  - Created: ${data['createdAt']}');
        }
      } else {
        if (kDebugMode) {
          print('❌ User document not found in Firestore');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error debugging user: $e');
      }
    }
  }
}
