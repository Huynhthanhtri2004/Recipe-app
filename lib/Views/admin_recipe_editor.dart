import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Services/storage_service.dart';
import 'package:recipe_app/Utils/constants.dart';

class AdminRecipeEditor extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? initialData;
  final bool isPending;

  const AdminRecipeEditor({
    super.key, 
    this.documentId, 
    this.initialData,
    this.isPending = false,
  });

  @override
  State<AdminRecipeEditor> createState() => _AdminRecipeEditorState();
}

class _AdminRecipeEditorState extends State<AdminRecipeEditor> {
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

  bool _saving = false;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;
  List<_IngredientInput> _ingredientInputs = <_IngredientInput>[];

  @override
  void initState() {
    super.initState();
    _ingredientInputs = <_IngredientInput>[];
    final d = widget.initialData;
    if (d != null) {
      _name.text = (d['name'] ?? '').toString();
      _image.text = (d['image'] ?? '').toString();
      _videoUrl.text = (d['videoUrl'] ?? '').toString();
      _time.text = (d['time'] ?? '').toString();
      _cal.text = (d['cal'] ?? '').toString();
      _cuisine.text = (d['cuisine'] ?? '').toString();
      _difficulty.text = (d['difficulty'] ?? '').toString();
      _mealType.text = (d['mealType'] ?? '').toString();
      final List<dynamic>? ingr = d['ingredients'] as List<dynamic>?;
      if (ingr != null && ingr.isNotEmpty) {
        for (final it in ingr) {
          final m = Map<String, dynamic>.from(it as Map);
          _ingredientInputs.add(
            _IngredientInput(
              name: TextEditingController(text: (m['name'] ?? '').toString()),
              amount: TextEditingController(text: ((m['amount'] ?? 0).toString())),
              unit: TextEditingController(text: (m['unit'] ?? 'g').toString()),
              imageUrl: TextEditingController(text: (m['imageUrl'] ?? '').toString()),
            ),
          );
        }
      } else {
        final List<dynamic> names = (d['ingredientsName'] as List<dynamic>?) ?? [];
        final List<dynamic> amounts = (d['ingredientsAmount'] as List<dynamic>?) ?? [];
        final List<dynamic> images = (d['ingredientsImage'] as List<dynamic>?) ?? [];
        for (int i = 0; i < names.length; i++) {
          final name = names[i]?.toString() ?? '';
          final amount = i < amounts.length ? amounts[i] : '';
          final imageUrl = i < images.length ? (images[i]?.toString() ?? '') : '';
          _ingredientInputs.add(
            _IngredientInput(
              name: TextEditingController(text: name),
              amount: TextEditingController(text: amount.toString()),
              unit: TextEditingController(text: 'g'),
              imageUrl: TextEditingController(text: imageUrl),
            ),
          );
        }
      }
      _instructions.text = (d['instructions'] as List?)?.join('\n') ?? '';
    }
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
    for (final it in _ingredientInputs) {
      it.name.dispose();
      it.amount.dispose();
      it.unit.dispose();
      it.imageUrl.dispose();
    }
    super.dispose();
  }

  Future<void> _uploadImage() async {
    setState(() => _isUploadingImage = true);
    final url = await StorageService.uploadImageFromGallery();
    if (mounted) {
      setState(() => _isUploadingImage = false);
      if (url != null) _image.text = url;
    }
  }

