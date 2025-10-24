import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Widget/video_player_widget.dart';
import 'package:recipe_app/Views/admin_recipe_editor.dart';

class PendingRecipesApproval extends StatefulWidget {
  const PendingRecipesApproval({super.key});

  @override
  State<PendingRecipesApproval> createState() => _PendingRecipesApprovalState();
}

class _PendingRecipesApprovalState extends State<PendingRecipesApproval> {
  String _searchQuery = '';
  String _selectedCuisine = 'all';
  String _selectedDifficulty = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(.search_normal),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Iconsax.close_circle),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
              const SizedBox(height: 12),
              // Filter Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCuisine,
                      decoration: const InputDecoration(
                        labelText: 'Ẩm thực',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'Việt Nam', child: Text('Việt Nam')),
                        DropdownMenuItem(value: 'Trung Quốc', child: Text('Trung Quốc')),
                        DropdownMenuItem(value: 'Nhật Bản', child: Text('Nhật Bản')),
                        DropdownMenuItem(value: 'Hàn Quốc', child: Text('Hàn Quốc')),
                        DropdownMenuItem(value: 'Thái Lan', child: Text('Thái Lan')),
                        DropdownMenuItem(value: 'Ý', child: Text('Ý')),
                        DropdownMenuItem(value: 'Pháp', child: Text('Pháp')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCuisine = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Độ khó',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'easy', child: Text('Dễ')),
                        DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                        DropdownMenuItem(value: 'hard', child: Text('Khó')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDifficulty = value!);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Pending Recipes List
        Expanded(
          child: _buildPendingRecipesList(),
        ),
      ],
    );
  }

  Widget _buildPendingRecipesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes_pending')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Không có công thức chờ duyệt',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Các công thức mới sẽ xuất hiện ở đây',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Filter recipes
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          // Search filter
          if (_searchQuery.isNotEmpty) {
            final name = (data['name'] ?? '').toString().toLowerCase();
            if (!name.contains(_searchQuery)) return false;
          }

          // Cuisine filter
          if (_selectedCuisine != 'all') {
            final cuisine = (data['cuisine'] ?? '').toString();
            if (cuisine != _selectedCuisine) return false;
          }

          // Difficulty filter
          if (_selectedDifficulty != 'all') {
            final difficulty = (data['difficulty'] ?? '').toString();
            if (difficulty != _selectedDifficulty) return false;
          }

          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Không tìm thấy công thức phù hợp',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminRecipeEditor(
                        documentId: doc.id,
                        initialData: data,
                        isPending: true,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CHỜ DUYỆT',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(data['submittedAt']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Recipe content
                      Row(
                        children: [
                          // Media preview
                          _buildMediaPreview(doc, data),
                          const SizedBox(width: 16),
                          
                          // Recipe info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Không có tên',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                
                                // Submitted by
                                Row(
                                  children: [
                                    const Icon(
                                      Iconsax.user,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Người gửi: ${data['submittedBy'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                
                                // Recipe details
                                Row(
                                  children: [
                                    Icon(Iconsax.clock, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data['time'] ?? 0} phút',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Iconsax.flash_1, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data['cal'] ?? 0} cal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                
                                Text(
                                  '${data['cuisine'] ?? 'N/A'} • ${data['difficulty'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveRecipe(doc, data),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Duyệt'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rejectRecipe(doc, data),
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text('Từ chối'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminRecipeEditor(
                                    documentId: doc.id,
                                    initialData: data,
                                    isPending: true,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Xem'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMediaPreview(DocumentSnapshot doc, Map<String, dynamic> data) {
    final videoUrl = data['videoUrl'] as String?;
    final imageUrl = data['image'] as String?;

    if (videoUrl != null && videoUrl.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              VideoPlayerWidget(
                videoUrl: videoUrl,
                autoPlay: false,
                showControls: false,
                aspectRatio: 1,
              ),
              const Center(
                child: Icon(
                  Iconsax.play,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.image_not_supported, size: 32),
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[200],
      ),
      child: const Icon(Icons.image_not_supported, size: 32),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    }
    return 'N/A';
  }

  Future<void> _approveRecipe(DocumentSnapshot doc, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text('Bạn có chắc chắn muốn duyệt công thức "${data['name']}"?'),
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

    if (confirmed == true) {
      try {
        // Tạo document mới trong RecipeApp collection
        final recipeData = Map<String, dynamic>.from(data);
        final submitterId = recipeData['submittedBy'];
        
        // Clean up pending-specific fields
        recipeData.remove('submittedBy');
        recipeData.remove('submittedAt');
        recipeData.remove('status');
        
        // Set approved fields
        recipeData['createdAt'] = FieldValue.serverTimestamp();
        recipeData['approvedAt'] = FieldValue.serverTimestamp();
        recipeData['ownerId'] = submitterId; // Preserve owner for user management
        
        // Ensure required fields exist
        if (!recipeData.containsKey('ingredientsAmount')) {
          recipeData['ingredientsAmount'] = [];
        }
        if (!recipeData.containsKey('ingredientsImage')) {
          recipeData['ingredientsImage'] = [];
        }
        if (!recipeData.containsKey('likeCount')) {
          recipeData['likeCount'] = 0;
        }
        if (!recipeData.containsKey('ratingAverage')) {
          recipeData['ratingAverage'] = 0.0;
        }
        if (!recipeData.containsKey('reviewsCount')) {
          recipeData['reviewsCount'] = 0;
        }
        
        // Add to approved recipes
        final added = await FirebaseFirestore.instance
            .collection('RecipeApp')
            .add(recipeData);
        
        // Remove from pending
        await doc.reference.delete();
        
        // Send notification to submitter
        if (submitterId != null && submitterId.toString().isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(submitterId.toString())
              .collection('notifications')
              .add({
            'title': 'Công thức được duyệt',
            'body': '"${recipeData['name']}" đã được duyệt và xuất bản',
            'type': 'recipe_approved',
            'data': added.id,
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
      }
    }
  }

  Future<void> _rejectRecipe(DocumentSnapshot doc, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận từ chối'),
        content: Text('Bạn có chắc chắn muốn từ chối công thức "${data['name']}"?'),
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

    if (confirmed == true) {
      try {
        // Remove from pending
        await doc.reference.delete();
        
        // Send notification to submitter
        final submitterId = data['submittedBy']?.toString();
        if (submitterId != null && submitterId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(submitterId)
              .collection('notifications')
              .add({
            'title': 'Công thức bị từ chối',
            'body': '"${data['name']}" đã bị từ chối',
            'type': 'recipe_rejected',
            'data': doc.id,
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
      }
    }
  }
}
