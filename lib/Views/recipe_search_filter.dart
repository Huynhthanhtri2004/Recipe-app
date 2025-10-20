import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Utils/constants.dart';

class RecipeSearchFilter extends StatefulWidget {
  const RecipeSearchFilter({super.key});

  @override
  State<RecipeSearchFilter> createState() => _RecipeSearchFilterState();
}

class _RecipeSearchFilterState extends State<RecipeSearchFilter> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _recipes = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  
  // Search & Filter states
  String _searchQuery = '';
  List<String> _selectedCategories = [];
  String _selectedDifficulty = 'all';
  String _selectedCuisine = 'all';
  String _sortBy = 'newest';
  RangeValues _timeRange = const RangeValues(0, 180);
  RangeValues _caloriesRange = const RangeValues(0, 1000);
  
  // Available options
  final List<String> _categories = [
    'Món chính', 'Món khai vị', 'Món tráng miệng', 'Món chay',
    'Món nhanh', 'Món truyền thống', 'Món quốc tế', 'Món nướng',
    'Món hấp', 'Món chiên'
  ];
  
  final List<String> _difficulties = ['Dễ', 'Trung bình', 'Khó'];
  final List<String> _cuisines = [
    'Việt Nam', 'Trung Quốc', 'Hàn Quốc', 'Nhật Bản', 'Thái Lan',
    'Ấn Độ', 'Ý', 'Pháp', 'Mỹ', 'Quốc tế'
  ];
  
  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Mới nhất'},
    {'value': 'rating', 'label': 'Rating cao nhất'},
    {'value': 'popular', 'label': 'Phổ biến nhất'},
    {'value': 'time', 'label': 'Thời gian nấu'},
    {'value': 'calories', 'label': 'Calories thấp nhất'},
  ];

  @override
  void initState() {
    super.initState();
    _searchRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRecipes({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;
    
    setState(() => _isLoading = true);
    
    try {
      Query query = FirebaseFirestore.instance.collection('RecipeApp');
      
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        query = query.where('name', isGreaterThanOrEqualTo: _searchQuery)
                    .where('name', isLessThan: _searchQuery + 'z');
      }
      
      // Apply category filter
      if (_selectedCategories.isNotEmpty) {
        query = query.where('mealType', whereIn: _selectedCategories);
      }
      
      // Apply difficulty filter
      if (_selectedDifficulty != 'all') {
        query = query.where('difficulty', isEqualTo: _selectedDifficulty);
      }
      
      // Apply cuisine filter
      if (_selectedCuisine != 'all') {
        query = query.where('cuisine', isEqualTo: _selectedCuisine);
      }
      
      // Apply time range filter
      query = query.where('time', isGreaterThanOrEqualTo: _timeRange.start.round())
                  .where('time', isLessThanOrEqualTo: _timeRange.end.round());
      
      // Apply calories range filter
      query = query.where('cal', isGreaterThanOrEqualTo: _caloriesRange.start.round())
                  .where('cal', isLessThanOrEqualTo: _caloriesRange.end.round());
      
      // Apply sorting
      switch (_sortBy) {
        case 'rating':
          query = query.orderBy('ratingAverage', descending: true);
          break;
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'popular':
          query = query.orderBy('likeCount', descending: true);
          break;
        case 'time':
          query = query.orderBy('time');
          break;
        case 'calories':
          query = query.orderBy('cal');
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
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == value) {
        _searchRecipes(refresh: true);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _searchRecipes(refresh: true);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedDifficulty = 'all';
      _selectedCuisine = 'all';
      _sortBy = 'newest';
      _timeRange = const RangeValues(0, 180);
      _caloriesRange = const RangeValues(0, 1000);
    });
    _searchRecipes(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm Recipes'),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => _searchRecipes(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm recipes...',
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          // Filter Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Quick Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedCategories.isEmpty && 
                                 _selectedDifficulty == 'all' && 
                                 _selectedCuisine == 'all',
                        onSelected: (selected) => _resetFilters(),
                      ),
                      const SizedBox(width: 8),
                      ..._categories.take(5).map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategories.contains(category),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                            _searchRecipes(refresh: true);
                          },
                        ),
                      )),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Advanced Filter Button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAdvancedFilters(),
                        icon: const Icon(Iconsax.filter),
                        label: const Text('Bộ lọc nâng cao'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kprimaryColor,
                          foregroundColor: Colors.white,
                        ),
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
                          _searchRecipes(refresh: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Results
          Expanded(
            child: _recipes.isEmpty && !_isLoading
                ? const Center(child: Text('Không tìm thấy recipes'))
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
                                    onPressed: _searchRecipes,
                                    child: const Text('Load More'),
                                  ),
                                ),
                              );
                      }
                      
                      final recipe = _recipes[index];
                      final data = recipe.data() as Map<String, dynamic>;
                      
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
                                  Icon(Iconsax.star, size: 16, color: Colors.amber),
                                  Text(' ${data['ratingAverage'] ?? 0}'),
                                  const SizedBox(width: 16),
                                  Icon(Iconsax.heart, size: 16, color: Colors.red),
                                  Text(' ${data['likeCount'] ?? 0}'),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Iconsax.arrow_right_3),
                          onTap: () {
                            // Navigate to recipe detail
                            // Navigator.push(context, MaterialPageRoute(
                            //   builder: (context) => RecipeDetailScreen(documentSnapshot: recipe),
                            // ));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bộ lọc nâng cao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedCategories.clear();
                        _selectedDifficulty = 'all';
                        _selectedCuisine = 'all';
                        _timeRange = const RangeValues(0, 180);
                        _caloriesRange = const RangeValues(0, 1000);
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Categories
              const Text('Danh mục', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                children: _categories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategories.contains(category),
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  ),
                )).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Difficulty
              const Text('Độ khó', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                children: _difficulties.map((difficulty) => Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: FilterChip(
                    label: Text(difficulty),
                    selected: _selectedDifficulty == difficulty,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedDifficulty = selected ? difficulty : 'all';
                      });
                    },
                  ),
                )).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Cuisine
              const Text('Ẩm thực', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                children: _cuisines.map((cuisine) => Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: FilterChip(
                    label: Text(cuisine),
                    selected: _selectedCuisine == cuisine,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedCuisine = selected ? cuisine : 'all';
                      });
                    },
                  ),
                )).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Time Range
              Text('Thời gian nấu: ${_timeRange.start.round()}-${_timeRange.end.round()} phút'),
              RangeSlider(
                values: _timeRange,
                min: 0,
                max: 180,
                divisions: 18,
                labels: RangeLabels('${_timeRange.start.round()} phút', '${_timeRange.end.round()} phút'),
                onChanged: (values) {
                  setModalState(() {
                    _timeRange = values;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Calories Range
              Text('Calories: ${_caloriesRange.start.round()}-${_caloriesRange.end.round()}'),
              RangeSlider(
                values: _caloriesRange,
                min: 0,
                max: 1000,
                divisions: 20,
                labels: RangeLabels('${_caloriesRange.start.round()}', '${_caloriesRange.end.round()}'),
                onChanged: (values) {
                  setModalState(() {
                    _caloriesRange = values;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Update main state with modal state
                    });
                    _searchRecipes(refresh: true);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Áp dụng bộ lọc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