  Future<void> _uploadVideo() async {
    setState(() => _isUploadingVideo = true);
    final url = await StorageService.uploadVideoFromGallery();
    if (mounted) {
      setState(() => _isUploadingVideo = false);
      if (url != null) _videoUrl.text = url;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final List<Map<String, dynamic>> ingredients = _ingredientInputs.map((r) {
      final parsed = double.tryParse(r.amount.text.trim()) ?? 0.0;
      final unit = r.unit.text.trim().isEmpty ? 'g' : r.unit.text.trim();
      return {
        'name': r.name.text.trim(),
        'amount': parsed,
        'unit': unit,
        'imageUrl': r.imageUrl.text.trim(),
      };
    }).toList();

    final List<String> ingredientsName = ingredients.map((e) => (e['name'] ?? '').toString()).toList();
    final List<double> ingredientsAmount = ingredients.map((e) => (e['amount'] as num).toDouble()).toList();
    final List<String> ingredientsImage = ingredients.map((e) => (e['imageUrl'] ?? '').toString()).toList();

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
      'updatedAt': FieldValue.serverTimestamp(),
      'status': (widget.initialData?['status'] ?? 'approved'),
    };

    try {
      if (widget.documentId == null) {
        // Lấy current user để set ownerId
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('RecipeApp').add({
          ...data,
          'ownerId': user?.uid, // Thêm field ownerId cho admin
          'createdAt': FieldValue.serverTimestamp(),
          'ratingAverage': 0.0,
          'reviewsCount': 0,
          'likeCount': 0,
        });
      } else {
        await FirebaseFirestore.instance.collection('RecipeApp').doc(widget.documentId).set(data, SetOptions(merge: true));
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _approveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text('Bạn có chắc chắn muốn duyệt công thức "${_name.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    
    try {
      final List<Map<String, dynamic>> ingredients = _ingredientInputs.map((r) {
        final parsed = double.tryParse(r.amount.text.trim()) ?? 0.0;
        final unit = r.unit.text.trim().isEmpty ? 'g' : r.unit.text.trim();
        return {
          'name': r.name.text.trim(),
          'amount': parsed,
          'unit': unit,
          'imageUrl': r.imageUrl.text.trim(),
        };
      }).toList();

      final List<String> ingredientsName = ingredients.map((e) => (e['name'] ?? '').toString()).toList();
      final List<double> ingredientsAmount = ingredients.map((e) => (e['amount'] as num).toDouble()).toList();
      final List<String> ingredientsImage = ingredients.map((e) => (e['imageUrl'] ?? '').toString()).toList();

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
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'ownerId': widget.initialData?['submittedBy'],
        'ratingAverage': 0.0,
        'reviewsCount': 0,
        'likeCount': 0,
      };

      // Add to approved recipes
      await FirebaseFirestore.instance.collection('RecipeApp').add(data);
      
      // Remove from pending
      if (widget.documentId != null) {
        await FirebaseFirestore.instance
            .collection('recipes_pending')
            .doc(widget.documentId)
            .delete();
      }

      // Send notification to submitter
      final submitterId = widget.initialData?['submittedBy']?.toString();
      if (submitterId != null && submitterId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(submitterId)
            .collection('notifications')
            .add({
          'title': 'Công thức được duyệt',
          'body': '"${data['name']}" đã được duyệt và xuất bản',
          'type': 'recipe_approved',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Công thức đã được duyệt thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi duyệt công thức: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _rejectRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận từ chối'),
        content: Text('Bạn có chắc chắn muốn từ chối công thức "${_name.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    
    try {
      // Remove from pending
      if (widget.documentId != null) {
        await FirebaseFirestore.instance
            .collection('recipes_pending')
            .doc(widget.documentId)
            .delete();
      }

      // Send notification to submitter
      final submitterId = widget.initialData?['submittedBy']?.toString();
      if (submitterId != null && submitterId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(submitterId)
            .collection('notifications')
            .add({
          'title': 'Công thức bị từ chối',
          'body': '"${_name.text}" đã bị từ chối',
          'type': 'recipe_rejected',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Công thức đã bị từ chối'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi từ chối công thức: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPending 
            ? 'Xem công thức chờ duyệt'
            : (widget.documentId == null ? 'Thêm công thức' : 'Sửa công thức')
        ),
        actions: [
          if (widget.isPending) ...[
            TextButton(
              onPressed: _saving ? null : _approveRecipe,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Duyệt'),
            ),
            TextButton(
              onPressed: _saving ? null : _rejectRecipe,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Từ chối'),
            ),
          ] else
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Tên món', _name, Iconsax.text),

              const SizedBox(height: 8),
              const Text('Hình ảnh món ăn', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: _field('Ảnh (URL)', _image, Iconsax.image)),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadImage,
                    icon: _isUploadingImage ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Iconsax.camera),
                    label: Text(_isUploadingImage ? 'Đang tải...' : 'Tải ảnh'),
                    style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text('Video hướng dẫn (tùy chọn)', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(child: _field('Video (URL)', _videoUrl, Iconsax.video, optional: true)),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isUploadingVideo ? null : _uploadVideo,
                    icon: _isUploadingVideo ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Iconsax.video),
                    label: Text(_isUploadingVideo ? 'Đang tải...' : 'Tải video'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ],
              ),

              Row(children: [
                Expanded(child: _field('Thời gian (phút)', _time, Iconsax.clock, number: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Calo', _cal, Iconsax.flash_1, number: true)),
              ]),
              _field('Quốc gia/Ẩm thực', _cuisine, Iconsax.global),
              _field('Độ khó (easy/medium/hard)', _difficulty, Iconsax.activity),
              _field('Bữa ăn (sáng/trưa/tối)', _mealType, Iconsax.menu_board),
      const SizedBox(height: 12),
      const Text('Nguyên liệu (schema mới)', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ..._ingredientInputs.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _field('Tên', row.name, Iconsax.text)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: _field('Số lượng', row.amount, Iconsax.hashtag, number: true),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: _field('Đơn vị', row.unit, Iconsax.tag),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _field('Ảnh nguyên liệu (URL)', row.imageUrl, Iconsax.image)),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = await StorageService.uploadImageFromGallery();
                      if (url != null) setState(() => row.imageUrl.text = url);
                    },
                    icon: const Icon(Iconsax.camera),
                    label: const Text('Tải ảnh'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _ingredientInputs.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ]),
              ],
            ),
          ),
        );
      }).toList(),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _ingredientInputs.add(_IngredientInput(
                name: TextEditingController(),
                amount: TextEditingController(text: '0'),
                unit: TextEditingController(text: 'g'),
                imageUrl: TextEditingController(),
              ));
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm nguyên liệu'),
        ),
      ),
              _multiline('Hướng dẫn (mỗi dòng 1 bước)', _instructions),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminRecipeEditor()),
          );
        },
        icon: const Icon(Iconsax.add),
        label: const Text('Thêm mới'),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon, {bool number = false, bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: (v) {
          if (optional) return null;
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
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true, prefixIcon: const Icon(Iconsax.edit), border: const OutlineInputBorder()),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
      ),
    );
  }
}

class _IngredientInput {
  final TextEditingController name;
  final TextEditingController amount;
  final TextEditingController unit;
  final TextEditingController imageUrl;

  _IngredientInput({
    required this.name,
    required this.amount,
    required this.unit,
    required this.imageUrl,
  });
}


