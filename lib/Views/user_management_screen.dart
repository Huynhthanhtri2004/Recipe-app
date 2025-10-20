import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Views/admin_recipe_editor.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<DocumentSnapshot> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  String _selectedRole = 'all';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;
    
    setState(() => _isLoading = true);
    
    try {
      Query query = FirebaseFirestore.instance.collection('users');
      
      // Apply filters
      if (_selectedRole != 'all') {
        query = query.where('role', isEqualTo: _selectedRole);
      }
      if (_selectedStatus != 'all') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }
      
      // Apply search
      if (_searchQuery.isNotEmpty) {
        query = query.where('email', isGreaterThanOrEqualTo: _searchQuery)
                    .where('email', isLessThan: _searchQuery + 'z');
      }
      
      // Apply pagination
      if (refresh) {
        _users.clear();
        _lastDocument = null;
        _hasMore = true;
      } else if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      QuerySnapshot snapshot = await query.limit(20).get();
      
      setState(() {
        if (refresh) {
          _users = snapshot.docs;
        } else {
          _users.addAll(snapshot.docs);
        }
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, bool isLocked) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': isLocked ? 'locked' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLocked ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thay đổi role thành $newRole'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo email...',
                  prefixIcon: const Icon(Iconsax.search_normal),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Iconsax.close_circle),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _loadUsers(refresh: true);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchQuery == value) {
                      _loadUsers(refresh: true);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              // Filter Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedRole = value!);
                        _loadUsers(refresh: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'locked', child: Text('Locked')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                        _loadUsers(refresh: true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Users List
        Expanded(
          child: _users.isEmpty && !_isLoading
              ? const Center(child: Text('Không có người dùng'))
              : ListView.builder(
                  itemCount: _users.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _users.length) {
                      return _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: ElevatedButton(
                                  onPressed: _loadUsers,
                                  child: const Text('Load More'),
                                ),
                              ),
                            );
                    }
                    
                    final user = _users[index];
                    final data = user.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? 'active').toString();
                    final isLocked = status != 'active';
                    final role = data['role'] ?? 'user';
                    final email = data['email'] ?? 'No email';
                    final displayName = data['displayName'] ?? 'No name';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLocked ? Colors.red : kprimaryColor,
                          child: Icon(
                            isLocked ? Iconsax.lock : Iconsax.user,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(displayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            Row(
                              children: [
                                Chip(
                                  label: Text(role.toUpperCase()),
                                  backgroundColor: role == 'admin' ? Colors.blue : Colors.grey,
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(isLocked ? 'LOCKED' : 'ACTIVE'),
                                  backgroundColor: isLocked ? Colors.red : Colors.green,
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Iconsax.eye, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailScreen(userId: user.id, userData: data),
                                  ),
                                );
                              },
                              tooltip: 'Xem chi tiết',
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'toggle_status':
                                    _toggleUserStatus(user.id, !isLocked);
                                    break;
                                  case 'make_admin':
                                    _changeUserRole(user.id, 'admin');
                                    break;
                                  case 'make_user':
                                    _changeUserRole(user.id, 'user');
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle_status',
                                  child: Row(
                                    children: [
                                      Icon(isLocked ? Iconsax.unlock : Iconsax.lock),
                                      const SizedBox(width: 8),
                                      Text(isLocked ? 'Mở khóa' : 'Khóa tài khoản'),
                                    ],
                                  ),
                                ),
                                if (role != 'admin')
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Row(
                                      children: [
                                        Icon(Iconsax.crown),
                                        SizedBox(width: 8),
                                        Text('Thăng làm Admin'),
                                      ],
                                    ),
                                  ),
                                if (role == 'admin')
                                  const PopupMenuItem(
                                    value: 'make_user',
                                    child: Row(
                                      children: [
                                        Icon(Iconsax.user),
                                        SizedBox(width: 8),
                                        Text('Hạ xuống User'),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết người dùng'),
          backgroundColor: kprimaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Thông tin', icon: Icon(Iconsax.user)),
              Tab(text: 'Công thức', icon: Icon(Iconsax.document_text)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserInfoTab(),
            _buildUserRecipesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar and Basic Info
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: kprimaryColor,
                  child: Text(
                    (widget.userData['displayName'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.userData['displayName'] ?? 'Không có tên',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.userData['email'] ?? 'Không có email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // User Details
          _buildInfoCard('Thông tin tài khoản', [
            _buildInfoRow('ID', widget.userId),
            _buildInfoRow('Email', widget.userData['email'] ?? 'N/A'),
            _buildInfoRow('Tên hiển thị', widget.userData['displayName'] ?? 'N/A'),
            _buildInfoRow('Role', widget.userData['role'] ?? 'user'),
            _buildInfoRow('Trạng thái', widget.userData['status'] ?? 'active'),
            _buildInfoRow('Ngày tạo', _formatDate(widget.userData['createdAt'])),
            _buildInfoRow('Cập nhật cuối', _formatDate(widget.userData['updatedAt'])),
          ]),

          const SizedBox(height: 16),

          // Dietary Preferences
          if (widget.userData['dietaryPreferences'] != null)
            _buildInfoCard('Sở thích ăn uống', [
              ...((widget.userData['dietaryPreferences'] as List?) ?? [])
                  .map((pref) => _buildInfoRow('Sở thích', pref.toString())),
            ]),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final isLocked = (widget.userData['status'] ?? 'active') != 'active';
                    _toggleUserStatus(!isLocked);
                  },
                  icon: Icon(
                    (widget.userData['status'] ?? 'active') != 'active' 
                        ? Iconsax.unlock 
                        : Iconsax.lock,
                  ),
                  label: Text(
                    (widget.userData['status'] ?? 'active') != 'active' 
                        ? 'Mở khóa' 
                        : 'Khóa tài khoản',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (widget.userData['status'] ?? 'active') != 'active' 
                        ? Colors.green 
                        : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final currentRole = widget.userData['role'] ?? 'user';
                    final newRole = currentRole == 'admin' ? 'user' : 'admin';
                    _changeUserRole(newRole);
                  },
                  icon: Icon(
                    (widget.userData['role'] ?? 'user') == 'admin' 
                        ? Iconsax.user 
                        : Iconsax.crown,
                  ),
                  label: Text(
                    (widget.userData['role'] ?? 'user') == 'admin' 
                        ? 'Hạ xuống User' 
                        : 'Thăng làm Admin',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (widget.userData['role'] ?? 'user') == 'admin' 
                        ? Colors.orange 
                        : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserRecipesTab() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getUserRecipes(),
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
                Text('Lỗi tải công thức: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final recipes = snapshot.data ?? [];
        
        if (recipes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Người dùng chưa có công thức nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            final data = recipe.data() as Map<String, dynamic>?;
            if (data == null) return const SizedBox.shrink();

            final status = _getRecipeStatus(recipe);
            final statusColor = _getStatusColor(status);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 60,
                  height: 60,
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
                              const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                title: Text(
                  data['name'] ?? 'Không có tên',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data['time'] ?? 0} phút • ${data['cal'] ?? 0} cal'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'view':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminRecipeEditor(
                              documentId: recipe.id,
                              initialData: data,
                            ),
                          ),
                        );
                        break;
                      case 'approve':
                        await _approveRecipe(recipe, data);
                        break;
                      case 'reject':
                        await _rejectRecipe(recipe, data);
                        break;
                      case 'delete':
                        await _deleteRecipe(recipe, data);
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuItem<String>>[
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Iconsax.eye, size: 16),
                            SizedBox(width: 8),
                            Text('Xem/Chỉnh sửa'),
                          ],
                        ),
                      ),
                    ];

                    if (status == 'Chờ duyệt') {
                      items.addAll([
                        const PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(Icons.check, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Duyệt'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(Icons.close, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text('Từ chối'),
                            ],
                          ),
                        ),
                      ]);
                    }

                    items.add(
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    );

                    return items;
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
    }
    return 'N/A';
  }

  Future<List<DocumentSnapshot>> _getUserRecipes() async {
    try {
      // Lấy công thức từ RecipeApp (đã duyệt)
      final approvedRecipes = await FirebaseFirestore.instance
          .collection('RecipeApp')
          .where('ownerId', isEqualTo: widget.userId)
          .get();

      // Lấy công thức từ recipes_pending (chờ duyệt)
      final pendingRecipes = await FirebaseFirestore.instance
          .collection('recipes_pending')
          .where('submittedBy', isEqualTo: widget.userId)
          .get();

      // Gộp và sắp xếp
      final allRecipes = <DocumentSnapshot>[];
      allRecipes.addAll(approvedRecipes.docs);
      allRecipes.addAll(pendingRecipes.docs);

      // Sắp xếp theo thời gian
      allRecipes.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>?;
        final bData = b.data() as Map<String, dynamic>?;
        
        final aTime = aData?['createdAt'] as Timestamp? ?? aData?['submittedAt'] as Timestamp?;
        final bTime = bData?['createdAt'] as Timestamp? ?? bData?['submittedAt'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return allRecipes;
    } catch (e) {
      // Error getting user recipes: $e
      return [];
    }
  }

  String _getRecipeStatus(DocumentSnapshot recipe) {
    final data = recipe.data() as Map<String, dynamic>?;
    if (data == null) return 'Không xác định';

    // Nếu có trong RecipeApp collection thì đã duyệt
    if (recipe.reference.path.contains('RecipeApp')) {
      return 'Đã duyệt';
    }
    
    // Nếu có trong recipes_pending thì chờ duyệt
    if (recipe.reference.path.contains('recipes_pending')) {
      return 'Chờ duyệt';
    }

    return 'Không xác định';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã duyệt':
        return Colors.green;
      case 'Chờ duyệt':
        return Colors.orange;
      case 'Bị từ chối':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleUserStatus(bool isLocked) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'status': isLocked ? 'locked' : 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLocked ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  Future<void> _changeUserRole(String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thay đổi role thành $newRole'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  Future<void> _approveRecipe(DocumentSnapshot recipe, Map<String, dynamic> data) async {
    try {
      // Tạo document mới trong RecipeApp collection
      final recipeData = Map<String, dynamic>.from(data);
      recipeData['status'] = 'approved';
      recipeData['createdAt'] = FieldValue.serverTimestamp();
      recipeData['approvedAt'] = FieldValue.serverTimestamp();
      recipeData['ownerId'] = widget.userId;
      
      await FirebaseFirestore.instance
          .collection('RecipeApp')
          .add(recipeData);
      
      // Xóa document khỏi recipes_pending
      await recipe.reference.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Công thức đã được duyệt'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the list
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

  Future<void> _rejectRecipe(DocumentSnapshot recipe, Map<String, dynamic> data) async {
    try {
      await recipe.reference.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Công thức đã bị từ chối'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {}); // Refresh the list
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

  Future<void> _deleteRecipe(DocumentSnapshot recipe, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa công thức "${data['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await recipe.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Công thức đã được xóa'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresh the list
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
    }
  }
}
