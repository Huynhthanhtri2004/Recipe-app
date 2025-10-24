import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/Provider/shopping_list_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedCategory = 'Vegetables';
  bool _isLoading = false;

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Meat & Seafood',
    'Dairy & Eggs',
    'Grains & Bread',
    'Spices & Herbs',
    'Pantry Items',
    'Beverages',
    'Other'
  ];

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên nguyên liệu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final shoppingListProvider = Provider.of<ShoppingListProvider>(context, listen: false);
      await shoppingListProvider.addItem(
        _itemController.text.trim(),
        _quantityController.text.trim().isNotEmpty ? _quantityController.text.trim() : '1',
        _selectedCategory,
      );

      _itemController.clear();
      _quantityController.clear();
      setState(() {
        _selectedCategory = 'Vegetables';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào danh sách mua sắm')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Danh sách mua sắm'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash),
            onPressed: () => _showClearAllDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add item form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                     
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addItem,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Iconsax.add),
                      label: const Text('Thêm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Shopping list items
          Expanded(
            child: Consumer<ShoppingListProvider>(
              builder: (context, shoppingListProvider, child) {
                return StreamBuilder<QuerySnapshot>(
                  stream: shoppingListProvider.getShoppingListStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Lỗi: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    final items = snapshot.data?.docs ?? [];

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.shopping_cart,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Danh sách mua sắm trống',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Thêm nguyên liệu từ công thức hoặc nhập thủ công',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group items by category
                    final Map<String, List<DocumentSnapshot>> groupedItems = {};
                    for (final item in items) {
                      final category = item['category'] as String;
                      if (!groupedItems.containsKey(category)) {
                        groupedItems[category] = [];
                      }
                      groupedItems[category]!.add(item);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: groupedItems.length,
                      itemBuilder: (context, index) {
                        final category = groupedItems.keys.elementAt(index);
                        final categoryItems = groupedItems[category]!;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(category),
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${categoryItems.length} món',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...categoryItems.map((item) {
                                final isCompleted = item['isCompleted'] as bool? ?? false;
                                return ListTile(
                                  leading: Checkbox(
                                    value: isCompleted,
                                    onChanged: (value) async {
                                      await shoppingListProvider.toggleItem(
                                        item.id,
                                        value ?? false,
                                      );
                                    },
                                  ),
                                  title: Text(
                                    item['name'] as String,
                                    style: TextStyle(
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: isCompleted
                                          ? Colors.grey[500]
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Số lượng: ${item['quantity'] as String}',
                                    style: TextStyle(
                                      color: isCompleted
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Iconsax.trash, color: Colors.red),
                                    onPressed: () => _showDeleteDialog(item.id),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFromRecipeDialog(),
        icon: const Icon(Iconsax.document_text),
        label: const Text('Từ công thức'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Vegetables':
        return Iconsax.carrot;
      case 'Fruits':
        return Iconsax.apple;
      case 'Meat & Seafood':
        return Iconsax.fish;
      case 'Dairy & Eggs':
        return Iconsax.milk;
      case 'Grains & Bread':
        return Iconsax.wheat;
      case 'Spices & Herbs':
        return Iconsax.leaf;
      case 'Pantry Items':
        return Iconsax.box;
      case 'Beverages':
        return Iconsax.cup;
      default:
        return Iconsax.shopping_cart;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả'),
        content: const Text('Bạn có chắc muốn xóa tất cả món trong danh sách mua sắm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final shoppingListProvider = Provider.of<ShoppingListProvider>(context, listen: false);
              await shoppingListProvider.clearAllItems();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tất cả')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa món'),
        content: const Text('Bạn có chắc muốn xóa món này khỏi danh sách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final shoppingListProvider = Provider.of<ShoppingListProvider>(context, listen: false);
              await shoppingListProvider.deleteItem(itemId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa món')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddFromRecipeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm từ công thức'),
        content: const Text('Tính năng này sẽ cho phép bạn chọn công thức và tự động thêm nguyên liệu vào danh sách mua sắm.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to recipe selection screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang được phát triển')),
              );
            },
            child: const Text('Chọn công thức'),
          ),
        ],
      ),
    );
  }
}
