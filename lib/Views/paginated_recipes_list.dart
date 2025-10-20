import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Views/admin_recipe_editor.dart';

class PaginatedRecipesList extends StatefulWidget {
  final String? status; // 'approved', 'pending', or null for all
  const PaginatedRecipesList({super.key, this.status});

  @override
  State<PaginatedRecipesList> createState() => _PaginatedRecipesListState();
}

class _PaginatedRecipesListState extends State<PaginatedRecipesList> {
  List<DocumentSnapshot> _recipes = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  String _sortBy = 'newest';

  final List<String> _categories = [
    'Món chính', 'Món khai vị', 'Món tráng miệng', 'Món chay',
    'Món nhanh', 'Món truyền thống', 'Món quốc tế', 'Món nướng',
    'Món hấp', 'Món chiên'
  ];

  final List<String> _difficulties = ['Dễ', 'Trung bình', 'Khó'];

  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Mới nhất'},
    {'value': 'rating', 'label': 'Rating cao nhất'},
    {'value': 'popular', 'label': 'Phổ biến nhất'},
    {'value': 'time', 'label': 'Thời gian nấu'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;
    
    setState(() => _isLoading = true);
    
    try {
      Query query = FirebaseFirestore.instance.collection('RecipeApp');
      
      // Apply status filter
      if (widget.status != null) {
        query = query.where('status', isEqualTo: widget.status);
      }
      
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        query = query.where('name', isGreaterThanOrEqualTo: _searchQuery)
                    .where('name', isLessThan: _searchQuery + 'z');
      }
      
      // Apply category filter
      if (_selectedCategory != 'all') {
        query = query.where('mealType', isEqualTo: _selectedCategory);
      }
      
      // Apply difficulty filter
      if (_selectedDifficulty != 'all') {
        query = query.where('difficulty', isEqualTo: _selectedDifficulty);
      }
      
      // Apply sorting
      switch (_sortBy) {
        case 'rating':
          query = query.orderBy('ratingAverage', descending: true);
          break;
        case 'newest':
          // Ưu tiên createdAt; nếu thiếu hãy fallback approvedAt, nếu vẫn thiếu fallback submittedAt
          // Lưu ý: Firestore không hỗ trợ orderBy nhiều trường với fallback trong 1 query,
          // nên ta ưu tiên createdAt; nếu không có dữ liệu trả về, lần tải sau ta có thể chuyển tiêu chí.
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'popular':
          query = query.orderBy('likeCount', descending: true);
          break;
        case 'time':
          query = query.orderBy('time');
          break;
      }
      
      // Apply pagination
      if (refresh) {
        _recipes.clear();
        _lastDocument = null;
        _hasMore = true;
      } else if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      QuerySnapshot snapshot = await query.limit(20).get();
      
      setState(() {
        if (refresh) {
          _recipes = snapshot.docs;
        } else {
          _recipes.addAll(snapshot.docs);
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

  Future<void> _approveRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance.collection('RecipeApp').doc(recipeId).update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã duyệt recipe'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecipes(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi duyệt recipe: $e')),
        );
      }
    }
  }

  Future<void> _rejectRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance.collection('RecipeApp').doc(recipeId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối recipe'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRecipes(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi từ chối recipe: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance.collection('RecipeApp').doc(recipeId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa recipe'),
            backgroundColor: Colors.red,
          ),
        );
        _loadRecipes(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa recipe: $e')),
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
                  hintText: 'Tìm kiếm recipes...',
                  prefixIcon: const Icon(Iconsax.search_normal),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Iconsax.close_circle),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _loadRecipes(refresh: true);
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
                      _loadRecipes(refresh: true);
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
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        ..._categories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                        _loadRecipes(refresh: true);
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
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                        ..._difficulties.map((difficulty) => DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDifficulty = value!);
                        _loadRecipes(refresh: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sắp xếp',
                        border: OutlineInputBorder(),
                      ),
                      items: _sortOptions.map((option) => DropdownMenuItem(
                        value: option['value'],
                        child: Text(option['label']!),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _sortBy = value!);
                        _loadRecipes(refresh: true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Recipes List
        Expanded(
          child: _recipes.isEmpty && !_isLoading
              ? const Center(child: Text('Không có recipes'))
              : ListView.builder(
                  itemCount: _recipes.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _recipes.length) {
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
                                  onPressed: _loadRecipes,
                                  child: const Text('Load More'),
                                ),
                              ),
                            );
                    }
                    
                    final recipe = _recipes[index];
                    final data = recipe.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final isPending = status == 'pending';
                    final isApproved = status == 'approved';
                    final isRejected = status == 'rejected';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['image'] ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Iconsax.image),
                            ),
                          ),
                        ),
                        title: Text(data['name'] ?? 'No name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${data['cuisine'] ?? ''} • ${data['difficulty'] ?? ''} • ${data['time'] ?? 0} phút'),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPending ? Colors.orange : 
                                           isApproved ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Iconsax.star, size: 16, color: Colors.amber),
                                Text(' ${data['ratingAverage'] ?? 0}'),
                                const SizedBox(width: 16),
                                Icon(Iconsax.heart, size: 16, color: Colors.red),
                                Text(' ${data['likeCount'] ?? 0}'),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPending) ...[
                              IconButton(
                                icon: const Icon(Iconsax.tick_circle, color: Colors.green),
                                onPressed: () => _approveRecipe(recipe.id),
                              ),
                              IconButton(
                                icon: const Icon(Iconsax.close_circle, color: Colors.red),
                                onPressed: () => _rejectRecipe(recipe.id),
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Iconsax.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminRecipeEditor(
                                      documentId: recipe.id,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'delete':
                                    _deleteRecipe(recipe.id);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Iconsax.trash, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Xóa'),
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
