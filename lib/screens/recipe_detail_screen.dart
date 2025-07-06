import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../models/nutrition.dart';
import '../models/meal_plan_model.dart';
import '../services/firebase_meal_service.dart';
import '../constants.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final DateTime? selectedDate;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.selectedDate,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final FirebaseMealService _mealService = FirebaseMealService();
  String _selectedMealCategory = 'Lunch';
  bool _isAdding = false;

  Future<void> _addToMealPlan({
    required String userId,
    required String foodName,
    required Nutrition nutrition,
    required String mealCategory,
    required DateTime date,
  }) async {
    try {
      final meal = MealPlan(
        id: '',
        userId: userId,
        foodName: foodName,
        nutrition: nutrition,
        mealCategory: mealCategory,
        date: date,
        createdAt: DateTime.now(),
      );

      await _mealService.addMeal(meal);
    } catch (e) {
      throw Exception('Failed to add to meal plan: $e');
    }
  }

  Future<void> _handleAddToMealPlan() async {
    setState(() {
      _isAdding = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final targetDate = widget.selectedDate ?? DateTime.now();

      await _addToMealPlan(
        userId: user.uid,
        foodName: widget.recipe.title,
        nutrition: widget.recipe.nutrition,
        mealCategory: _selectedMealCategory,
        date: targetDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${widget.recipe.title} to $_selectedMealCategory '
                  'for ${targetDate.day}/${targetDate.month}/${targetDate.year}',
            ),
            backgroundColor: kSuccessColor,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to meal plan: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Future<String?> _showMealCategoryDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Select Meal Category',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
              .map((category) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context, category),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: kPrimaryColor.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: kPrimaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ADD THIS HELPER METHOD
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

  Widget _buildRecipeImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: widget.recipe.image.isNotEmpty
          ? ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: Image.network(
          widget.recipe.image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.restaurant,
                color: Colors.grey,
                size: 80,
              ),
            );
          },
        ),
      )
          : const Icon(
        Icons.restaurant,
        color: Colors.grey,
        size: 80,
      ),
    );
  }

  Widget _buildRecipeInfo() {
    return Padding(
      padding: const EdgeInsets.all(kSpacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.recipe.title,
            style: kHeadingStyle,
          ),
          const SizedBox(height: kSpacingSM),

          // Recipe meta info
          Row(
            children: [
              _buildInfoChip(
                Icons.access_time,
                widget.recipe.formattedTime,
                Colors.blue,
              ),
              const SizedBox(width: kSpacingSM),
              _buildInfoChip(
                Icons.restaurant_menu,
                '${widget.recipe.servings} servings',
                Colors.green,
              ),
              const SizedBox(width: kSpacingSM),
              _buildInfoChip(
                Icons.local_fire_department,
                '${widget.recipe.calories} cal',
                Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: kSpacingMD),

          // Diet labels
          if (widget.recipe.dietLabels.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.recipe.dietLabels.map((label) {
                return Chip(
                  label: Text(
                    label,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: kPrimaryColor),
                );
              }).toList(),
            ),
            const SizedBox(height: kSpacingMD),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInfo() {
    return Card(
      margin: const EdgeInsets.all(kSpacingMD),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition Information',
              style: kSubheadingStyle,
            ),
            const SizedBox(height: kSpacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Calories',
                    '${widget.recipe.calories}',
                    'kcal',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: kSpacingSM),
                Expanded(
                  child: _buildNutritionCard(
                    'Protein',
                    widget.recipe.protein.toStringAsFixed(1),
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
                    widget.recipe.carbs.toStringAsFixed(1),
                    'g',
                    Icons.grain,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: kSpacingSM),
                Expanded(
                  child: _buildNutritionCard(
                    'Fat',
                    widget.recipe.fat.toStringAsFixed(1),
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
              fontSize: 16,
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

  Widget _buildIngredients() {
    if (widget.recipe.ingredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(kSpacingMD),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingredients',
              style: kSubheadingStyle,
            ),
            const SizedBox(height: kSpacingMD),
            ...widget.recipe.ingredients.map((ingredient) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: const BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: kBodyStyle,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    if (widget.recipe.instructions.isEmpty) {
      return const SizedBox.shrink();
    }

    final instructions = widget.recipe.instructions
        .split('\n')
        .where((instruction) => instruction.trim().isNotEmpty)
        .toList();

    return Card(
      margin: const EdgeInsets.all(kSpacingMD),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instructions',
              style: kSubheadingStyle,
            ),
            const SizedBox(height: kSpacingMD),
            ...instructions.asMap().entries.map((entry) {
              final index = entry.key;
              final instruction = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        instruction.trim(),
                        style: kBodyStyle,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToMealPlanSection() {
    return Container(
      padding: const EdgeInsets.all(kSpacingMD),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Date indicator
          if (widget.selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, color: kPrimaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Adding to: ${widget.selectedDate!.day}/${widget.selectedDate!.month}/${widget.selectedDate!.year}',
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Meal category selector
          Row(
            children: [
              const Text(
                'Add to:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedMealCategory,
                  isExpanded: true,
                  items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMealCategory = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: kSpacingMD),

          // Add button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isAdding ? null : _handleAddToMealPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAdding
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Add to Meal Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePickerAndAddToMeal() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      // Now show meal category selection
      final selectedCategory = await _showMealCategoryDialog();
      if (selectedCategory != null) {
        // Add to meal plan with selected date and category
        await _addToMealPlanWithDate(selectedDate, selectedCategory);
      }
    }
  }

  Future<void> _addToMealPlanWithDate(DateTime date, String category) async {
    setState(() {
      _isAdding = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _addToMealPlan(
        userId: user.uid,
        foodName: widget.recipe.title,
        nutrition: widget.recipe.nutrition,
        mealCategory: category,
        date: date,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${widget.recipe.title} to $category for ${date.day}/${date.month}/${date.year}',
            ),
            backgroundColor: kSuccessColor,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to meal plan: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildRecipeImage(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildRecipeInfo(),
                _buildNutritionInfo(),
                _buildIngredients(),
                _buildInstructions(),
                const SizedBox(height: 80), // Space for bottom section
              ],
            ),
          ),
        ],
      ),
      // Only show bottom navigation bar if selectedDate is provided
      bottomNavigationBar: widget.selectedDate != null
          ? _buildAddToMealPlanSection()
          : null,
      // Add floating action button for view-only mode
      floatingActionButton: widget.selectedDate == null
          ? FloatingActionButton.extended(
        onPressed: () {
          // Show date picker and then add to meal plan
          _showDatePickerAndAddToMeal();
        },
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add to Meal Plan'),
      )
          : null,
    );
  }
}