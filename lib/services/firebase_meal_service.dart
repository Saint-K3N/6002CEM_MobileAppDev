import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_plan_model.dart';
import '../models/nutrition.dart';

class FirebaseMealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'meal_plans';

  Future<void> addMeal(MealPlan meal) async {
    try {
      // Generate new document ID
      final docRef = _firestore.collection(_collection).doc();

      // Create meal with the generated ID - save as Timestamp for new meals
      final mealData = {
        'id': docRef.id,
        'userId': meal.userId,
        'foodName': meal.foodName,
        'mealCategory': meal.mealCategory,
        'date': Timestamp.fromDate(meal.date),
        'createdAt': Timestamp.fromDate(meal.createdAt),
        'nutrition': {
          'calories': meal.nutrition.calories,
          'protein': meal.nutrition.protein,
          'carbs': meal.nutrition.carbs,
          'fat': meal.nutrition.fat,
          'fiber': meal.nutrition.fiber,
          'sodium': meal.nutrition.sodium,
        },
      };

      // Save to Firestore
      await docRef.set(mealData);
      print('✅ Meal added successfully: ${meal.foodName}');
    } catch (e) {
      print('❌ Error adding meal: $e');
      rethrow;
    }
  }

  DateTime _parseDate(dynamic dateField) {
    try {
      if (dateField is Timestamp) {
        // New format - Timestamp
        return dateField.toDate();
      } else if (dateField is String) {
        // Old format - String (handle existing data)
        return DateTime.parse(dateField);
      } else {
        // Fallback - current time
        print('⚠️ Unknown date format: ${dateField.runtimeType}');
        return DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parsing date: $e');
      return DateTime.now();
    }
  }

  Future<List<MealPlan>> getMealsForDate(String userId, DateTime date) async {
    try {
      print(
          '🔍 Getting meals for user: $userId, date: ${date.day}/${date.month}/${date.year}');

      // SUPER SIMPLE QUERY - hanya by userId
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      print('📄 Total documents found: ${snapshot.docs.length}');

      final List<MealPlan> mealsForDate = [];

      // Process each document
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Parse date - handle both String and Timestamp
          final DateTime mealDate = _parseDate(data['date']);

          // Check if this meal is for the target date
          if (mealDate.year == date.year &&
              mealDate.month == date.month &&
              mealDate.day == date.day) {
            // Create MealPlan object
            final meal = MealPlan(
              id: doc.id,
              userId: data['userId'] as String? ?? '',
              foodName: data['foodName'] as String? ?? 'Unknown Food',
              mealCategory: data['mealCategory'] as String? ?? 'Snack',
              date: mealDate,
              createdAt: _parseDate(data['createdAt']),
              nutrition: _parseNutrition(data['nutrition']),
            );

            mealsForDate.add(meal);
          }
        } catch (e) {
          print('⚠️ Error parsing document ${doc.id}: $e');
          // Continue processing other documents
        }
      }

      print('✅ Found ${mealsForDate.length} meals for target date');

      // Sort by meal category (Breakfast -> Lunch -> Dinner -> Snack)
      mealsForDate.sort((a, b) {
        const order = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
        final aIndex = order.indexOf(a.mealCategory);
        final bIndex = order.indexOf(b.mealCategory);
        return (aIndex == -1 ? 999 : aIndex)
            .compareTo(bIndex == -1 ? 999 : bIndex);
      });

      return mealsForDate;
    } catch (e) {
      print('❌ Error getting meals for date: $e');
      return [];
    }
  }

  Nutrition _parseNutrition(dynamic nutritionData) {
    try {
      if (nutritionData is Map<String, dynamic>) {
        return Nutrition(
          calories: _parseDouble(nutritionData['calories']),
          protein: _parseDouble(nutritionData['protein']),
          carbs: _parseDouble(nutritionData['carbs']),
          fat: _parseDouble(nutritionData['fat']),
          fiber: _parseDouble(nutritionData['fiber']),
          sodium: _parseDouble(nutritionData['sodium']),
        );
      } else {
        print('⚠️ Invalid nutrition data format');
        return const Nutrition(
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          fiber: 0,
          sodium: 0,
        );
      }
    } catch (e) {
      print('⚠️ Error parsing nutrition: $e');
      return const Nutrition(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sodium: 0,
      );
    }
  }

  double _parseDouble(dynamic value) {
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<MealPlan>> getMealsForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      print(
          '🔍 Getting meals for date range: ${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}');

      // Super simple query - only by userId
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final List<MealPlan> mealsInRange = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final DateTime mealDate = _parseDate(data['date']);

          // Check if meal date is within range
          if (mealDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              mealDate.isBefore(endDate.add(const Duration(days: 1)))) {
            final meal = MealPlan(
              id: doc.id,
              userId: data['userId'] as String? ?? '',
              foodName: data['foodName'] as String? ?? 'Unknown Food',
              mealCategory: data['mealCategory'] as String? ?? 'Snack',
              date: mealDate,
              createdAt: _parseDate(data['createdAt']),
              nutrition: _parseNutrition(data['nutrition']),
            );

            mealsInRange.add(meal);
          }
        } catch (e) {
          print('⚠️ Error parsing document ${doc.id}: $e');
        }
      }

      print('✅ Found ${mealsInRange.length} meals in date range');

      // Sort by date, then by meal category
      mealsInRange.sort((a, b) {
        final dateComp = a.date.compareTo(b.date);
        if (dateComp != 0) return dateComp;

        const order = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
        final aIndex = order.indexOf(a.mealCategory);
        final bIndex = order.indexOf(b.mealCategory);
        return (aIndex == -1 ? 999 : aIndex)
            .compareTo(bIndex == -1 ? 999 : bIndex);
      });

      return mealsInRange;
    } catch (e) {
      print('❌ Error getting meals for date range: $e');
      return [];
    }
  }

  Future<void> updateMeal(MealPlan meal) async {
    try {
      final mealData = {
        'userId': meal.userId,
        'foodName': meal.foodName,
        'mealCategory': meal.mealCategory,
        'date': Timestamp.fromDate(meal.date),
        'createdAt': Timestamp.fromDate(meal.createdAt),
        'nutrition': {
          'calories': meal.nutrition.calories,
          'protein': meal.nutrition.protein,
          'carbs': meal.nutrition.carbs,
          'fat': meal.nutrition.fat,
          'fiber': meal.nutrition.fiber,
          'sodium': meal.nutrition.sodium,
        },
      };

      await _firestore.collection(_collection).doc(meal.id).update(mealData);

      print('✅ Meal updated successfully: ${meal.foodName}');
    } catch (e) {
      print('❌ Error updating meal: $e');
      rethrow;
    }
  }

  Future<void> deleteMeal(String mealId) async {
    try {
      await _firestore.collection(_collection).doc(mealId).delete();

      print('✅ Meal deleted successfully: $mealId');
    } catch (e) {
      print('❌ Error deleting meal: $e');
      rethrow;
    }
  }

  Future<List<MealPlan>> getAllUserMeals(String userId) async {
    try {
      print('🔍 Getting all meals for user: $userId');

      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final List<MealPlan> meals = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          final meal = MealPlan(
            id: doc.id,
            userId: data['userId'] as String? ?? '',
            foodName: data['foodName'] as String? ?? 'Unknown Food',
            mealCategory: data['mealCategory'] as String? ?? 'Snack',
            date: _parseDate(data['date']),
            createdAt: _parseDate(data['createdAt']),
            nutrition: _parseNutrition(data['nutrition']),
          );

          meals.add(meal);
        } catch (e) {
          print('⚠️ Error parsing document ${doc.id}: $e');
        }
      }

      print('✅ Found ${meals.length} total meals');

      // Sort by date (newest first)
      meals.sort((a, b) => b.date.compareTo(a.date));

      return meals;
    } catch (e) {
      print('❌ Error getting all user meals: $e');
      return [];
    }
  }

  Future<List<MealPlan>> getMealsByCategory(
      String userId, DateTime date, String category) async {
    try {
      final allMeals = await getMealsForDate(userId, date);
      final categoryMeals =
          allMeals.where((meal) => meal.mealCategory == category).toList();

      print('✅ Found ${categoryMeals.length} meals for category: $category');
      return categoryMeals;
    } catch (e) {
      print('❌ Error getting meals by category: $e');
      return [];
    }
  }

  Future<Map<String, double>> getNutritionSummary(
      String userId, DateTime date) async {
    try {
      final meals = await getMealsForDate(userId, date);

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

      final summary = {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'fiber': totalFiber,
        'sodium': totalSodium,
      };

      print(
          '✅ Nutrition summary calculated: ${totalCalories.toStringAsFixed(0)} calories');
      return summary;
    } catch (e) {
      print('❌ Error getting nutrition summary: $e');
      return {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
        'fiber': 0,
        'sodium': 0,
      };
    }
  }

  // Stream for real-time updates
  Stream<List<MealPlan>> getMealsForDateStream(String userId, DateTime date) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final List<MealPlan> meals = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final DateTime mealDate = _parseDate(data['date']);

          if (mealDate.year == date.year &&
              mealDate.month == date.month &&
              mealDate.day == date.day) {
            final meal = MealPlan(
              id: doc.id,
              userId: data['userId'] as String? ?? '',
              foodName: data['foodName'] as String? ?? 'Unknown Food',
              mealCategory: data['mealCategory'] as String? ?? 'Snack',
              date: mealDate,
              createdAt: _parseDate(data['createdAt']),
              nutrition: _parseNutrition(data['nutrition']),
            );

            meals.add(meal);
          }
        } catch (e) {
          print('⚠️ Error parsing document ${doc.id} in stream: $e');
        }
      }

      // Sort by meal category
      meals.sort((a, b) {
        const order = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
        final aIndex = order.indexOf(a.mealCategory);
        final bIndex = order.indexOf(b.mealCategory);
        return (aIndex == -1 ? 999 : aIndex)
            .compareTo(bIndex == -1 ? 999 : bIndex);
      });

      return meals;
    });
  }

  // Batch operations
  Future<void> addMultipleMeals(List<MealPlan> meals) async {
    try {
      final batch = _firestore.batch();

      for (final meal in meals) {
        final docRef = _firestore.collection(_collection).doc();

        final mealData = {
          'id': docRef.id,
          'userId': meal.userId,
          'foodName': meal.foodName,
          'mealCategory': meal.mealCategory,
          'date': Timestamp.fromDate(meal.date),
          'createdAt': Timestamp.fromDate(meal.createdAt),
          'nutrition': {
            'calories': meal.nutrition.calories,
            'protein': meal.nutrition.protein,
            'carbs': meal.nutrition.carbs,
            'fat': meal.nutrition.fat,
            'fiber': meal.nutrition.fiber,
            'sodium': meal.nutrition.sodium,
          },
        };

        batch.set(docRef, mealData);
      }

      await batch.commit();
      print('✅ Added ${meals.length} meals in batch');
    } catch (e) {
      print('❌ Error adding multiple meals: $e');
      rethrow;
    }
  }

  Future<void> deleteMultipleMeals(List<String> mealIds) async {
    try {
      final batch = _firestore.batch();

      for (final mealId in mealIds) {
        final docRef = _firestore.collection(_collection).doc(mealId);
        batch.delete(docRef);
      }

      await batch.commit();
      print('✅ Deleted ${mealIds.length} meals in batch');
    } catch (e) {
      print('❌ Error deleting multiple meals: $e');
      rethrow;
    }
  }

  // Analytics helpers
  Future<Map<String, int>> getMealCountByCategory(
      String userId, DateTime date) async {
    try {
      final meals = await getMealsForDate(userId, date);

      final Map<String, int> counts = {
        'Breakfast': 0,
        'Lunch': 0,
        'Dinner': 0,
        'Snack': 0,
      };

      for (final meal in meals) {
        counts[meal.mealCategory] = (counts[meal.mealCategory] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('❌ Error getting meal count by category: $e');
      return {'Breakfast': 0, 'Lunch': 0, 'Dinner': 0, 'Snack': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyNutritionSummary(
      String userId, DateTime startDate) async {
    try {
      final endDate = startDate.add(const Duration(days: 6));
      final meals = await getMealsForDateRange(userId, startDate, endDate);

      final List<Map<String, dynamic>> weeklyData = [];

      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final dayMeals = meals
            .where((meal) =>
                meal.date.year == date.year &&
                meal.date.month == date.month &&
                meal.date.day == date.day)
            .toList();

        double dayCalories = 0;
        double dayProtein = 0;
        double dayCarbs = 0;
        double dayFat = 0;

        for (final meal in dayMeals) {
          dayCalories += meal.nutrition.calories;
          dayProtein += meal.nutrition.protein;
          dayCarbs += meal.nutrition.carbs;
          dayFat += meal.nutrition.fat;
        }

        weeklyData.add({
          'date': date,
          'calories': dayCalories,
          'protein': dayProtein,
          'carbs': dayCarbs,
          'fat': dayFat,
          'mealCount': dayMeals.length,
        });
      }

      return weeklyData;
    } catch (e) {
      print('❌ Error getting weekly nutrition summary: $e');
      return [];
    }
  }

  addFoodToMealPlan({required String userId, required String foodName, required Nutrition nutrition, required String mealCategory, required DateTime date}) {}
}
