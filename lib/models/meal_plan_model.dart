import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nutrition.dart';

class MealPlan {
  final String id;
  final String userId;
  final String foodName;
  final Nutrition nutrition;
  final String mealCategory;
  final DateTime date;
  final DateTime createdAt;

  MealPlan({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.nutrition,
    required this.mealCategory,
    required this.date,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'foodName': foodName,
      'nutrition': nutrition.toMap(),
      'mealCategory': mealCategory,
      'date': date.toIso8601String(), // Store as string for consistency
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map (Firestore document)
  factory MealPlan.fromMap(Map<String, dynamic> map, String id) {
    // Parse date from different formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String && dateValue.isNotEmpty) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      } else {
        return DateTime.now();
      }
    }

    return MealPlan(
      id: id,
      userId: map['userId'] ?? '',
      foodName: map['foodName'] ?? '',
      nutrition: map['nutrition'] != null
          ? Nutrition.fromMap(map['nutrition'] as Map<String, dynamic>)
          : const Nutrition(
              calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sodium: 0),
      mealCategory: map['mealCategory'] ?? '',
      date: parseDate(map['date']),
      createdAt: parseDate(map['createdAt']),
    );
  }

  // Copy with method for updates
  MealPlan copyWith({
    String? id,
    String? userId,
    String? foodName,
    Nutrition? nutrition,
    String? mealCategory,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      nutrition: nutrition ?? this.nutrition,
      mealCategory: mealCategory ?? this.mealCategory,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MealPlan(id: $id, foodName: $foodName, mealCategory: $mealCategory)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper getters
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
  String get formattedTime =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  bool get isBreakfast => mealCategory.toLowerCase() == 'breakfast';
  bool get isLunch => mealCategory.toLowerCase() == 'lunch';
  bool get isDinner => mealCategory.toLowerCase() == 'dinner';
  bool get isSnack => mealCategory.toLowerCase() == 'snack';
}
