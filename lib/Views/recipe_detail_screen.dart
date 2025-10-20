import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:recipe_app/Provider/favorite_provider.dart';
import 'package:recipe_app/Provider/quantity.dart';
import 'package:recipe_app/Provider/collections_provider.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Widget/my_icon_button.dart';
import 'package:recipe_app/Widget/quantity_incerment_decrement.dart';
import 'package:recipe_app/Widget/video_player_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recipe_app/Views/cooking_guide_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final DocumentSnapshot<Object?> documentSnapshot;
  const RecipeDetailScreen({super.key, required this.documentSnapshot});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    // Ưu tiên schema mới 'ingredients' - kiểm tra an toàn
    List<double> baseAmounts = [];
    try {
      final List<dynamic> ingredientsObj = (widget.documentSnapshot['ingredients'] as List<dynamic>?) ?? [];
      if (ingredientsObj.isNotEmpty) {
        baseAmounts = ingredientsObj.map<double>((e) {
          final m = e as Map<String, dynamic>;
          return (m['amount'] as num?)?.toDouble() ?? 0.0;
        }).toList();
      }
    } catch (e) {
      // Field 'ingredients' chưa tồn tại, dùng schema cũ
    }
    
    if (baseAmounts.isEmpty) {
      // Fallback schema cũ
      final amounts = widget.documentSnapshot['ingredientsAmount'] ?? [];
      baseAmounts = (amounts as List).map<double>((amount) {
        return double.tryParse(amount.toString()) ?? 0.0;
      }).toList();
      if (baseAmounts.isEmpty) {
        baseAmounts = List.filled((widget.documentSnapshot['ingredientsName'] as List?)?.length ?? 0, 100.0);
      }
    }

    Provider.of<QuantityProvider>(context, listen: false)
        .setBaseIngredientAmounts(baseAmounts);

    _loadLikeStatus();
    super.initState();
  }

  Future<void> _loadLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('RecipeApp')
          .doc(widget.documentSnapshot.id)
          .collection('likes')
          .doc(user.uid)
          .get();

      final likeCountDoc = await FirebaseFirestore.instance
          .collection('RecipeApp')
          .doc(widget.documentSnapshot.id)
          .get();

      if (mounted) {
        setState(() {
          _isLiked = likeDoc.exists;
          _likeCount = likeCountDoc.data()?['likeCount'] ?? 0;
        });
      }
    } catch (e) {
      if (mounted && kDebugMode) {
        print('Error loading like status: $e');
      }
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final likeRef = FirebaseFirestore.instance
          .collection('RecipeApp')
          .doc(widget.documentSnapshot.id)
          .collection('likes')
          .doc(user.uid);

      final recipeRef = FirebaseFirestore.instance
          .collection('RecipeApp')
          .doc(widget.documentSnapshot.id);

      if (_isLiked) {
        await likeRef.delete();
        await recipeRef.update({
          'likeCount': FieldValue.increment(-1),
        });
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likeCount--;
          });
        }
      } else {
        await likeRef.set({
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await recipeRef.update({
          'likeCount': FieldValue.increment(1),
        });
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likeCount++;
          });
        }
      }
    } catch (e) {
      if (mounted && kDebugMode) {
        print('Error toggling like: $e');
      }
    }
  }

  Future<void> _shareRecipe() async {
    final recipe = widget.documentSnapshot;
    String rating = '0';
    try {
      rating = (recipe['ratingAverage'] ?? (double.tryParse('${recipe['rating'] ?? '0'}') ?? 0)).toString();
    } catch (e) {
      // Fallback to old rating field
      rating = (double.tryParse('${recipe['rating'] ?? '0'}') ?? 0).toString();
    }
    final shareText = 'Check out this recipe: ${recipe['name']}\n'
        'Calories: ${recipe['cal']}\n'
        'Time: ${recipe['time']} minutes\n'
        'Rating: $rating/5';
    
    await Share.share(shareText);
  }

  Future<void> _reportComment(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .add({
        'type': 'comment',
        'commentId': commentId,
        'recipeId': widget.documentSnapshot.id,
        'reportedBy': user.uid,
        'reason': 'Inappropriate content',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Báo cáo đã được gửi')),
        );
      }
    } catch (e) {
      if (mounted && kDebugMode) {
        print('Error reporting comment: $e');
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review')),
      );
      return;
    }

    if (_selectedRating == 0 || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating and comment')),
      );
      return;
    }

    try {
      final reviewData = {
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Anonymous',
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };


      // Lưu bình luận vào sub-collection 'reviews' của món ăn
      await FirebaseFirestore.instance
          .collection('RecipeApp')
          .doc(widget.documentSnapshot.id)
          .collection('reviews')
          .add(reviewData);

      // Cập nhật rating trung bình và số lượng reviews (numeric fields)
      await _updateRecipeRating();

      if (mounted) {
        _commentController.clear();
        setState(() {
          _selectedRating = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    }
  }


  Future<void> _updateRecipeRating() async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('RecipeApp')
        .doc(widget.documentSnapshot.id)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc['rating'] as num).toDouble();
    }
    final averageRating = totalRating / reviewsSnapshot.docs.length;

    await FirebaseFirestore.instance
        .collection('RecipeApp')
        .doc(widget.documentSnapshot.id)
        .update({
      'ratingAverage': averageRating,
      'reviewsCount': reviewsSnapshot.docs.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = FavoriteProvider.of(context);
    final quantityProvider = Provider.of<QuantityProvider>(context);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: startCookingAndFavoriteButton(provider),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: widget.documentSnapshot['image'],
                  child: Container(
                    height: MediaQuery.of(context).size.height / 2.1,
                    child: _buildMediaContent(),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      MyIconButton(
                        icon: Iconsax.arrow_left,
                        pressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      MyIconButton(
                        icon: Iconsax.notification,
                        pressed: () {},
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.width,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.documentSnapshot['name'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Iconsax.flash_1,
                        size: 20,
                        color: Colors.grey,
                      ),
                      Text(
                        "${widget.documentSnapshot['cal']} Cal",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                      Icon(
                        Iconsax.clock,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${widget.documentSnapshot['time']} Min",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.star1,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        (() {
                          try {
                            return (widget.documentSnapshot['ratingAverage'] ?? (double.tryParse('${widget.documentSnapshot['rating'] ?? '0'}') ?? 0)).toString();
                          } catch (e) {
                            return (double.tryParse('${widget.documentSnapshot['rating'] ?? '0'}') ?? 0).toString();
                          }
                        })(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      Text(
                        "/5",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        (() {
                          try {
                            return "${(widget.documentSnapshot['reviewsCount'] ?? widget.documentSnapshot['reviews'] ?? 0).toString()} Reviews";
                          } catch (e) {
                            return "${(widget.documentSnapshot['reviews'] ?? 0).toString()} Reviews";
                          }
                        })(),
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isLiked ? Iconsax.heart5 : Iconsax.heart,
                              color: _isLiked ? Colors.red : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _likeCount.toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ingredients",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "How many servings?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      QuantityIncrementDecrement(
                        currentNumber: quantityProvider.currentNumber,
                        onAdd: () => quantityProvider.increaseQuantity(),
                        onRemov: () => quantityProvider.decreaseQuantity(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: (() {
                              final List<Widget> items = [];
                              try {
                                final List<dynamic> ingr = (widget.documentSnapshot['ingredients'] as List<dynamic>?) ?? [];
                                if (ingr.isNotEmpty) {
                                  for (final it in ingr) {
                                    final m = it as Map<String, dynamic>;
                                    final imageUrl = (m['imageUrl'] ?? '').toString();
                                    items.add(
                                      Container(
                                        height: 60,
                                        width: 60,
                                        margin: const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: imageUrl.isEmpty ? Colors.grey[300] : null,
                                          image: imageUrl.isNotEmpty
                                              ? DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: NetworkImage(imageUrl),
                                                )
                                              : null,
                                        ),
                                        child: imageUrl.isEmpty
                                            ? const Icon(Iconsax.image, color: Colors.grey, size: 24)
                                            : null,
                                      ),
                                    );
                                  }
                                  return items;
                                }
                              } catch (e) {
                                // Field 'ingredients' chưa tồn tại, dùng schema cũ
                              }
                              // Fallback schema cũ
                              final images = (widget.documentSnapshot['ingredientsImage'] as List<dynamic>?) ?? [];
                              if (images.isNotEmpty) {
                                return images.map<Widget>((imageUrl) => Container(
                                  height: 60,
                                  width: 60,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(imageUrl),
                                    ),
                                  ),
                                )).toList();
                              }
                              final count = (widget.documentSnapshot['ingredientsName'] as List?)?.length ?? 0;
                              return List.generate(count, (index) => Container(
                                    height: 60,
                                    width: 60,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.grey[300],
                                    ),
                                    child: const Icon(
                                      Iconsax.image,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ));
                            })(),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (() {
                              try {
                                final ingr = (widget.documentSnapshot['ingredients'] as List<dynamic>?) ?? [];
                                if (ingr.isNotEmpty) {
                                  return ingr.map<Widget>((it) {
                                    final m = it as Map<String, dynamic>;
                                    return SizedBox(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          (m['name'] ?? '').toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context).colorScheme.onBackground,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList();
                                }
                              } catch (e) {
                                // Field 'ingredients' chưa tồn tại, dùng schema cũ
                              }
                              final names = (widget.documentSnapshot['ingredientsName'] as List<dynamic>?) ?? [];
                              return names.map<Widget>((ingredient) => SizedBox(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    ingredient,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                              )).toList();
                            })(),
                          ),
                          const Spacer(),
                          Column(
                            children: (() {
                              try {
                                final ingr = (widget.documentSnapshot['ingredients'] as List<dynamic>?) ?? [];
                                if (ingr.isNotEmpty) {
                                  final scaled = quantityProvider.updateIngredientAmounts;
                                  return List.generate(ingr.length, (i) {
                                    final m = ingr[i] as Map<String, dynamic>;
                                    final unit = (m['unit'] ?? 'g').toString();
                                    final amount = scaled.length > i ? scaled[i] : 0.0;
                                    return SizedBox(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          "${amount}${unit}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context).colorScheme.onBackground,
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                }
                              } catch (e) {
                                // Field 'ingredients' chưa tồn tại, dùng schema cũ
                              }
                              return quantityProvider.updateIngredientAmounts
                                  .map<Widget>((amount) => SizedBox(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            "${amount}gam",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context).colorScheme.onBackground,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList();
                            })(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Phần đánh giá và bình luận
                  Text(
                    "Reviews",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Đánh giá sao
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _selectedRating ? Iconsax.star1 : Iconsax.star,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  // Nhập bình luận
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Write your review...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kprimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Submit Review"),
                  ),
                  const SizedBox(height: 20),
                  // Danh sách bình luận
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('RecipeApp')
                        .doc(widget.documentSnapshot.id)
                        .collection('reviews')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text("Error loading reviews"));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No reviews yet"));
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      data['userName'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onBackground,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < data['rating'] ? Iconsax.star1 : Iconsax.star,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  data['comment'],
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Text(
                                      data['timestamp'] != null
                                          ? DateFormat('dd/MM/yyyy HH:mm').format((data['timestamp'] as Timestamp).toDate())
                                          : 'Just now',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'report',
                                          child: Text('Báo cáo'),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'report') {
                                          _reportComment(doc.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  FloatingActionButton startCookingAndFavoriteButton(FavoriteProvider provider) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.transparent,
      elevation: 0,
      onPressed: () {},
      label: Row(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kprimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 10),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CookingGuideScreen(
                    documentSnapshot: widget.documentSnapshot,
                  ),
                ),
              );
            },
            child: const Text(
              "Start Cooking",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            onPressed: () {
              provider.toggleFavorite(widget.documentSnapshot);
            },
            icon: Icon(
              provider.isExist(widget.documentSnapshot)
                  ? Iconsax.heart5
                  : Iconsax.heart,
              color: provider.isExist(widget.documentSnapshot)
                  ? Colors.red
                  : Theme.of(context).colorScheme.onBackground,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            onPressed: _shareRecipe,
            icon: Icon(
              Iconsax.share,
              color: Theme.of(context).colorScheme.onBackground,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    final data = widget.documentSnapshot.data() as Map<String, dynamic>?;
    final videoUrl = data?['videoUrl'] as String?;
    final imageUrl = data?['image'] as String?;

    // Nếu có video, hiển thị video player
    if (videoUrl != null && videoUrl.isNotEmpty) {
      return VideoPlayerWidget(
        videoUrl: videoUrl,
        autoPlay: false,
        showControls: true,
        aspectRatio: 16 / 9,
      );
    }
    
    // Nếu không có video, hiển thị hình ảnh
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: NetworkImage(imageUrl),
          ),
        ),
      );
    }

    // Nếu không có cả video và hình ảnh, hiển thị placeholder
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.image,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Không có hình ảnh',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}