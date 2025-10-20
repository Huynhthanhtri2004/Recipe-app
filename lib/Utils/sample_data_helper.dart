import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SampleDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo dữ liệu mẫu cho danh mục
  static Future<void> createSampleCategories() async {
    try {
      final categories = [
        'Món chính',
        'Món khai vị',
        'Món tráng miệng',
        'Món chay',
        'Món nhanh',
        'Món truyền thống',
        'Món quốc tế',
        'Món nướng',
        'Món hấp',
        'Món chiên',
      ];

      final batch = _firestore.batch();
      
      for (final category in categories) {
        final docRef = _firestore.collection('App-Category').doc();
        batch.set(docRef, {
          'name': category,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ Sample categories created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating sample categories: $e');
      }
    }
  }

  /// Tạo dữ liệu mẫu cho công thức
  static Future<void> createSampleRecipes() async {
    try {
      final recipes = [
        {
          'name': 'Cơm chiên dương châu',
          'image': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=500',
          'cuisine': 'Trung Quốc',
          'difficulty': 'Dễ',
          'time': 30,
          'calories': 450,
          'mealType': 'Món chính',
          'ingredients': ['Cơm nguội', 'Trứng', 'Tôm', 'Thịt bò', 'Hành tây', 'Cà rốt'],
          'ingredientsAmount': ['2 bát', '2 quả', '100g', '100g', '1 củ', '1 củ'],
          'instructions': [
            'Chuẩn bị nguyên liệu',
            'Xào trứng trước',
            'Xào thịt và tôm',
            'Thêm cơm và rau củ',
            'Nêm gia vị và hoàn thành'
          ],
          'status': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Phở bò',
          'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
          'cuisine': 'Việt Nam',
          'difficulty': 'Trung bình',
          'time': 120,
          'calories': 350,
          'mealType': 'Món chính',
          'ingredients': ['Bánh phở', 'Thịt bò', 'Hành tây', 'Gừng', 'Quế', 'Hoa hồi'],
          'ingredientsAmount': ['500g', '300g', '2 củ', '1 củ', '2 thanh', '3 hoa'],
          'instructions': [
            'Nấu nước dùng từ xương bò',
            'Thêm gia vị và thảo mộc',
            'Thái thịt bò mỏng',
            'Chần bánh phở',
            'Trang trí và thưởng thức'
          ],
          'status': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Bánh mì kẹp thịt',
          'image': 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=500',
          'cuisine': 'Quốc tế',
          'difficulty': 'Dễ',
          'time': 20,
          'calories': 600,
          'mealType': 'Món nhanh',
          'ingredients': ['Bánh mì', 'Thịt bò xay', 'Phô mai', 'Rau xà lách', 'Cà chua', 'Sốt'],
          'ingredientsAmount': ['2 ổ', '200g', '2 lát', '4 lá', '2 quả', '2 thìa'],
          'instructions': [
            'Nướng bánh mì',
            'Chiên thịt bò',
            'Thêm phô mai',
            'Trang trí rau',
            'Hoàn thành'
          ],
          'status': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      
      for (final recipe in recipes) {
        final docRef = _firestore.collection('RecipeApp').doc();
        batch.set(docRef, recipe);
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ Sample recipes created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating sample recipes: $e');
      }
    }
  }

  /// Tạo dữ liệu mẫu cho công thức chờ duyệt
  static Future<void> createSamplePendingRecipes() async {
    try {
      final pendingRecipes = [
        {
          'name': 'Mì tôm trứng',
          'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
          'cuisine': 'Việt Nam',
          'difficulty': 'Dễ',
          'time': 10,
          'calories': 300,
          'mealType': 'Món nhanh',
          'ingredients': ['Mì tôm', 'Trứng', 'Hành lá'],
          'ingredientsAmount': ['1 gói', '1 quả', '1 nhánh'],
          'instructions': [
            'Đun sôi nước',
            'Thả mì vào',
            'Thêm trứng',
            'Trang trí hành lá'
          ],
          'status': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      
      for (final recipe in pendingRecipes) {
        final docRef = _firestore.collection('recipes_pending').doc();
        batch.set(docRef, recipe);
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('✅ Sample pending recipes created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating sample pending recipes: $e');
      }
    }
  }

  /// Tạo tất cả dữ liệu mẫu
  static Future<void> createAllSampleData() async {
    try {
      await createSampleCategories();
      await createSampleRecipes();
      await createSamplePendingRecipes();
      
      if (kDebugMode) {
        print('✅ All sample data created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating sample data: $e');
      }
    }
  }
}
