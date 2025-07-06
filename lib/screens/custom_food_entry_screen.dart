import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/firebase_meal_service.dart';
import '../models/nutrition.dart';
import '../models/meal_plan_model.dart';

class CustomFoodEntryScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const CustomFoodEntryScreen({
    super.key,
    this.selectedDate,
  });

  @override
  State<CustomFoodEntryScreen> createState() => _CustomFoodEntryScreenState();
}

class _CustomFoodEntryScreenState extends State<CustomFoodEntryScreen> {
  final FirebaseMealService _mealService = FirebaseMealService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _fiberController = TextEditingController();
  final TextEditingController _sodiumController = TextEditingController();

  String _selectedMealCategory = 'Lunch';
  bool _isLoading = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final nutrition = Nutrition(
        calories: double.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        fiber: double.tryParse(_fiberController.text) ?? 0,
        sodium: double.tryParse(_sodiumController.text) ?? 0,
      );

      final targetDate = widget.selectedDate ?? DateTime.now();

      final meal = MealPlan(
        id: '', // Will be set by Firestore
        userId: user.uid,
        foodName: _foodNameController.text.trim(),
        nutrition: nutrition,
        mealCategory: _selectedMealCategory,
        date: targetDate,
        createdAt: DateTime.now(),
      );

      await _mealService.addMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_foodNameController.text} to $_selectedMealCategory '
              'for ${targetDate.day}/${targetDate.month}/${targetDate.year}',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving meal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffix,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        if (keyboardType == TextInputType.number &&
            value != null &&
            value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildMealCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meal Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((category) {
              final isSelected = _selectedMealCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMealCategory = category;
                    });
                  }
                },
                selectedColor: kPrimaryColor.withOpacity(0.2),
                backgroundColor: Colors.grey[100],
                labelStyle: TextStyle(
                  color: isSelected ? kPrimaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Food Manually'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected date indicator
              if (widget.selectedDate != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_today, color: kPrimaryColor),
                      const SizedBox(height: 8),
                      const Text(
                        'Adding food for:',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${widget.selectedDate!.day}/${widget.selectedDate!.month}/${widget.selectedDate!.year}',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Food name
              _buildTextField(
                controller: _foodNameController,
                label: 'Food Name',
                hint: 'e.g., Grilled Chicken Breast',
              ),

              const SizedBox(height: 20),

              // Meal category
              _buildMealCategorySelector(),

              const SizedBox(height: 24),

              const Text(
                'Nutrition Information',
                style: kSubheadingStyle,
              ),

              const SizedBox(height: 16),

              // Calories
              _buildTextField(
                controller: _caloriesController,
                label: 'Calories',
                hint: 'e.g., 250',
                suffix: 'kcal',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Macronutrients row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _proteinController,
                      label: 'Protein',
                      hint: 'e.g., 25',
                      suffix: 'g',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _carbsController,
                      label: 'Carbs',
                      hint: 'e.g., 30',
                      suffix: 'g',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _fatController,
                      label: 'Fat',
                      hint: 'e.g., 10',
                      suffix: 'g',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _fiberController,
                      label: 'Fiber',
                      hint: 'e.g., 5',
                      suffix: 'g',
                      keyboardType: TextInputType.number,
                      isRequired: false,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sodium
              _buildTextField(
                controller: _sodiumController,
                label: 'Sodium',
                hint: 'e.g., 200',
                suffix: 'mg',
                keyboardType: TextInputType.number,
                isRequired: false,
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
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

              const SizedBox(height: 16),

              // Quick add suggestions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Add Common Foods',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickAddChip(
                              'Apple (1 medium)', 95, 0.5, 25, 0.3),
                          _buildQuickAddChip(
                              'Banana (1 medium)', 105, 1.3, 27, 0.4),
                          _buildQuickAddChip(
                              'Chicken Breast (100g)', 165, 31, 0, 3.6),
                          _buildQuickAddChip(
                              'Brown Rice (1 cup)', 216, 5, 45, 1.8),
                          _buildQuickAddChip('Egg (1 large)', 70, 6, 0.6, 5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddChip(
      String name, int calories, double protein, double carbs, double fat) {
    return ActionChip(
      label: Text(name),
      onPressed: () {
        final foodName = name.split(' (')[0];
        _foodNameController.text = foodName;
        _caloriesController.text = calories.toString();
        _proteinController.text = protein.toString();
        _carbsController.text = carbs.toString();
        _fatController.text = fat.toString();
        _fiberController.text = '2.0';
        _sodiumController.text = '5';
      },
      backgroundColor: kPrimaryColor.withOpacity(0.1),
      labelStyle: const TextStyle(color: kPrimaryColor),
    );
  }
}
