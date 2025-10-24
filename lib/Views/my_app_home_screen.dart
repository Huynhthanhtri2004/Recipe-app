import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Views/food_items_display.dart';
import 'package:recipe_app/Views/view_all_items.dart';
import 'package:recipe_app/Views/notifications_screen.dart';
import 'package:recipe_app/Views/shopping_list_screen.dart';
import 'package:recipe_app/Widget/banner.dart';
import 'package:recipe_app/Widget/my_icon_button.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/Provider/theme_provider.dart';

class MyAppHomeScreen extends StatefulWidget {
  const MyAppHomeScreen({super.key});

  @override
  State<MyAppHomeScreen> createState() => _MyAppHomeScreenState();
}

  final TextEditingController _searchController = TextEditingController();

  final CollectionReference categoriesItems = FirebaseFirestore.instance.collection('App-Category');

  Query get filteredRecipes =>
  Query get selectedRecipes {
    Query query = category == "All" ? allRecipes : filteredRecipes;
    
    if (searchQuery.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }
    
    if (selectedDifficulty != "All") {
      query = query.where('difficulty', isEqualTo: selectedDifficulty);
    }
    
    if (selectedMealType != "All") {
      query = query.where('mealType', isEqualTo: selectedMealType);
    }
    
    if (selectedCuisine != "All") {
      query = query.where('cuisine', isEqualTo: selectedCuisine);
    }
    
    if (maxTime != null) {
      query = query.where('time', isLessThanOrEqualTo: maxTime!);
    }
    
    return query;
  }

  void handleSearchChange() {
    if (mounted) {
      setState(() {
        searchQuery = _searchController.text.trim();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(handleSearchChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(handleSearchChange);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerParts(),
                    mySearchBar(),
                    const BannerToExplore(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("Categories",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    selectedCategory(),
                    const SizedBox(height: 16),
                    _buildFilterSection(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Quick & Easy",
                          style: TextStyle(
                            fontSize: 20,
                            letterSpacing: 0.1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ViewAllItems()),
                            );
                          },
                          child: const Text("View all",
                            style: TextStyle(
                              color: kBannerColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StreamBuilder(
                stream: selectedRecipes.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading recipes"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData) {
                    final recipes = snapshot.data?.docs ?? [];
                    if (recipes.isEmpty) {
                      return const Center(
                        child: Text("No recipes found",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 5, left: 15),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: recipes.map((e) =>
                              FoodItemsDisplay(documentSnapshot: e)).toList(),
                        ),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  StreamBuilder<QuerySnapshot<Object?>> selectedCategory() {
    return StreamBuilder(
      stream: categoriesItems.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
        if (streamSnapshot.hasData) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                streamSnapshot.data!.docs.length,
                    (index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      category = streamSnapshot.data!.docs[index]['name'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: category == streamSnapshot.data!.docs[index]['name']
                          ? kprimaryColor
                          : Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    margin: const EdgeInsets.only(right: 20),
                    child: Text(
                      streamSnapshot.data!.docs[index]['name'],
                      style: TextStyle(
                        color: category == streamSnapshot.data!.docs[index]['name']
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  // search
  Padding mySearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          prefixIcon: const Icon(Iconsax.search_normal),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Iconsax.close_circle),
            onPressed: () {
              _searchController.clear();
              setState(() {
                searchQuery = "";
              });
            },
          )
              : null,
          fillColor: Colors.white,
          border: InputBorder.none,
          hintText: "Search any recipes",
          hintStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          setState(() {
            searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Filters",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip("Difficulty", selectedDifficulty, ["All", "easy", "medium", "hard"], (value) {
              setState(() => selectedDifficulty = value);
            }),
            _buildFilterChip("Meal Type", selectedMealType, ["All", "sáng", "trưa", "tối"], (value) {
              setState(() => selectedMealType = value);
            }),
            _buildFilterChip("Cuisine", selectedCuisine, ["All", "Việt Nam", "Trung Quốc", "Nhật Bản", "Hàn Quốc", "Thái Lan", "Ý", "Pháp"], (value) {
              setState(() => selectedCuisine = value);
            }),
            _buildTimeFilter(),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected == "All" ? Colors.grey[200] : kprimaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option, style: TextStyle(
              color: selected == "All" ? Colors.black : Colors.white,
              fontSize: 12,
            )),
          )).toList(),
          onChanged: (value) => onChanged(value ?? "All"),
        ),
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: maxTime == null ? Colors.grey[200] : kprimaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            maxTime == null ? "Any time" : "≤${maxTime}m",
            style: TextStyle(
              color: maxTime == null ? Colors.black : Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: maxTime,
              items: [
                const DropdownMenuItem(value: null, child: Text("Any")),
                const DropdownMenuItem(value: 15, child: Text("≤15m")),
                const DropdownMenuItem(value: 30, child: Text("≤30m")),
                const DropdownMenuItem(value: 60, child: Text("≤1h")),
                const DropdownMenuItem(value: 120, child: Text("≤2h")),
              ],
              onChanged: (value) => setState(() => maxTime = value),
            ),
          ),
        ],
      ),
    );
  }

  Row headerParts() {
    return Row(
      children: [
        const Text(
          "What are you\ncooking today?",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        const Spacer(),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MyIconButton(
              icon: themeProvider.isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
              pressed: () {
                themeProvider.toggleTheme();
              },
            );
          },
        ),
        const SizedBox(width: 8),
        MyIconButton(
          icon: Iconsax.shopping_cart,
          pressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ShoppingListScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        MyIconButton(
          icon: Iconsax.notification,
          pressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
