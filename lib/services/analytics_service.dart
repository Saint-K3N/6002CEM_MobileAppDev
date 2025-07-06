import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_plan_model.dart';
import '../models/nutrition.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get comprehensive nutrition analytics
  Future<Map<String, dynamic>> getComprehensiveAnalytics(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get meals from different periods
      final weeklyMeals = await _getMealsInPeriod(userId, weekAgo, now);
      final monthlyMeals = await _getMealsInPeriod(userId, monthAgo, now);

      return {
        'weekly': _calculateNutritionSummary(weeklyMeals),
        'monthly': _calculateNutritionSummary(monthlyMeals),
        'trends': await _calculateTrends(userId),
        'recommendations': _generateRecommendations(weeklyMeals),
      };
    } catch (e) {
      throw Exception('Failed to get comprehensive analytics: $e');
    }
  }

  // Get daily nutrition summary
  Future<Map<String, dynamic>> getDailyNutritionSummary(
      String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final meals = await _getMealsInPeriod(userId, startOfDay, endOfDay);
      return _calculateNutritionSummary(meals);
    } catch (e) {
      throw Exception('Failed to get daily nutrition summary: $e');
    }
  }

  // Get weekly nutrition summary
  Future<Map<String, dynamic>> getWeeklyNutritionSummary(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final meals = await _getMealsInPeriod(userId, weekAgo, now);
      return _calculateNutritionSummary(meals);
    } catch (e) {
      throw Exception('Failed to get weekly nutrition summary: $e');
    }
  }

  // Get monthly nutrition summary
  Future<Map<String, dynamic>> getMonthlyNutritionSummary(String userId) async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      final meals = await _getMealsInPeriod(userId, monthAgo, now);
      return _calculateNutritionSummary(meals);
    } catch (e) {
      throw Exception('Failed to get monthly nutrition summary: $e');
    }
  }

  // Get nutrition trends over time
  Future<Map<String, dynamic>> getNutritionTrends(String userId,
      {int days = 30}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final dailyData = <DateTime, Map<String, dynamic>>{};

      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final summary = await getDailyNutritionSummary(userId, date);
        dailyData[date] = summary;
      }

      return {
        'dailyData': dailyData,
        'averages': _calculateAverages(dailyData.values.toList()),
        'trends': _analyzeTrends(dailyData),
      };
    } catch (e) {
      throw Exception('Failed to get nutrition trends: $e');
    }
  }

  // Get meal distribution by category
  Future<Map<String, int>> getMealDistribution(String userId,
      {int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final meals = await _getMealsInPeriod(userId, startDate, now);

      final distribution = <String, int>{};
      for (final meal in meals) {
        final category = meal.mealCategory.toLowerCase();
        distribution[category] = (distribution[category] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      throw Exception('Failed to get meal distribution: $e');
    }
  }

  // Get top foods by frequency
  Future<List<Map<String, dynamic>>> getTopFoods(String userId,
      {int limit = 10, int days = 30}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final meals = await _getMealsInPeriod(userId, startDate, now);

      final foodFrequency = <String, int>{};
      final foodNutrition = <String, Nutrition>{};

      for (final meal in meals) {
        final foodName = meal.foodName.toLowerCase();
        foodFrequency[foodName] = (foodFrequency[foodName] ?? 0) + 1;
        foodNutrition[foodName] = meal.nutrition;
      }

      final sortedFoods = foodFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedFoods.take(limit).map((entry) {
        return {
          'foodName': entry.key,
          'frequency': entry.value,
          'nutrition': foodNutrition[entry.key]?.toMap() ?? {},
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get top foods: $e');
    }
  }

  // Get nutrition goals progress
  Future<Map<String, dynamic>> getNutritionGoalsProgress(
    String userId,
    DateTime date, {
    required double calorieGoal,
    required double proteinGoal,
    required double carbsGoal,
    required double fatGoal,
  }) async {
    try {
      final summary = await getDailyNutritionSummary(userId, date);

      final currentCalories =
          (summary['totalCalories'] as num?)?.toDouble() ?? 0.0;
      final currentProtein =
          (summary['totalProtein'] as num?)?.toDouble() ?? 0.0;
      final currentCarbs = (summary['totalCarbs'] as num?)?.toDouble() ?? 0.0;
      final currentFat = (summary['totalFat'] as num?)?.toDouble() ?? 0.0;

      return {
        'calories': {
          'current': currentCalories,
          'goal': calorieGoal,
          'percentage': calorieGoal > 0
              ? (currentCalories / calorieGoal * 100).clamp(0, 100)
              : 0,
          'remaining':
              (calorieGoal - currentCalories).clamp(0, double.infinity),
        },
        'protein': {
          'current': currentProtein,
          'goal': proteinGoal,
          'percentage': proteinGoal > 0
              ? (currentProtein / proteinGoal * 100).clamp(0, 100)
              : 0,
          'remaining': (proteinGoal - currentProtein).clamp(0, double.infinity),
        },
        'carbs': {
          'current': currentCarbs,
          'goal': carbsGoal,
          'percentage': carbsGoal > 0
              ? (currentCarbs / carbsGoal * 100).clamp(0, 100)
              : 0,
          'remaining': (carbsGoal - currentCarbs).clamp(0, double.infinity),
        },
        'fat': {
          'current': currentFat,
          'goal': fatGoal,
          'percentage':
              fatGoal > 0 ? (currentFat / fatGoal * 100).clamp(0, 100) : 0,
          'remaining': (fatGoal - currentFat).clamp(0, double.infinity),
        },
      };
    } catch (e) {
      throw Exception('Failed to get nutrition goals progress: $e');
    }
  }

  // Private helper methods
  Future<List<MealPlan>> _getMealsInPeriod(
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('meal_plans')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThan: end.toIso8601String())
          .get();

      return snapshot.docs.map((doc) {
        return MealPlan.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      // Fallback to client-side filtering if compound query fails
      final snapshot = await _firestore
          .collection('meal_plans')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => MealPlan.fromMap(doc.data(), doc.id))
          .where((meal) => meal.date.isAfter(start) && meal.date.isBefore(end))
          .toList();
    }
  }

  Map<String, dynamic> _calculateNutritionSummary(List<MealPlan> meals) {
    if (meals.isEmpty) {
      return {
        'totalCalories': 0.0,
        'totalProtein': 0.0,
        'totalCarbs': 0.0,
        'totalFat': 0.0,
        'totalFiber': 0.0,
        'totalSodium': 0.0,
        'mealCount': 0,
        'averageCaloriesPerMeal': 0.0,
        'macroDistribution': {
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
        },
      };
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSodium = 0;

    for (final meal in meals) {
      totalCalories += meal.nutrition.calories;
      totalProtein += meal.nutrition.protein;
      totalCarbs += meal.nutrition.carbs;
      totalFat += meal.nutrition.fat;
      totalFiber += meal.nutrition.fiber;
      totalSodium += meal.nutrition.sodium;
    }

    final totalMacros = totalProtein + totalCarbs + totalFat;

    return {
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalFiber': totalFiber,
      'totalSodium': totalSodium,
      'mealCount': meals.length,
      'averageCaloriesPerMeal':
          meals.isNotEmpty ? totalCalories / meals.length : 0.0,
      'macroDistribution': {
        'protein': totalMacros > 0 ? (totalProtein / totalMacros * 100) : 0.0,
        'carbs': totalMacros > 0 ? (totalCarbs / totalMacros * 100) : 0.0,
        'fat': totalMacros > 0 ? (totalFat / totalMacros * 100) : 0.0,
      },
    };
  }

  Future<Map<String, dynamic>> _calculateTrends(String userId) async {
    try {
      final now = DateTime.now();
      final last7Days = await getWeeklyNutritionSummary(userId);
      final previous7Days = await _getMealsInPeriod(
        userId,
        now.subtract(const Duration(days: 14)),
        now.subtract(const Duration(days: 7)),
      );
      final previous7Summary = _calculateNutritionSummary(previous7Days);

      final caloriesTrend = _calculatePercentageChange(
          last7Days['totalCalories'], previous7Summary['totalCalories']);

      final proteinTrend = _calculatePercentageChange(
          last7Days['totalProtein'], previous7Summary['totalProtein']);

      return {
        'caloriesTrend': caloriesTrend,
        'proteinTrend': proteinTrend,
        'isImproving': caloriesTrend >= 0 && proteinTrend >= 0,
      };
    } catch (e) {
      return {
        'caloriesTrend': 0.0,
        'proteinTrend': 0.0,
        'isImproving': false,
      };
    }
  }

  double _calculatePercentageChange(dynamic current, dynamic previous) {
    final currentValue = (current as num?)?.toDouble() ?? 0.0;
    final previousValue = (previous as num?)?.toDouble() ?? 0.0;

    if (previousValue == 0) return 0.0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  Map<String, dynamic> _calculateAverages(
      List<Map<String, dynamic>> dailyData) {
    if (dailyData.isEmpty) {
      return {
        'averageCalories': 0.0,
        'averageProtein': 0.0,
        'averageCarbs': 0.0,
        'averageFat': 0.0,
      };
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final day in dailyData) {
      totalCalories += (day['totalCalories'] as num?)?.toDouble() ?? 0.0;
      totalProtein += (day['totalProtein'] as num?)?.toDouble() ?? 0.0;
      totalCarbs += (day['totalCarbs'] as num?)?.toDouble() ?? 0.0;
      totalFat += (day['totalFat'] as num?)?.toDouble() ?? 0.0;
    }

    final count = dailyData.length;
    return {
      'averageCalories': count > 0 ? totalCalories / count : 0.0,
      'averageProtein': count > 0 ? totalProtein / count : 0.0,
      'averageCarbs': count > 0 ? totalCarbs / count : 0.0,
      'averageFat': count > 0 ? totalFat / count : 0.0,
    };
  }

  Map<String, dynamic> _analyzeTrends(
      Map<DateTime, Map<String, dynamic>> dailyData) {
    final dates = dailyData.keys.toList()..sort();
    if (dates.length < 2) {
      return {
        'caloriesTrend': 'stable',
        'proteinTrend': 'stable',
        'overallTrend': 'stable',
      };
    }

    final firstWeek = dates.take(dates.length ~/ 2).toList();
    final secondWeek = dates.skip(dates.length ~/ 2).toList();

    final firstWeekAvg =
        _calculateAverages(firstWeek.map((date) => dailyData[date]!).toList());
    final secondWeekAvg =
        _calculateAverages(secondWeek.map((date) => dailyData[date]!).toList());

    final caloriesChange = _calculatePercentageChange(
        secondWeekAvg['averageCalories'], firstWeekAvg['averageCalories']);

    final proteinChange = _calculatePercentageChange(
        secondWeekAvg['averageProtein'], firstWeekAvg['averageProtein']);

    return {
      'caloriesTrend': caloriesChange > 5
          ? 'increasing'
          : caloriesChange < -5
              ? 'decreasing'
              : 'stable',
      'proteinTrend': proteinChange > 5
          ? 'increasing'
          : proteinChange < -5
              ? 'decreasing'
              : 'stable',
      'overallTrend':
          (caloriesChange + proteinChange) > 5 ? 'improving' : 'stable',
    };
  }

  List<String> _generateRecommendations(List<MealPlan> meals) {
    final recommendations = <String>[];

    if (meals.isEmpty) {
      recommendations
          .add('Start tracking your meals to get personalized recommendations');
      return recommendations;
    }

    final summary = _calculateNutritionSummary(meals);
    final avgCalories = summary['averageCaloriesPerMeal'] as double;
    final proteinPercentage = summary['macroDistribution']['protein'] as double;

    if (avgCalories < 300) {
      recommendations
          .add('Consider adding more nutrient-dense foods to your meals');
    }

    if (proteinPercentage < 20) {
      recommendations.add('Try to include more protein sources in your diet');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Great job maintaining a balanced diet!');
    }

    return recommendations;
  }
}
