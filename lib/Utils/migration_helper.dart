import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cập nhật các công thức hiện có để thêm các trường còn thiếu
  static Future<void> migrateExistingRecipes() async {
    try {
      if (kDebugMode) {
        print('🔄 Bắt đầu migration các công thức hiện có...');
      }

      final recipesSnapshot = await _firestore.collection('RecipeApp').get();
      int updatedCount = 0;

      for (final doc in recipesSnapshot.docs) {
        final data = doc.data();
        bool needsUpdate = false;
        final updateData = <String, dynamic>{};

        // Chuẩn hóa nguyên liệu sang danh sách object: {name, amount, unit, imageUrl}
        if (!data.containsKey('ingredients') || data['ingredients'] == null) {
          final List<dynamic> names = (data['ingredientsName'] as List<dynamic>?) ?? [];
          final List<dynamic> amountsRaw = (data['ingredientsAmount'] as List<dynamic>?) ?? [];
          final List<dynamic> images = (data['ingredientsImage'] as List<dynamic>?) ?? [];

          final List<Map<String, dynamic>> normalized = [];
          for (int i = 0; i < names.length; i++) {
            final String name = names[i]?.toString() ?? '';
            final dynamic amountItem = i < amountsRaw.length ? amountsRaw[i] : null;
            double amount = 0.0;
            String unit = 'g';
            if (amountItem != null) {
              final String s = amountItem.toString().trim();
              final RegExp numExp = RegExp(r"[0-9]+(\.[0-9]+)?");
              final Match? m = numExp.firstMatch(s);
              if (m != null) {
                amount = double.tryParse(m.group(0)!) ?? 0.0;
                final String rest = s.replaceFirst(m.group(0)!, '').trim();
                if (rest.isNotEmpty) unit = rest;
              } else if (amountItem is num) {
                amount = (amountItem as num).toDouble();
              }
            }
            final String imageUrl = i < images.length ? (images[i]?.toString() ?? '') : '';
            normalized.add({
              'name': name,
              'amount': amount,
              'unit': unit,
              'imageUrl': imageUrl,
            });
          }
          updateData['ingredients'] = normalized;
          needsUpdate = true;
        }

        // Đảm bảo các mảng cũ tối thiểu tồn tại để tương thích ngược (không bắt buộc)
        if (!data.containsKey('ingredientsAmount') || data['ingredientsAmount'] == null) {
          final ingredientsName = data['ingredientsName'] as List<dynamic>? ?? [];
          updateData['ingredientsAmount'] = List.filled(ingredientsName.length, 100.0);
          needsUpdate = true;
        }
        if (!data.containsKey('ingredientsImage') || data['ingredientsImage'] == null) {
          updateData['ingredientsImage'] = [];
          needsUpdate = true;
        }

        // likeCount mặc định
        if (!data.containsKey('likeCount') || data['likeCount'] == null) {
          updateData['likeCount'] = 0;
          needsUpdate = true;
        }

        // Thêm trường ratingAverage (double) và reviewsCount (int)
        if (!data.containsKey('ratingAverage') || data['ratingAverage'] == null) {
          double avg = 0.0;
          if (data.containsKey('rating') && data['rating'] != null) {
            avg = double.tryParse(data['rating'].toString()) ?? 0.0;
          }
          updateData['ratingAverage'] = avg;
          needsUpdate = true;
        }
        if (!data.containsKey('reviewsCount') || data['reviewsCount'] == null) {
          int count = 0;
          if (data.containsKey('reviews') && data['reviews'] != null) {
            final dynamic r = data['reviews'];
            if (r is num) count = r.toInt();
            else count = int.tryParse(r.toString()) ?? 0;
          }
          updateData['reviewsCount'] = count;
          needsUpdate = true;
        }

        if (needsUpdate) {
          await doc.reference.set(updateData, SetOptions(merge: true));
          updatedCount++;
          if (kDebugMode) {
            print('✅ Đã cập nhật công thức: ${data['name']}');
          }
        }
      }

      if (kDebugMode) {
        print('🎉 Hoàn thành migration! Đã cập nhật $updatedCount công thức.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi trong quá trình migration: $e');
      }
      rethrow;
    }
  }

  /// Kiểm tra xem có cần migration không
  static Future<bool> needsMigration() async {
    try {
      final recipesSnapshot = await _firestore.collection('RecipeApp').limit(1).get();
      
      if (recipesSnapshot.docs.isEmpty) {
        return false;
      }

      final data = recipesSnapshot.docs.first.data();
      return !data.containsKey('ingredients') ||
             !data.containsKey('ratingAverage') ||
             !data.containsKey('reviewsCount');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Lỗi kiểm tra migration: $e');
      }
      return false;
    }
  }
}

