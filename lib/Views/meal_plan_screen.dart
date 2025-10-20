import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:recipe_app/Views/recipe_selection_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/Provider/favorite_provider.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final Map<String, List<DocumentSnapshot>> _mealPlan = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
  };

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.week;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    // Sử dụng addPostFrameCallback để đảm bảo widget đã mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMealPlan();
      }
    });
  }
  Future<void> _loadMealPlan() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final docRef = FirebaseFirestore.instance.collection('mealPlans').doc(dateStr);

    try {
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        await _loadRecipesForMeal('Breakfast', data['Breakfast'] ?? []);
        await _loadRecipesForMeal('Lunch', data['Lunch'] ?? []);
        await _loadRecipesForMeal('Dinner', data['Dinner'] ?? []);
      } else {
        // Nếu chưa có dữ liệu, khởi tạo danh sách rỗng
        if (mounted) {
          setState(() {
            _mealPlan['Breakfast'] = [];
            _mealPlan['Lunch'] = [];
            _mealPlan['Dinner'] = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải kế hoạch bữa ăn: $e')),
        );
      }
    }
  }

  Future<void> _loadRecipesForMeal(String mealType, List<dynamic> recipeIds) async {
    if (recipeIds.isEmpty) {
      setState(() {
        _mealPlan[mealType] = [];
      });
      return;
    }

    final recipes = await FirebaseFirestore.instance
        .collection('RecipeApp')
        .where(FieldPath.documentId, whereIn: recipeIds)
        .get();

    if (mounted) {
      setState(() {
        _mealPlan[mealType] = recipes.docs;
      });
    }
  }

  // add recipe
  void _addRecipeToMeal(String mealType) async {
    // Mở màn hình chọn công thức và chờ kết quả trả về
    final selectedRecipe = await Navigator.push<DocumentSnapshot>(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeSelectionScreen(
          onRecipeSelected: (recipe) => recipe,
        ),
      ),
    );

    if (selectedRecipe != null) {
      setState(() {
        _mealPlan[mealType]!.add(selectedRecipe);
      });
      await _saveMealPlanToFirestore();
    }
  }

  Future<void> _saveMealPlanToFirestore() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final docRef = FirebaseFirestore.instance.collection('mealPlans').doc(dateStr);

    final data = {
      'Breakfast': _mealPlan['Breakfast']!.map((doc) => doc.id).toList(),
      'Lunch': _mealPlan['Lunch']!.map((doc) => doc.id).toList(),
      'Dinner': _mealPlan['Dinner']!.map((doc) => doc.id).toList(),
      'date': dateStr,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await docRef.set(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu kế hoạch bữa ăn: $e')),
        );
      }
    }
  }

    // remove recipe
  void _removeRecipeFromMeal(String mealType, int index) async {
    // Lưu trữ giá trị tạm thời
    final removedItem = _mealPlan[mealType]!.removeAt(index);

    // Chỉ cập nhật UI nếu widget còn mounted
    if (mounted) {
      setState(() {});
    }

    try {
      await _saveMealPlanToFirestore();
    } catch (e) {
      // Khôi phục lại nếu có lỗi và widget vẫn mounted
      if (mounted) {
        setState(() {
          _mealPlan[mealType]!.insert(index, removedItem);
        });
      }
      print('Error saving meal plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meal Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar View
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadMealPlan();
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: kprimaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: kprimaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 20),
            // Meal Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildMealSection(context, 'Breakfast'),
                  _buildMealSection(context, 'Lunch'),
                  _buildMealSection(context, 'Dinner'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(BuildContext context, String mealType) {
    final recipes = _mealPlan[mealType] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  mealType,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                Text(
                  "${recipes.length} recipes",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Recipe List
          if (recipes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: Text(
                  "No recipes added",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ...recipes.map((recipe) => _buildRecipeItem(context, recipe, mealType)).toList(),
          // Add Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _addRecipeToMeal(mealType),
              icon: const Icon(Iconsax.add),
              label: const Text('Add Recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kprimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeItem(BuildContext context, DocumentSnapshot recipe, String mealType) {
    final index = _mealPlan[mealType]!.indexOf(recipe);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 60,
        height: 60,
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
      subtitle: Row(
        children: [
          Row(
            children: [
              const Icon(Iconsax.flash_1, size: 16, color: Colors.grey),
              Text(' ${recipe['cal']} Cal', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              const Icon(Iconsax.clock, size: 16, color: Colors.grey),
              Text(' ${recipe['time']} Min', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Iconsax.close_circle, color: Colors.red),
        onPressed: () => _removeRecipeFromMeal(mealType, index),
      ),
    );
  }
}