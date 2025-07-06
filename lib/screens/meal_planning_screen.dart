import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_meal_service.dart';
import '../models/meal_plan_model.dart';
import '../widgets/weekly_calendar.dart';
import 'custom_food_entry_screen.dart';
import 'recipe_screen.dart';
import 'camera_screen.dart';

// Local constants
const Color kPrimaryColor = Color(0xFF4CAF50);
const Color kAccentColor = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF333333);
const Color kLightTextColor = Color(0xFF666666);

const TextStyle kHeadingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

const TextStyle kSubheadingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: kTextColor,
);

const TextStyle kBodyStyle = TextStyle(
  fontSize: 16,
  color: kTextColor,
);

const TextStyle kCaptionStyle = TextStyle(
  fontSize: 14,
  color: kLightTextColor,
);

const double kSpacingSM = 8.0;
const double kSpacingMD = 16.0;
const double kSpacingLG = 24.0;
const double kBorderRadius = 12.0;

class MealPlanningScreen extends StatefulWidget {
  const MealPlanningScreen({super.key});

  @override
  State<MealPlanningScreen> createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends State<MealPlanningScreen>
    with AutomaticKeepAliveClientMixin {
  final FirebaseMealService _mealService = FirebaseMealService();
  DateTime _selectedDate = DateTime.now();
  List<MealPlan> _meals = [];
  Map<DateTime, int> _mealCounts = {};
  bool _isLoading = true;
  String? _userId;

  @override
  bool get wantKeepAlive => true; // Keep state alive for auto-reload

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      _loadMeals();
      _loadMealCounts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto reload when returning from other screens
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (_userId != null) {
      await _loadMeals();
      await _loadMealCounts();
    }
  }

