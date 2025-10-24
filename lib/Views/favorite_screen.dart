import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/Provider/favorite_provider.dart';
import 'package:recipe_app/Utils/constants.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key})
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
      body: favoriteItems.isEmpty
          ? Center(
        child: Text(
          "No Favorites yet",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      )
          : ListView.builder(
        itemCount: favoriteItems.length,
        itemBuilder: (context, index) {
          String favorite = favoriteItems[index];
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("RecipeApp")
                .doc(favorite)
                .get(),
            builder: (context, snapshot) {
              // Kiểm tra mounted trước khi xây dựng
              if (!mounted) return const SizedBox.shrink();
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi tải mục yêu thích: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final favoriteItem = snapshot.data!;

              // Nếu document không tồn tại (đã bị xóa), hiển thị placeholder và cho phép xóa khỏi favorites
              if (!favoriteItem.exists) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('Công thức không còn tồn tại'),
                  subtitle: Text('ID: ${favoriteItem.id}'),
                  trailing: IconButton(
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        provider.toggleFavorite(favoriteItem);
                      });
                    },
                  ),
                );
              }

              final data = (favoriteItem.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
              final imageUrl = (data['image'] ?? '').toString();
              final name = (data['name'] ?? 'Không có tên').toString();
              final cal = data['cal']?.toString() ?? '0';
              final time = data['time']?.toString() ?? '0';

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(imageUrl),
                                    )
                                  : null,
                              color: imageUrl.isEmpty ? Colors.grey[200] : null,
                            ),
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.image, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.flash_1,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    "$cal Cal",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Text(
                                    ".",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Icon(
                                    Iconsax.clock,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "$time Min",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // delete
                  Positioned(
                    top: 50,
                    right: 35,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          provider.toggleFavorite(favoriteItem);
                        });
                      },
                      child: const Icon(
                        Iconsax.trash,
                        color: Colors.red,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}