import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  NotificationProvider() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      _notifications = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      // Update local state
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> sendNotificationToUser(String userId, String title, String body, {String? type, String? data}) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type ?? 'general',
        'data': data,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  Future<void> sendAnnouncementToAllUsers(String title, String body) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Send notification to each user
      final batch = _firestore.batch();
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = userDoc.reference
            .collection('notifications')
            .doc();
        
        batch.set(notificationRef, {
          'title': title,
          'body': body,
          'type': 'announcement',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error sending announcement: $e');
      }
    }
  }

  int get unreadCount => _notifications.where((n) => !(n['isRead'] ?? false)).length;
}
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';

// class NotificationProvider extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
  
//   List<Map<String, dynamic>> _notifications = [];
//   List<Map<String, dynamic>> get notifications => _notifications;

//   NotificationProvider() {
//     _loadNotifications();
//   }

//   Future<void> _loadNotifications() async {
//     final uid = _auth.currentUser?.uid;
//     if (uid == null) return;

//     try {
//       final snapshot = await _firestore
//           .collection('users')
//           .doc(uid)
//           .collection('notifications')
//           .orderBy('timestamp', descending: true)
//           .limit(50)
//           .get();
      
//       _notifications = snapshot.docs.map((doc) => {
//         'id': doc.id,
//         ...doc.data(),
//       }).toList();
//       notifyListeners();
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error loading notifications: $e');
//       }
//     }
//   }

//   Future<void> markAsRead(String notificationId) async {
//     final uid = _auth.currentUser?.uid;
//     if (uid == null) return;

//     try {
//       await _firestore
//           .collection('users')
//           .doc(uid)
//           .collection('notifications')
//           .doc(notificationId)
//           .update({'isRead': true});
      
//       // Update local state
//       final index = _notifications.indexWhere((n) => n['id'] == notificationId);
//       if (index != -1) {
//         _notifications[index]['isRead'] = true;
//         notifyListeners();
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error marking notification as read: $e');
//       }
//     }
//   }

//   Future<void> sendNotificationToUser(String userId, String title, String body, {String? type, String? data}) async {
//     try {
//       await _firestore
//           .collection('users')
//           .doc(userId)
//           .collection('notifications')
//           .add({
//         'title': title,
//         'body': body,
//         'type': type ?? 'general',
//         'data': data,
//         'isRead': false,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error sending notification: $e');
//       }
//     }
//   }

//   Future<void> sendAnnouncementToAllUsers(String title, String body) async {
//     try {
//       // Get all users
//       final usersSnapshot = await _firestore.collection('users').get();
      
//       // Send notification to each user
//       final batch = _firestore.batch();
//       for (final userDoc in usersSnapshot.docs) {
//         final notificationRef = userDoc.reference
//             .collection('notifications')
//             .doc();
        
//         batch.set(notificationRef, {
//           'title': title,
//           'body': body,
//           'type': 'announcement',
//           'isRead': false,
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//       }
      
//       await batch.commit();
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error sending announcement: $e');
//       }
//     }
//   }

//   int get unreadCount => _notifications.where((n) => !(n['isRead'] ?? false)).length;
// }
