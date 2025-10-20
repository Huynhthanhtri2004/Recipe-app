import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Services/storage_service.dart';
import 'package:recipe_app/Widget/video_player_widget.dart';

class ImprovedSubmitRecipeScreen extends StatefulWidget {
  const ImprovedSubmitRecipeScreen({super.key});

  @override
  State<ImprovedSubmitRecipeScreen> createState() => _ImprovedSubmitRecipeScreenState();
}

class _ImprovedSubmitRecipeScreenState extends State<ImprovedSubmitRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _image = TextEditingController();
  final TextEditingController _videoUrl = TextEditingController();
  final TextEditingController _time = TextEditingController();
  final TextEditingController _cal = TextEditingController();
  final TextEditingController _cuisine = TextEditingController();
  final TextEditingController _difficulty = TextEditingController();
  final TextEditingController _mealType = TextEditingController();
  final TextEditingController _instructions = TextEditingController();

  bool _submitting = false;
  String? _selectedImageUrl;
  String? _selectedVideoUrl;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;
  
  // Danh sách nguyên liệu với số lượng, đơn vị và hình ảnh
  List<IngredientItem> _ingredients = [];

  @override
  void initState() {
    super.initState();
    // Thêm một nguyên liệu mặc định
    _ingredients.add(IngredientItem());
  }

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
    _instructions.dispose();
    for (var ingredient in _ingredients) {
      ingredient.nameController.dispose();
      ingredient.amountController.dispose();
      ingredient.unitController.dispose();
    }
    super.dispose();
  }

  // Thêm nguyên liệu mới
  void _addIngredient() {
    setState(() {
      _ingredients.add(IngredientItem());
    });
  }

  // Xóa nguyên liệu
  void _removeIngredient(int index) {
    if (_ingredients.length > 1) {
      setState(() {
        _ingredients[index].nameController.dispose();
        _ingredients[index].amountController.dispose();
        _ingredients[index].unitController.dispose();
        _ingredients.removeAt(index);
      });
    }
  }

  Future<void> _uploadImage() async {
    setState(() => _isUploadingImage = true);

    try {
      final source = await _showImageSourceDialog();
      if (source == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      String? imageUrl;
      if (source == 'camera') {
        imageUrl = await StorageService.uploadImageFromCamera();
      } else if (source == 'gallery') {
        imageUrl = await StorageService.uploadImageFromGallery();
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _selectedImageUrl = imageUrl;
          _image.text = imageUrl!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải ảnh. Vui lòng thử lại.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _uploadVideo() async {
    setState(() => _isUploadingVideo = true);

    try {
      final source = await _showVideoSourceDialog();
      if (source == null) {
        setState(() => _isUploadingVideo = false);
        return;
      }

      String? videoUrl;
      if (source == 'camera') {
        videoUrl = await StorageService.uploadVideoFromCamera();
      } else if (source == 'gallery') {
        videoUrl = await StorageService.uploadVideoFromGallery();
      }

      if (videoUrl != null && videoUrl.isNotEmpty) {
        setState(() {
          _selectedVideoUrl = videoUrl;
          _videoUrl.text = videoUrl!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải video thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải video. Vui lòng thử lại.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải video: $e'),
          backgroundColor: Colors.red,
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

  Future<void> _uploadIngredientImage(int index) async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      String? imageUrl;
      if (source == 'camera') {
        imageUrl = await StorageService.uploadImageFromCamera();
      } else if (source == 'gallery') {
        imageUrl = await StorageService.uploadImageFromGallery();
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _ingredients[index].imageUrl = imageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh nguyên liệu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh nguyên liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra nguyên liệu
    bool hasValidIngredients = false;
    for (var ingredient in _ingredients) {
      if (ingredient.nameController.text.trim().isNotEmpty) {
        hasValidIngredients = true;
        break;
      }
    }

    if (!hasValidIngredients) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập ít nhất một nguyên liệu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      // Chuẩn bị dữ liệu nguyên liệu
      final List<Map<String, dynamic>> ingredients = _ingredients
          .where((ingredient) => ingredient.nameController.text.trim().isNotEmpty)
          .map((ingredient) => {
                'name': ingredient.nameController.text.trim(),
                'amount': double.tryParse(ingredient.amountController.text.trim()) ?? 0.0,
                'unit': ingredient.unitController.text.trim().isEmpty ? 'g' : ingredient.unitController.text.trim(),
                'imageUrl': ingredient.imageUrl ?? '',
              })
          .toList();

      final List<String> ingredientsName = ingredients.map((e) => e['name'] as String).toList();
      final List<double> ingredientsAmount = ingredients.map((e) => e['amount'] as double).toList();
      final List<String> ingredientsImage = ingredients.map((e) => e['imageUrl'] as String).toList();

      final data = {
        'name': _name.text.trim(),
        'image': _image.text.trim(),
        'videoUrl': _videoUrl.text.trim().isEmpty ? null : _videoUrl.text.trim(),
        'time': int.tryParse(_time.text.trim()) ?? 0,
        'cal': int.tryParse(_cal.text.trim()) ?? 0,
        'cuisine': _cuisine.text.trim(),
        'difficulty': _difficulty.text.trim(),
        'mealType': _mealType.text.trim(),
        'ingredients': ingredients,
        'ingredientsName': ingredientsName,
        'ingredientsAmount': ingredientsAmount,
        'ingredientsImage': ingredientsImage,
        'instructions': _instructions.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'submittedBy': user.uid,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'rating': '0.0',
        'reviews': 0,
      };

      await FirebaseFirestore.instance.collection('recipes_pending').add(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi công thức. Chờ admin duyệt.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi công thức: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi công thức'),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên món ăn
              _buildTextField(
                controller: _name,
                label: 'Tên món ăn *',
                icon: Iconsax.text,
                validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập tên món ăn' : null,
              ),
              const SizedBox(height: 16),

              // Hình ảnh
              _buildImageSection(),
              const SizedBox(height: 16),

              // Video
              _buildVideoSection(),
              const SizedBox(height: 16),

              // Thông tin cơ bản
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _time,
                      label: 'Thời gian (phút)',
                      icon: Iconsax.clock,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _cal,
                      label: 'Calories',
                      icon: Iconsax.flash_1,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cuisine,
                      label: 'Quốc gia',
                      icon: Iconsax.flag,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _difficulty,
                      label: 'Độ khó',
                      icon: Iconsax.star,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _mealType,
                label: 'Loại món',
                icon: Iconsax.category,
              ),
              const SizedBox(height: 24),

              // Nguyên liệu
              _buildIngredientsSection(),
              const SizedBox(height: 24),

              // Hướng dẫn
              _buildTextField(
                controller: _instructions,
                label: 'Hướng dẫn nấu ăn *',
                icon: Iconsax.document_text,
                maxLines: 5,
                validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập hướng dẫn' : null,
              ),
              const SizedBox(height: 32),

              // Nút gửi
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Gửi công thức', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hình ảnh món ăn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _selectedImageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.error, size: 50),
                    ),
                  ),
                )
              : InkWell(
                  onTap: _uploadImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: _isUploadingImage
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.camera, size: 50, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('Chọn hình ảnh'),
                              const Text('(Tùy chọn)', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Video hướng dẫn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedVideoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: VideoPlayerWidget(
                    videoUrl: _selectedVideoUrl!,
                    autoPlay: false,
                    showControls: true,
                    aspectRatio: 16 / 9,
                  ),
                )
              : InkWell(
                  onTap: _uploadVideo,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: _isUploadingVideo
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.video, size: 50, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('Chọn video'),
                              const Text('(Tùy chọn)', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Nguyên liệu *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              onPressed: _addIngredient,
              icon: const Icon(Iconsax.add_circle, color: kprimaryColor),
              tooltip: 'Thêm nguyên liệu',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_ingredients.length, (index) {
          final ingredient = _ingredients[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: ingredient.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên nguyên liệu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: ingredient.amountController,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: ingredient.unitController,
                        decoration: const InputDecoration(
                          labelText: 'Đơn vị',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _uploadIngredientImage(index),
                      icon: Icon(
                        ingredient.imageUrl != null ? Iconsax.image : Iconsax.camera,
                        color: ingredient.imageUrl != null ? Colors.green : Colors.grey,
                      ),
                      tooltip: 'Thêm ảnh nguyên liệu',
                    ),
                    if (_ingredients.length > 1)
                      IconButton(
                        onPressed: () => _removeIngredient(index),
                        icon: const Icon(Iconsax.trash, color: Colors.red),
                        tooltip: 'Xóa nguyên liệu',
                      ),
                  ],
                ),
                if (ingredient.imageUrl != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ingredient.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class IngredientItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  String? imageUrl;

  IngredientItem();
}