  Future<void> _loadMeals() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final meals = await _mealService.getMealsForDate(_userId!, _selectedDate);
      if (mounted) {
        setState(() {
          _meals = meals;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading meals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMealCounts() async {
    if (_userId == null) return;

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final counts = <DateTime, int>{};

      for (int i = 0; i < 14; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        final meals = await _mealService.getMealsForDate(_userId!, date);
        counts[dateKey] = meals.length;
      }

      if (mounted) {
        setState(() {
          _mealCounts = counts;
        });
      }
    } catch (e) {
      print('Error loading meal counts: $e');
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadMeals();
  }

  Future<void> _deleteMeal(MealPlan meal) async {
    try {
      await _mealService.deleteMeal(meal.id);
      await _refreshData(); // Use refresh instead of separate calls
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal deleted successfully'),
            backgroundColor: kPrimaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddMealOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(kSpacingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: kSpacingMD),
            const Text(
              'Add Meal',
              style: kSubheadingStyle,
            ),
            const SizedBox(height: kSpacingMD),
            _buildAddOption(
              icon: Icons.camera_alt,
              title: 'Scan Food',
              subtitle: 'Use camera to scan food items',
              color: kPrimaryColor,
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      selectedDate: _selectedDate,
                    ),
                  ),
                );
                // Auto reload after returning
                if (result != null || result == true) {
                  await _refreshData();
                }
              },
            ),
            _buildAddOption(
              icon: Icons.restaurant_menu,
              title: 'Browse Recipes',
              subtitle: 'Choose from recipe collection',
              color: kAccentColor,
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeScreen(
                      selectedDate: _selectedDate,
                    ),
                  ),
                );
                // Auto reload after returning
                if (result != null || result == true) {
                  await _refreshData();
                }
              },
            ),
            _buildAddOption(
              icon: Icons.edit,
              title: 'Manual Entry',
              subtitle: 'Enter food details manually',
              color: Colors.blue,
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomFoodEntryScreen(
                      selectedDate: _selectedDate,
                    ),
                  ),
                );
                // Auto reload after returning
                if (result != null || result == true) {
                  await _refreshData();
                }
              },
            ),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + kSpacingMD),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingSM),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: Container(
            padding: const EdgeInsets.all(kSpacingMD),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: kSpacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: kCaptionStyle,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionSummary() {
    if (_meals.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in _meals) {
      totalCalories += meal.nutrition.calories;
      totalProtein += meal.nutrition.protein;
      totalCarbs += meal.nutrition.carbs;
      totalFat += meal.nutrition.fat;
    }

    return Card(
      margin: const EdgeInsets.all(kSpacingMD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: kPrimaryColor),
                const SizedBox(width: kSpacingSM),
                const Text('Daily Summary', style: kSubheadingStyle),
                const Spacer(),
                Text(
                  '${_meals.length} meals',
                  style: kCaptionStyle,
                ),
              ],
            ),
            const SizedBox(height: kSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Calories',
                    totalCalories.toStringAsFixed(0),
                    'kcal',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: kSpacingSM),
                Expanded(
                  child: _buildNutritionCard(
                    'Protein',
                    totalProtein.toStringAsFixed(1),
                    'g',
                    Icons.fitness_center,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpacingSM),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Carbs',
                    totalCarbs.toStringAsFixed(1),
                    'g',
                    Icons.grain,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: kSpacingSM),
                Expanded(
                  child: _buildNutritionCard(
                    'Fat',
                    totalFat.toStringAsFixed(1),
                    'g',
                    Icons.opacity,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(kSpacingSM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: kLightTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(kSpacingLG),
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    if (_meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpacingLG),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 48,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: kSpacingMD),
              Text(
                'No meals planned for this day',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: kSpacingSM),
              Text(
                'Tap the + button to add your first meal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group meals by category
    final groupedMeals = <String, List<MealPlan>>{};
    for (final meal in _meals) {
      final category = meal.mealCategory;
      groupedMeals[category] = groupedMeals[category] ?? [];
      groupedMeals[category]!.add(meal);
    }

    final categories = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryMeals = groupedMeals[category] ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: kSpacingMD,
            vertical: kSpacingSM,
          ),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(kSpacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: kPrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: kSpacingSM),
                    Text(category, style: kSubheadingStyle),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryMeals.isNotEmpty
                            ? kAccentColor.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${categoryMeals.length} items',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: categoryMeals.isNotEmpty
                              ? kAccentColor
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (categoryMeals.isNotEmpty) ...[
                  const SizedBox(height: kSpacingMD),
                  ...categoryMeals.map((meal) => _buildMealItem(meal)),
                ] else ...[
                  const SizedBox(height: kSpacingSM),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(kSpacingMD),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      'No $category planned',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildMealItem(MealPlan meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingSM),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Show meal details
            _showMealDetails(meal);
          },
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: Container(
            padding: const EdgeInsets.all(kSpacingMD),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: kSpacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.foodName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meal.nutrition.calories.toStringAsFixed(0)} cal • '
                        '${meal.nutrition.protein.toStringAsFixed(1)}g protein',
                        style: kCaptionStyle,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(meal),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMealDetails(MealPlan meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meal.foodName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${meal.mealCategory}'),
            const SizedBox(height: 8),
            Text('Calories: ${meal.nutrition.calories.toStringAsFixed(0)}'),
            Text('Protein: ${meal.nutrition.protein.toStringAsFixed(1)}g'),
            Text('Carbs: ${meal.nutrition.carbs.toStringAsFixed(1)}g'),
            Text('Fat: ${meal.nutrition.fat.toStringAsFixed(1)}g'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MealPlan meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal.foodName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMeal(meal);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Meal Planning'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: kPrimaryColor,
        child: Column(
          children: [
            // Calendar Widget
            WeeklyCalendar(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
              mealCounts: _mealCounts,
            ),
            // Selected Date Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kSpacingMD),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: kPrimaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: kPrimaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Planning for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (_meals.isNotEmpty) _buildNutritionSummary(),
                    _buildMealsList(),
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMealOptions,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
    );
  }
}
