import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Views/favorite_screen.dart';
import 'package:recipe_app/Views/my_app_home_screen.dart';
import 'package:recipe_app/Views/profile_screen.dart';
import 'package:recipe_app/Views/collections_screen.dart';
import 'meal_plan_screen.dart';

class AppMainScreen extends StatefulWidget {
  const AppMainScreen({super.key});

  @override
  State<AppMainScreen> createState() => _AppMainScreenState();
}

class _AppMainScreenState extends State<AppMainScreen> {
  int selectedIndex = 0;
  late final List<Widget> page;

  @override
  void initState() {
    super.initState();
    page = [
      const MyAppHomeScreen(),
      const FavoriteScreen(),
      const CollectionsScreen(),
      const MealPlanScreen(),
      const ProfileScreen(),
    ];
  }

  // IndexedStack đã giữ trạng thái, không cần override didChangeDependencies

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        elevation: 0,
        iconSize: 24,
        currentIndex: selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              selectedIndex == 0 ? Iconsax.home_15 : Iconsax.home_1,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              selectedIndex == 1 ? Iconsax.heart5 : Iconsax.heart,
            ),
            label: "Favorite",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              selectedIndex == 2 ? Iconsax.folder_25 : Iconsax.folder_2,
            ),
            label: "Collections",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              selectedIndex == 3 ? Iconsax.calendar_25 : Iconsax.calendar_2,
            ),
            label: "Meal Plan",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              selectedIndex == 4 ? Iconsax.profile_circle5 : Iconsax.profile_circle,
            ),
            label: "Profile",
          ),
        ],
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: page,
      ),
    );
  }

  Widget navBarPage(IconData iconName) {
    return Center(
      child: Icon(
        iconName,
        size: 100,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}