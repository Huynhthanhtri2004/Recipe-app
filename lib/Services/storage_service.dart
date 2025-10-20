import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<void> _ensureAuthenticated() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        if (kDebugMode) {
          print('🔐 Signed in anonymously for upload');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Auth ensure failed: $e');
      }
    }
  }

  // Upload hình ảnh từ gallery
  static Future<String?> uploadImageFromGallery() async {
    try {
      await _ensureAuthenticated();
      if (kDebugMode) {
        print('📸 Starting image picker from gallery...');
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image == null) {
        if (kDebugMode) {
          print('📸 No image selected');
        }
        return null;
      }
      
      if (kDebugMode) {
        print('📸 Image selected: ${image.path}');
      }
      
      // Kiểm tra kích thước file
      final fileSize = await image.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        if (kDebugMode) {
          print('❌ File too large: ${fileSize / 1024 / 1024}MB');
        }
        throw Exception('File quá lớn. Vui lòng chọn file nhỏ hơn 10MB');
      }
      
      if (kIsWeb) {
        final Uint8List bytes = await image.readAsBytes();
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        return await _uploadBytes(bytes, 'images', fileName, 'image/jpeg');
      }
      return await _uploadFile(File(image.path), 'images');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image from gallery: $e');
      }
      rethrow; // Re-throw để UI có thể xử lý
    }
  }

  // Upload hình ảnh từ camera
  static Future<String?> uploadImageFromCamera() async {
    try {
      await _ensureAuthenticated();
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      
      // Kiểm tra kích thước file
      final fileSize = await image.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        if (kDebugMode) {
          print('❌ File too large: ${fileSize / 1024 / 1024}MB');
        }
        throw Exception('File quá lớn. Vui lòng chọn file nhỏ hơn 10MB');
      }
      
      if (kIsWeb) {
        final Uint8List bytes = await image.readAsBytes();
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        return await _uploadBytes(bytes, 'images', fileName, 'image/jpeg');
      }
      return await _uploadFile(File(image.path), 'images');
    } catch (e) {
      if (kDebugMode) {
        print('Error taking photo: $e');
      }
      rethrow; // Re-throw để UI có thể xử lý
    }
  }

  // Upload video từ gallery
  static Future<String?> uploadVideoFromGallery() async {
    try {
      await _ensureAuthenticated();
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 30), // Giới hạn 30 phút
      );
      
      if (video == null) return null;
      if (kIsWeb) {
        final Uint8List bytes = await video.readAsBytes();
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${video.name}';
        // contentType có thể là video/mp4; với web khó xác định exact, mặc định mp4
        return await _uploadBytes(bytes, 'videos', fileName, 'video/mp4');
      }
      return await _uploadFile(File(video.path), 'videos');
    } catch (e) {
      if (kDebugMode) {
        print('Error picking video: $e');
      }
      return null;
    }
  }

  // Upload video từ camera
  static Future<String?> uploadVideoFromCamera() async {
    try {
      await _ensureAuthenticated();
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 30), // Giới hạn 30 phút
      );
      
      if (video == null) return null;
      if (kIsWeb) {
        final Uint8List bytes = await video.readAsBytes();
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${video.name}';
        return await _uploadBytes(bytes, 'videos', fileName, 'video/mp4');
      }
      return await _uploadFile(File(video.path), 'videos');
    } catch (e) {
      if (kDebugMode) {
        print('Error recording video: $e');
      }
      return null;
    }
  }

  // Upload file bất kỳ
  static Future<String?> uploadFile() async {
    try {
      await _ensureAuthenticated();
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
        allowMultiple: false,
      );

      if (result != null) {
        final platformFile = result.files.single;
        final String extension = (platformFile.extension ?? '').toLowerCase();
        final String folder = (extension == 'mp4' || extension == 'mov' || extension == 'avi') ? 'videos' : 'images';
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}';

        if (kIsWeb) {
          if (platformFile.bytes == null) return null;
          final Uint8List bytes = platformFile.bytes!;
          final String contentType = folder == 'videos' ? 'video/mp4' : 'image/jpeg';
          return await _uploadBytes(bytes, folder, fileName, contentType);
        }

        if (platformFile.path != null) {
          final File file = File(platformFile.path!);
          return await _uploadFile(file, folder);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking file: $e');
      }
      return null;
    }
  }

  // Upload file lên Firebase Storage
  static Future<String> _uploadFile(File file, String folder) async {
    try {
      if (kDebugMode) {
        print('📤 Starting file upload...');
        print('📤 File path: ${file.path}');
        print('📤 File exists: ${await file.exists()}');
        print('📤 File size: ${await file.length()} bytes');
      }
      
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      String path = '$folder/$fileName';
      
      if (kDebugMode) {
        print('📤 Upload path: $path');
      }
      
      Reference ref = _storage.ref().child(path);
      
      SettableMetadata metadata = SettableMetadata(
        cacheControl: 'public, max-age=604800',
        contentType: folder == 'videos' ? 'video/mp4' : 'image/jpeg',
      );
      UploadTask uploadTask = ref.putFile(file, metadata);
      
      if (kDebugMode) {
        print('📤 Upload task started...');
      }
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('✅ File uploaded successfully: $downloadUrl');
      }
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading file: $e');
        print('❌ Error type: ${e.runtimeType}');
      }
      rethrow;
    }
  }

  // Upload bytes (dành cho web)
  static Future<String> _uploadBytes(Uint8List data, String folder, String fileName, String contentType) async {
    try {
      if (kDebugMode) {
        print('📤 Starting bytes upload...');
        print('📤 Bytes length: ${data.length}');
      }

      final String path = '$folder/$fileName';
      final Reference ref = _storage.ref().child(path);
      final SettableMetadata metadata = SettableMetadata(
        cacheControl: 'public, max-age=604800',
        contentType: contentType,
      );
      final UploadTask uploadTask = ref.putData(data, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      if (kIsWeb && kDebugMode) {
        print('✅ Bytes uploaded successfully: $downloadUrl');
      }
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading bytes: $e');
      }
      rethrow;
    }
  }

  // Xóa file từ Storage
  static Future<bool> deleteFile(String url) async {
    try {
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
      if (kDebugMode) {
        print('File deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
      return false;
    }
  }

  // Lấy danh sách file trong folder
  static Future<List<Reference>> listFiles(String folder) async {
    try {
      ListResult result = await _storage.ref().child(folder).listAll();
      return result.items;
    } catch (e) {
      if (kDebugMode) {
        print('Error listing files: $e');
      }
      return [];
    }
  }

  // Upload multiple images
  static Future<List<String>> uploadMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      List<String> urls = [];
      for (XFile image in images) {
        String? url;
        if (kIsWeb) {
          final Uint8List bytes = await image.readAsBytes();
          final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
          url = await _uploadBytes(bytes, 'images', fileName, 'image/jpeg');
        } else {
          url = await _uploadFile(File(image.path), 'images');
        }
        if (url != null) urls.add(url);
      }
      
      return urls;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking multiple images: $e');
      }
      return [];
    }
  }

  // Resolve Firebase Storage gs:// URL to https download URL
  static Future<String> resolveDownloadUrl(String url) async {
    try {
      if (url.startsWith('gs://')) {
        final Reference ref = _storage.refFromURL(url);
        final String downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      }
      
      // Nếu URL đã là https nhưng có vấn đề encoding, thử decode lại
      if (url.startsWith('https://firebasestorage.googleapis.com') || 
          url.startsWith('https://firebasestorage.app')) {
        try {
          // Thử parse URL để kiểm tra tính hợp lệ
          final uri = Uri.parse(url);
          if (uri.isAbsolute) {
            // Thêm cache busting parameter để tránh CORS cache
            final separator = url.contains('?') ? '&' : '?';
            return '$url${separator}_t=${DateTime.now().millisecondsSinceEpoch}';
          }
        } catch (e) {
          if (kDebugMode) {
            print('URL parsing error: $e');
          }
        }
      }
      
      return url;
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving download URL: $e');
        print('Original URL: $url');
      }
      return url;
    }
  }
}
