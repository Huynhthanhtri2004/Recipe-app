import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/Provider/auth_provider.dart' as app_auth;
import 'package:recipe_app/Utils/constants.dart';
import 'user_management_screen.dart';
import 'pending_recipes_approval.dart';

    const _AdminDashboardPage(),
    const PendingRecipesApproval(),
    const UserManagementScreen(),
    const _AdminCommentsPage(),
    const AdminCategoriesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: () async {
              await Provider.of<app_auth.AuthProvider>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kprimaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
            activeIcon: Icon(Icons.dashboard),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_top), 
            label: 'Duyệt công thức',
            activeIcon: Icon(Icons.hourglass_top),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt), 
            label: 'Quản lý người dùng',
            activeIcon: Icon(Icons.people_alt),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.comment_bank), 
            label: 'Bình luận',
            activeIcon: Icon(Icons.comment_bank),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category), 
            label: 'Danh mục',
            activeIcon: Icon(Icons.category),
          ),
        ],
      ),
    );
  }
}



class _AdminCommentsPage extends StatefulWidget {
  const _AdminCommentsPage();

  @override
  State<_AdminCommentsPage> createState() => _AdminCommentsPageState();
}

class _AdminCommentsPageState extends State<_AdminCommentsPage> {
  bool _useAlternativeMethod = false;

  String _initialOf(String? name) {
    final value = (name ?? '').trim();
    if (value.isEmpty) return 'U';
    return value[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý bình luận'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              setState(() {
                _useAlternativeMethod = !_useAlternativeMethod;
              });
            },
            tooltip: _useAlternativeMethod ? 'Dùng CollectionGroup' : 'Dùng phương pháp khác',
          ),
        ],
      ),
      body: _buildAlternativeCommentsView(), // Sử dụng phương pháp alternative ngay
    );
  }

  Widget _buildCollectionGroupView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('reviews')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          bool isPermissionError = error.contains('permission-denied');
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermissionError ? Icons.security : Icons.error,
                  size: 64,
                  color: isPermissionError ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isPermissionError 
                      ? 'Lỗi quyền truy cập Firestore'
                      : 'Lỗi tải bình luận',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    isPermissionError
                        ? 'Cần cập nhật Firestore Security Rules để cho phép admin truy cập collectionGroup("reviews")'
                        : 'Lỗi: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                if (isPermissionError) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _useAlternativeMethod = true;
                      });
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Dùng phương pháp khác'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
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
                Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Không có bình luận nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Bình luận sẽ xuất hiện ở đây khi người dùng đánh giá công thức',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: kprimaryColor.withOpacity(0.1),
                          child: Text(
                            _initialOf(data['userName']?.toString()),
                            style: TextStyle(
                              color: kprimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? 'Người dùng',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            final rating = data['rating'] as int? ?? 0;
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['comment'] ?? 'Không có nội dung',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              await d.reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã xóa bình luận'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi xóa bình luận: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlternativeCommentsView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllComments(),
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
                Text('Lỗi tải bình luận: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        
        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Không có bình luận nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Bình luận sẽ xuất hiện ở đây khi người dùng đánh giá công thức',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: comments.length,
          itemBuilder: (context, i) {
            final comment = comments[i];
            final timestamp = comment['timestamp'] as Timestamp?;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: kprimaryColor.withOpacity(0.1),
                          child: Text(
                            _initialOf(comment['userName']?.toString()),
                            style: TextStyle(
                              color: kprimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['userName'] ?? 'Người dùng',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            final rating = comment['rating'] as int? ?? 0;
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      comment['comment'] ?? 'Không có nội dung',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              await comment['reference'].delete();
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã xóa bình luận'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi xóa bình luận: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAllComments() async {
    final List<Map<String, dynamic>> allComments = [];
    
    try {
      // Lấy tất cả recipes
      final recipesSnapshot = await FirebaseFirestore.instance
          .collection('RecipeApp')
          .get();
      
      for (final recipeDoc in recipesSnapshot.docs) {
        final reviewsSnapshot = await recipeDoc.reference
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .get();
        
        for (final reviewDoc in reviewsSnapshot.docs) {
          final data = reviewDoc.data();
          allComments.add({
            ...data,
            'recipeName': recipeDoc['name'],
            'recipeId': recipeDoc.id,
            'reference': reviewDoc.reference,
          });
        }
      }
      
      // Sắp xếp theo timestamp
      allComments.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return allComments.take(100).toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }
  
  String _formatTimestamp(Timestamp timestamp) {
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
}

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    final recipes = FirebaseFirestore.instance.collection('RecipeApp');
    final pending = FirebaseFirestore.instance.collection('recipes_pending');
    final users = FirebaseFirestore.instance.collection('users');

    return FutureBuilder<List<int>>(
      future: Future.wait([
        recipes.count().get().then((a) => a.count ?? 0),
        pending.count().get().then((a) => a.count ?? 0),
        users.count().get().then((a) => a.count ?? 0),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          children: [
            _statCard('Công thức', data[0], Icons.menu_book, Colors.blue),
            _statCard('Chờ duyệt', data[1], Icons.hourglass_top, Colors.orange),
            _statCard('Người dùng', data[2], Icons.people, Colors.green),
          ],
        );
      },
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value.toString(), style: const TextStyle(fontSize: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('App-Category');
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];
              return ListTile(
                title: Text(d['name'] ?? d.id),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showDialog(context, ref, d.id, d['name'] ?? ''),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => d.reference.delete(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, ref, null, ''),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDialog(BuildContext context, CollectionReference ref, String? id, String initial) {
    final controller = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Thêm danh mục' : 'Sửa danh mục'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Tên')), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              if (id == null) {
                await ref.add({'name': name});
              } else {
                await ref.doc(id).set({'name': name}, SetOptions(merge: true));
              }
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

