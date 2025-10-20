import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/Provider/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    // Mark all as read
                    for (final notification in provider.notifications) {
                      if (!(notification['isRead'] ?? false)) {
                        provider.markAsRead(notification['id']);
                      }
                    }
                  },
                  child: const Text('Đánh dấu tất cả đã đọc'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.notification, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có thông báo nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              final isRead = notification['isRead'] ?? false;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: isRead ? null : Colors.blue.withOpacity(0.1),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey : Colors.blue,
                    child: Icon(
                      _getNotificationIcon(notification['type']),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    notification['title'] ?? 'Thông báo',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification['body'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification['timestamp']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      provider.markAsRead(notification['id']);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'announcement':
        return Iconsax.notification_bing;
      case 'recipe_approved':
        return Iconsax.tick_circle;
      case 'recipe_rejected':
        return Iconsax.close_circle;
      default:
        return Iconsax.notification;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Vừa xong';
    
    try {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${difference.inDays} ngày trước';
      }
    } catch (e) {
      return 'Không xác định';
    }
  }
}
