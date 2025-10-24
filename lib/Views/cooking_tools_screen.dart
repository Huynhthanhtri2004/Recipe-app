import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Widget/cooking_timer.dart';
import 'package:recipe_app/Widget/nutrition_card.dart';

class CookingToolsScreen extends StatefulWidget {
  const CookingToolsScreen({super.key});

  @override
  State<CookingToolsScreen> createState() => _CookingToolsScreenState();
}

class _CookingToolsScreenState extends State<CookingToolsScreen> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooking Tools'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cooking Timer Section
            const Text(
              'Cooking Timers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CookingTimer(
              initialMinutes: 15,
              title: 'Boil Water',
            ),
            const SizedBox(height: 16),
            const CookingTimer(
              initialMinutes: 30,
              title: 'Bake Chicken',
            ),
            const SizedBox(height: 16),
            const CookingTimer(
              initialMinutes: 45,
              title: 'Roast Vegetables',
            ),
            
            const SizedBox(height: 32),
            
            // Nutrition Calculator Section
            const Text(
              'Nutrition Calculator',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Input Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.calculator, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      const Text(
                        'Calculate Nutrition',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _caloriesController,
                          decoration: const InputDecoration(
                            labelText: 'Calories',
                            hintText: '250',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _proteinController,
                          decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            hintText: '20',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _carbsController,
                          decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            hintText: '30',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _fatController,
                          decoration: const InputDecoration(
                            labelText: 'Fat (g)',
                            hintText: '10',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: const Icon(Iconsax.calculator),
                      label: const Text('Calculate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Nutrition Display
            if (_caloriesController.text.isNotEmpty ||
                _proteinController.text.isNotEmpty ||
                _carbsController.text.isNotEmpty ||
                _fatController.text.isNotEmpty)
              NutritionCard(
                calories: _caloriesController.text.isEmpty ? '0' : '${_caloriesController.text} kcal',
                protein: _proteinController.text.isEmpty ? '0g' : '${_proteinController.text}g',
                carbs: _carbsController.text.isEmpty ? '0g' : '${_carbsController.text}g',
                fat: _fatController.text.isEmpty ? '0g' : '${_fatController.text}g',
              ),
            
            const SizedBox(height: 32),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Iconsax.scale,
                    title: 'Convert Units',
                    subtitle: 'Weight & Volume',
                    onTap: () {
                      _showUnitConverter();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Iconsax.timer_1,
                    title: 'Custom Timer',
                    subtitle: 'Set your time',
                    onTap: () {
                      _showCustomTimer();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitConverter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unit Converter'),
        content: const Text('Unit converter feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCustomTimer() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Timer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            hintText: 'Enter minutes',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text) ?? 0;
              if (minutes > 0) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Custom Timer')),
                      body: Center(
                        child: CookingTimer(
                          initialMinutes: minutes,
                          title: 'Custom Timer',
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
