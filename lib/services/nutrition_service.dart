import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition.dart';

class NutritionService {
  static const String _baseUrl =
      'https://world.openfoodfacts.org/api/v0/product';

  // Mock nutrition database for common foods
  static final Map<String, Nutrition> _nutritionDatabase = {
    'apple': const Nutrition(
      calories: 95,
      protein: 0.5,
      carbs: 25,
      fat: 0.3,
      fiber: 4,
      sodium: 2,
    ),
    'banana': const Nutrition(
      calories: 105,
      protein: 1.3,
      carbs: 27,
      fat: 0.4,
      fiber: 3.1,
      sodium: 1,
    ),
    'chicken breast': const Nutrition(
      calories: 231,
      protein: 43.5,
      carbs: 0,
      fat: 5.0,
      fiber: 0,
      sodium: 74,
    ),
    'rice': const Nutrition(
      calories: 130,
      protein: 2.7,
      carbs: 28,
      fat: 0.3,
      fiber: 0.4,
      sodium: 1,
    ),
    'broccoli': const Nutrition(
      calories: 25,
      protein: 3,
      carbs: 5,
      fat: 0.3,
      fiber: 2.6,
      sodium: 33,
    ),
    'salmon': const Nutrition(
      calories: 206,
      protein: 22,
      carbs: 0,
      fat: 12,
      fiber: 0,
      sodium: 93,
    ),
    'bread': const Nutrition(
      calories: 79,
      protein: 2.7,
      carbs: 13,
      fat: 1.2,
      fiber: 1.2,
      sodium: 149,
    ),
    'egg': const Nutrition(
      calories: 70,
      protein: 6,
      carbs: 0.6,
      fat: 5,
      fiber: 0,
      sodium: 70,
    ),
  };

  // Get nutrition info from Open Food Facts API
  static Future<Nutrition?> getNutritionFromBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$barcode.json'),
        headers: {'User-Agent': 'MealPlanner/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};

          return Nutrition(
            calories: (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
            protein: (nutriments['proteins_100g'] ?? 0).toDouble(),
            carbs: (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
            fat: (nutriments['fat_100g'] ?? 0).toDouble(),
            fiber: (nutriments['fiber_100g'] ?? 0).toDouble(),
            sodium: (nutriments['sodium_100g'] ?? 0).toDouble(),
          );
        }
      }
    } catch (e) {
      // Logger would go here
    }

    return null;
  }

  // Get nutrition info by food name
  static Future<Nutrition> getNutritionByName(String foodName) async {
    final normalizedName = foodName.toLowerCase().trim();

    // Check our local database first
    for (final entry in _nutritionDatabase.entries) {
      if (normalizedName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Return default nutrition if not found
    return const Nutrition(
      calories: 150,
      protein: 5,
      carbs: 20,
      fat: 3,
      fiber: 2,
      sodium: 100,
    );
  }

  // Calculate nutrition for serving size
  static Nutrition calculateNutritionForServing(
    Nutrition baseNutrition,
    double servings,
  ) {
    return baseNutrition * servings;
  }

  // Get nutrition recommendations based on user profile
  static Map<String, double> getNutritionRecommendations({
    required int age,
    required String gender,
    required double weightKg,
    required double heightCm,
    required String activityLevel,
  }) {
    // Basic BMR calculation (Mifflin-St Jeor Equation)
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }

    // Activity factor
    double activityFactor;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        activityFactor = 1.2;
        break;
      case 'light':
        activityFactor = 1.375;
        break;
      case 'moderate':
        activityFactor = 1.55;
        break;
      case 'active':
        activityFactor = 1.725;
        break;
      case 'very active':
        activityFactor = 1.9;
        break;
      default:
        activityFactor = 1.4;
    }

    final calories = bmr * activityFactor;
    final protein = weightKg * 1.2; // 1.2g per kg body weight
    final fat = calories * 0.25 / 9; // 25% of calories from fat
    final carbs = (calories - (protein * 4) - (fat * 9)) / 4;

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': 25, // Recommended daily fiber
      'sodium': 2300, // Max recommended sodium (mg)
    };
  }

  // Analyze nutrition quality
  static Map<String, dynamic> analyzeNutrition(Nutrition nutrition) {
    final analysis = <String, dynamic>{};

    // Calorie density
    analysis['calorieDensity'] = _getCalorieDensityCategory(nutrition.calories);

    // Protein quality
    analysis['proteinQuality'] =
        _getProteinQuality(nutrition.protein, nutrition.calories);

    // Macro balance
    analysis['macroBalance'] = _analyzeMacroBalance(nutrition);

    // Health indicators
    analysis['healthScore'] = _calculateHealthScore(nutrition);

    return analysis;
  }

  static String _getCalorieDensityCategory(double calories) {
    if (calories < 100) return 'Low';
    if (calories < 300) return 'Medium';
    return 'High';
  }

  static String _getProteinQuality(double protein, double calories) {
    final proteinPercentage = (protein * 4) / calories * 100;
    if (proteinPercentage >= 20) return 'High Protein';
    if (proteinPercentage >= 10) return 'Good Protein';
    return 'Low Protein';
  }

  static Map<String, double> _analyzeMacroBalance(Nutrition nutrition) {
    final totalCalories = nutrition.calories;
    return {
      'proteinPercent': (nutrition.protein * 4) / totalCalories * 100,
      'carbsPercent': (nutrition.carbs * 4) / totalCalories * 100,
      'fatPercent': (nutrition.fat * 9) / totalCalories * 100,
    };
  }

  static double _calculateHealthScore(Nutrition nutrition) {
    double score = 50; // Base score

    // Bonus for fiber
    if (nutrition.fiber >= 3) {
      score += 15;
    } else if (nutrition.fiber >= 1) score += 5;

    // Penalty for high sodium
    if (nutrition.sodium > 500) {
      score -= 15;
    } else if (nutrition.sodium > 200) score -= 5;

    // Bonus for balanced macros
    final proteinPercent = (nutrition.protein * 4) / nutrition.calories * 100;
    if (proteinPercent >= 10 && proteinPercent <= 35) score += 10;

    return score.clamp(0, 100);
  }
}
