import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Views/improved_submit_recipe_screen.dart';
import 'package:recipe_app/Views/recipe_detail_screen.dart';

class UserRecipeManagementScreen extends StatefulWidget {
  const UserRecipeManagementScreen({super.key});

  @override
  State<UserRecipeManagementScreen> createState() => _UserRecipeManagementScreenState();
}

class _UserRecipeManagementScreenState extends State<UserRecipeManagementScreen>
    with SingleTickerProviderState

  @override
  void dispose() {
    _tabController.dispose();
    super.dispowait _fir

      // Gộp kết quả và loại bỏ trùng lặp
      final allDocs = <DocumentSnapshot>[];
      final seenIds = <String>{};

      for (final doc in submittedByQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          allDocs.add(doc);
          seenIds.add(doc.id);
        }
      }

      for (final doc in ownerIdQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          allDocs.add(doc);
          seenIds.add(doc.id);
        }
      }

      // Sắp xếp theo createdAt
      allDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>?;
        final bData = b.data() as Map<String, dynamic>?;
        final aTime = aData?['createdAt'] as Timestamp?;
        final bTime = bData?['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return allDocs;
    } catch (e) {
      print('Error getting user recipes: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý công thức'),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Đã duyệt', icon: Icon(Iconsax.tick_circle)),
            Tab(text: 'Chờ duyệt', icon: Icon(Iconsax.clock)),
            Tab(text: 'Bị từ chối', icon: Icon(Iconsax.close_circle)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Iconsax.refresh),
            tooltip: 'Làm mới',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImprovedSubmitRecipeScreen(),
                ),
              );
            },
            icon: const Icon(Iconsax.add),
            tooltip: 'Thêm công thức mới',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovedRecipes(),
          _buildPendingRecipes(),
          _buildRejectedRecipes(),
        ],
      ),
    );
  }

  Widget _buildApprovedRecipes() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getUserRecipes(user.uid),
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

        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.tick_circle,
            title: 'Chưa có công thức đã duyệt',
            subtitle: 'Công thức của bạn sau khi được admin duyệt sẽ hiển thị ở đây\n\n'
                '💡 Mẹo: Hãy kiểm tra tab "Chờ duyệt" để xem công thức đang chờ admin duyệt',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRecipeCard(doc, data, 'approved');
          },
        );
      },
    );
  }

  Widget _buildPendingRecipes() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('recipes_pending')
          .where('submittedBy', isEqualTo: user.uid)
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
          return _buildEmptyState(
            icon: Iconsax.clock,
            title: 'Chưa có công thức chờ duyệt',
            subtitle: 'Công thức bạn gửi đang chờ admin duyệt sẽ hiển thị ở đây',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRecipeCard(doc, data, 'pending');
          },
        );
      },
    );
  }

  Widget _buildRejectedRecipes() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('recipes_pending')
          .where('submittedBy', isEqualTo: user.uid)
          .where('status', isEqualTo: 'rejected')
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
          return _buildEmptyState(
            icon: Iconsax.close_circle,
            title: 'Chưa có công thức bị từ chối',
            subtitle: 'Công thức bị admin từ chối sẽ hiển thị ở đây',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRecipeCard(doc, data, 'rejected');
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImprovedSubmitRecipeScreen(),
                ),
              );
            },
            icon: const Icon(Iconsax.add),
            label: const Text('Thêm công thức mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kprimaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(DocumentSnapshot doc, Map<String, dynamic> data, String status) {
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isApproved
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(documentSnapshot: doc),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Hình ảnh
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (data['image'] ?? '').toString().isNotEmpty
                          ? Image.network(
                              data['image'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 32),
                            )
                          : const Icon(Icons.image, size: 32, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Thông tin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Không có tên',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Trạng thái
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? Colors.green.withOpacity(0.1)
                                : isPending
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isApproved
                                ? 'Đã duyệt'
                                : isPending
                                    ? 'Chờ duyệt'
                                    : 'Bị từ chối',
                            style: TextStyle(
                              color: isApproved
                                  ? Colors.green
                                  : isPending
                                      ? Colors.orange
                                      : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Thông tin chi tiết
                        Row(
                          children: [
                            Icon(Iconsax.clock, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${data['time'] ?? 0} phút',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Iconsax.flash_1, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${data['cal'] ?? 0} cal',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Nút hành động
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value, doc, data, status),
                    itemBuilder: (context) => [
                      if (isApproved)
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Iconsax.eye, size: 16),
                              SizedBox(width: 8),
                              Text('Xem chi tiết'),
                            ],
                          ),
                        ),
                      if (isPending || isRejected)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Iconsax.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                      if (isPending || isRejected)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Iconsax.trash, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                    child: const Icon(Iconsax.more),
                  ),
                ],
              ),

              // Lý do từ chối (nếu có)
              if (isRejected && data['rejectionReason'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.info_circle, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lý do từ chối: ${data['rejectionReason']}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(String action, DocumentSnapshot doc, Map<String, dynamic> data, String status) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(documentSnapshot: doc),
          ),
        );
        break;
      case 'edit':
        // TODO: Implement edit functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tính năng chỉnh sửa đang được phát triển')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(doc, data['name'] ?? 'công thức này');
        break;
    }
  }

  void _showDeleteConfirmation(DocumentSnapshot doc, String recipeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "$recipeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await doc.reference.delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa công thức'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi xóa: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
