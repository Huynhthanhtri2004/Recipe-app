import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/Provider/collections_provider.dart';
import 'package:recipe_app/Views/food_items_display.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bộ sưu tập'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: () => _showCreateCollectionDialog(),
          ),
        ],
      ),
      body: Consumer<CollectionsProvider>(
        builder: (context, provider, child) {
          if (provider.collections.isEmpty) {
            return const Center(
              child: Text('Chưa có bộ sưu tập nào'),
            );
          }

          return ListView.builder(
            itemCount: provider.collections.length,
            itemBuilder: (context, index) {
              final collection = provider.collections[index];
              return _buildCollectionCard(collection);
            },
          );
        },
      ),
    );
  }

  Widget _buildCollectionCard(Map<String, dynamic> collection) {
    final recipeIds = (collection['recipeIds'] as List<dynamic>?) ?? [];
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: const Icon(Iconsax.folder, size: 32),
        title: Text(
          collection['name'] ?? 'Unnamed Collection',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${recipeIds.length} công thức',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('Xem'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Xóa'),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _viewCollection(collection);
            } else if (value == 'delete') {
              _deleteCollection(collection['id']);
            }
          },
        ),
        onTap: () => _viewCollection(collection),
      ),
    );
  }

  void _viewCollection(Map<String, dynamic> collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionDetailScreen(collection: collection),
      ),
    );
  }

  void _deleteCollection(String collectionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bộ sưu tập'),
        content: const Text('Bạn có chắc muốn xóa bộ sưu tập này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CollectionsProvider>(context, listen: false)
                  .deleteCollection(collectionId);
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo bộ sưu tập mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên bộ sưu tập',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Provider.of<CollectionsProvider>(context, listen: false)
                    .createCollection(
                      nameController.text.trim(),
                      descriptionController.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}

class CollectionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final recipeIds = (collection['recipeIds'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(collection['name'] ?? 'Collection'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: recipeIds.isEmpty
          ? const Center(
              child: Text('Bộ sưu tập trống'),
            )
          : ListView.builder(
              itemCount: recipeIds.length,
              itemBuilder: (context, index) {
                final recipeId = recipeIds[index] as String;
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('RecipeApp')
                      .doc(recipeId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Loading...'),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const ListTile(
                        leading: Icon(Icons.error),
                        title: Text('Recipe not found'),
                      );
                    }
                    return FoodItemsDisplay(documentSnapshot: snapshot.data!);
                  },
                );
              },
            ),
    );
  }
}
