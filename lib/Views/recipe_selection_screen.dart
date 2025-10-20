import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Views/food_items_display.dart';

class RecipeSelectionScreen extends StatelessWidget {
  final Function(DocumentSnapshot) onRecipeSelected;

  const RecipeSelectionScreen({
    Key? key,
    required this.onRecipeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Recipe'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.close_circle),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('RecipeApp').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(recipe['image']),
                      ),
                    ),
                  ),
                  title: Text(
                    recipe['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${recipe['cal']} Cal • ${recipe['time']} Min',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Iconsax.add),
                    onPressed: () {
                      Navigator.pop(context, recipe);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}