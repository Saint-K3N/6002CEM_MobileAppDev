class Nutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;

  const Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
    };
  }

  // Create from Map (Firestore document)
  factory Nutrition.fromMap(Map<String, dynamic> map) {
    return Nutrition(
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0.0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Copy with method for updates
  Nutrition copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sodium,
  }) {
    return Nutrition(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
    );
  }

  // Add two nutrition objects
  Nutrition operator +(Nutrition other) {
    return Nutrition(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      sodium: sodium + other.sodium,
    );
  }

  // Subtract two nutrition objects
  Nutrition operator -(Nutrition other) {
    return Nutrition(
      calories: (calories - other.calories).clamp(0, double.infinity),
      protein: (protein - other.protein).clamp(0, double.infinity),
      carbs: (carbs - other.carbs).clamp(0, double.infinity),
      fat: (fat - other.fat).clamp(0, double.infinity),
      fiber: (fiber - other.fiber).clamp(0, double.infinity),
      sodium: (sodium - other.sodium).clamp(0, double.infinity),
    );
  }

  // Multiply nutrition by a factor (for serving size calculations)
  Nutrition operator *(double factor) {
    return Nutrition(
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      sodium: sodium * factor,
    );
  }

  // Divide nutrition by a factor
  Nutrition operator /(double factor) {
    if (factor == 0) return this;
    return Nutrition(
      calories: calories / factor,
      protein: protein / factor,
      carbs: carbs / factor,
      fat: fat / factor,
      fiber: fiber / factor,
      sodium: sodium / factor,
    );
  }

  @override
  String toString() {
    return 'Nutrition(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat, fiber: $fiber, sodium: $sodium)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Nutrition &&
        other.calories == calories &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fat == fat &&
        other.fiber == fiber &&
        other.sodium == sodium;
  }

  @override
  int get hashCode {
    return Object.hash(calories, protein, carbs, fat, fiber, sodium);
  }

  // Helper getters
  double get totalMacros => protein + carbs + fat;
  double get proteinCalories => protein * 4;
  double get carbsCalories => carbs * 4;
  double get fatCalories => fat * 9;

  // Percentage calculations
  double get proteinPercentage =>
      calories > 0 ? (proteinCalories / calories) * 100 : 0;
  double get carbsPercentage =>
      calories > 0 ? (carbsCalories / calories) * 100 : 0;
  double get fatPercentage => calories > 0 ? (fatCalories / calories) * 100 : 0;

  // Check if nutrition values are valid
  bool get isValid =>
      calories >= 0 &&
      protein >= 0 &&
      carbs >= 0 &&
      fat >= 0 &&
      fiber >= 0 &&
      sodium >= 0;

  // Get formatted strings
  String get formattedCalories => '${calories.toStringAsFixed(0)} kcal';
  String get formattedProtein => '${protein.toStringAsFixed(1)}g protein';
  String get formattedCarbs => '${carbs.toStringAsFixed(1)}g carbs';
  String get formattedFat => '${fat.toStringAsFixed(1)}g fat';
  String get formattedFiber => '${fiber.toStringAsFixed(1)}g fiber';
  String get formattedSodium => '${sodium.toStringAsFixed(0)}mg sodium';

  // Static method to create empty nutrition
  static const Nutrition empty = Nutrition(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
    sodium: 0,
  );

  // Static method to create from calories and basic macros
  factory Nutrition.fromBasicMacros({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double fiber = 0,
    double sodium = 0,
  }) {
    return Nutrition(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sodium: sodium,
    );
  }

  // Calculate nutrition density (nutrition per calorie)
  double get nutritionDensity {
    if (calories == 0) return 0;
    return (protein + fiber) / calories * 100;
  }

  // Check if this is a high-protein food
  bool get isHighProtein => proteinPercentage > 30;

  // Check if this is a low-carb food
  bool get isLowCarb => carbsPercentage < 20;

  // Check if this is a high-fiber food
  bool get isHighFiber => fiber >= 5;

  // Check if this is low sodium
  bool get isLowSodium => sodium < 140;

  // Get quality score (0-100)
  double get qualityScore {
    double score = 50; // Start with neutral score

    // Add points for good things
    if (isHighProtein) score += 15;
    if (isHighFiber) score += 10;
    if (isLowSodium) score += 10;

    // Subtract points for bad things
    if (sodium > 600) score -= 15; // High sodium
    if (fatPercentage > 50) score -= 10; // Very high fat

    return score.clamp(0, 100);
  }

  // Create a scaled version based on serving size
  Nutrition scaledByServing(double servingMultiplier) {
    return this * servingMultiplier;
  }

  // Get macronutrient breakdown as percentages
  Map<String, double> get macroBreakdown {
    if (totalMacros == 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'protein': (protein / totalMacros) * 100,
      'carbs': (carbs / totalMacros) * 100,
      'fat': (fat / totalMacros) * 100,
    };
  }

  // Check if nutrition meets certain dietary requirements
  bool meetsDietaryRequirement(String requirement) {
    switch (requirement.toLowerCase()) {
      case 'low_carb':
        return carbsPercentage < 20;
      case 'high_protein':
        return proteinPercentage > 30;
      case 'low_sodium':
        return sodium < 140;
      case 'high_fiber':
        return fiber >= 5;
      case 'low_fat':
        return fatPercentage < 30;
      default:
        return false;
    }
  }
}
