import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Services/storage_service.dart';
import 'package:recipe_app/Widget/video_player_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';


class SubmitRecipeScreen extends StatefulWidget {
  const SubmitRecipeScreen({super.key});

  @override
  State<SubmitRecipeScreen> createState() => _SubmitRecipeScreenState();
}

class _SubmitRecipeScreenState extends State<SubmitRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _image = TextEditingController();
  final TextEditingController _videoUrl = TextEditingController();
  final TextEditingController _time = TextEd
  final TextEditingController _ingredientsAmount = TextEditingController();
  final TextEditingController _instructions = TextEditingController();

  bool _submitting = false;
  String? _selectedImageUrl;
  String? _selectedVideoUrl;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;

  @override
  void dispose() {
    _name.dispose();
    _image.dispose();
    _videoUrl.dispose();
    _time.dispose();
    _cal.dispose();
    _cuisine.dispose();
    _difficulty.dispose();
    _mealType.dispose();
    _ingredients.dispose();
    _ingredientsAmount.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    setState(() => _isUploadingImage = true);

    try {
      // Hiển thị dialog chọn nguồn ảnh
      final source = await _showImageSourceDialog();
      if (source == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      print('📸 Selected image source: $source');

      String? imageUrl;
      if (source == 'camera') {
        print('📸 Uploading from camera...');
        imageUrl = await StorageService.uploadImageFromCamera();
      } else if (source == 'gallery') {
        print('📸 Uploading from gallery...');
        imageUrl = await StorageService.uploadImageFromGallery();
      }

      print('📸 Upload result: $imageUrl');

      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _selectedImageUrl = imageUrl;
          _image.text = imageUrl ?? '';
        });
        print('✅ Image uploaded successfully: $imageUrl');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ Image upload failed: URL is null or empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải ảnh. Vui lòng thử lại.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _uploadVideo() async {
    setState(() => _isUploadingVideo = true);

    try {
      // Hiển thị dialog chọn nguồn video
      final source = await _showVideoSourceDialog();
      if (source == null) {
        setState(() => _isUploadingVideo = false);
        return;
      }

      print('🎥 Selected video source: $source');

      String? videoUrl;
      if (source == 'camera') {
        print('🎥 Uploading from camera...');
        videoUrl = await StorageService.uploadVideoFromCamera();
      } else if (source == 'gallery') {
        print('🎥 Uploading from gallery...');
        videoUrl = await StorageService.uploadVideoFromGallery();
      }

      print('🎥 Upload result: $videoUrl');

      if (videoUrl != null && videoUrl.isNotEmpty) {
        setState(() {
          _selectedVideoUrl = videoUrl;
          _videoUrl.text = videoUrl ?? '';
        });
        print('✅ Video uploaded successfully: $videoUrl');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải video thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ Video upload failed: URL is null or empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải video. Vui lòng thử lại.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error uploading video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải video: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isUploadingVideo = false);
    }
  }

  Future<String?> _showImageSourceDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.camera),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Iconsax.gallery),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showVideoSourceDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn nguồn video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.video),
              title: const Text('Quay video'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Iconsax.gallery),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Bắt buộc ảnh phải là URL từ Firebase Storage (ngăn dán link ngoài)
    final imageUrl = _image.text.trim();
    final videoUrl = _videoUrl.text.trim();
    bool isFirebaseUrl(String url) =>
        url.contains('firebasestorage.googleapis.com') || url.contains('firebasestorage.app');

    if (imageUrl.isEmpty || !isFirebaseUrl(imageUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải ảnh lên Firebase bằng nút/ô chọn ảnh')),
      );
      return;
    }

    if (videoUrl.isNotEmpty && !isFirebaseUrl(videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải video lên Firebase bằng nút/ô chọn video')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final data = {
        'name': _name.text.trim(),
        'image': imageUrl,
        'videoUrl': videoUrl.isNotEmpty ? videoUrl : null,
        'time': int.tryParse(_time.text.trim()) ?? 0,
        'cal': int.tryParse(_cal.text.trim()) ?? 0,
        'cuisine': _cuisine.text.trim(),
        'difficulty': _difficulty.text.trim(),
        'mealType': _mealType.text.trim(),
        'ingredientsName': _ingredients.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'ingredientsAmount': _ingredientsAmount.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) => double.tryParse(e) ?? 0.0).toList(),
        'ingredientsImage': [], // Có thể thêm tính năng upload ảnh nguyên liệu sau
        'instructions': _instructions.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'submittedBy': user.uid,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'rating': '0.0',
        'reviews': 0,
      };
      await FirebaseFirestore.instance.collection('recipes_pending').add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi công thức. Chờ admin duyệt.')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi công thức')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Tên món', _name, Iconsax.text),

              // Upload Image Section
              const Text('Hình ảnh món ăn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isUploadingImage ? null : _uploadImage,
                      child: AbsorbPointer(
                        absorbing: true,
                        child: _field('Ảnh (URL)', _image, Iconsax.image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Icon(Iconsax.camera, size: 16),
                    label: Text(_isUploadingImage ? 'Đang tải...' : 'Tải ảnh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kprimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              if (_selectedImageUrl != null) ...[
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _selectedImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Iconsax.image, size: 32, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Upload Video Section
              const Text('Video hướng dẫn (tùy chọn)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isUploadingVideo ? null : _uploadVideo,
                      child: AbsorbPointer(
                        absorbing: true,
                        child: _field('Video (URL)', _videoUrl, Iconsax.video),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingVideo ? null : _uploadVideo,
                    icon: _isUploadingVideo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Icon(Iconsax.video, size: 16),
                    label: Text(_isUploadingVideo ? 'Đang tải...' : 'Tải video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              if (_selectedVideoUrl != null) ...[
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: VideoPlayerWidget(
                      videoUrl: _selectedVideoUrl!,
                      autoPlay: false,
                      showControls: true,
                      aspectRatio: 16 / 9,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _field('Thời gian (phút)', _time, Iconsax.clock, number: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Calo', _cal, Iconsax.flash_1, number: true)),
              ]),
              _field('Quốc gia/Ẩm thực', _cuisine, Iconsax.global),
              _field('Độ khó (easy/medium/hard)', _difficulty, Iconsax.activity),
              _field('Bữa ăn (sáng/trưa/tối)', _mealType, Iconsax.menu_board),
              _multiline('Nguyên liệu (mỗi dòng 1 nguyên liệu)', _ingredients),
              _multiline('Số lượng nguyên liệu (mỗi dòng 1 số lượng, theo thứ tự nguyên liệu trên)', _ingredientsAmount),
              _multiline('Hướng dẫn (mỗi dòng 1 bước)', _instructions),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
                child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Gửi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: (v) {
          // Cho phép trường video rỗng
          if (label.contains('Video') && (v == null || v.trim().isEmpty)) {
            return null;
          }
          return (v == null || v.trim().isEmpty) ? 'Không được để trống' : null;
        },
      ),
    );
  }

  Widget _multiline(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true, prefixIcon: const Icon(Iconsax.edit), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
      ),
    );
  }
}


