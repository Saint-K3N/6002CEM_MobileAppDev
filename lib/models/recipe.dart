import 'nutrition.dart';

class Recipe {
  final String id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final String instructions;
  final List<String> ingredients;
  final List<String> dietLabels;
  final List<String> healthLabels;
  final String sourceUrl;
  final String? summary;
  final double healthScore;
  final String cuisine;

  const Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.readyInMinutes,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.instructions,
    required this.ingredients,
    required this.dietLabels,
    required this.healthLabels,
    required this.sourceUrl,
    this.summary,
    this.healthScore = 0.0,
    this.cuisine = 'Unknown',
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodium': sodium,
      'instructions': instructions,
      'ingredients': ingredients,
      'dietLabels': dietLabels,
      'healthLabels': healthLabels,
      'sourceUrl': sourceUrl,
      'summary': summary,
      'healthScore': healthScore,
      'cuisine': cuisine,
    };
  }

  // Create from Map
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      image: map['image'] ?? '',
      readyInMinutes: (map['readyInMinutes'] as num?)?.toInt() ?? 0,
      servings: (map['servings'] as num?)?.toInt() ?? 1,
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0.0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
      instructions: map['instructions'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      dietLabels: List<String>.from(map['dietLabels'] ?? []),
      healthLabels: List<String>.from(map['healthLabels'] ?? []),
      sourceUrl: map['sourceUrl'] ?? '',
      summary: map['summary'],
      healthScore: (map['healthScore'] as num?)?.toDouble() ?? 0.0,
      cuisine: map['cuisine'] ?? 'Unknown',
    );
  }

  // Helper method to estimate nutrition when API data is missing
  static Map<String, double> _estimateNutrition(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toLowerCase();

    if (title.contains('salad')) {
      return {'calories': 180.0, 'protein': 8.0, 'carbs': 15.0, 'fat': 12.0};
    } else if (title.contains('chicken')) {
      return {'calories': 320.0, 'protein': 35.0, 'carbs': 8.0, 'fat': 16.0};
    } else if (title.contains('pasta')) {
      return {'calories': 380.0, 'protein': 14.0, 'carbs': 65.0, 'fat': 8.0};
    } else if (title.contains('soup')) {
      return {'calories': 150.0, 'protein': 8.0, 'carbs': 20.0, 'fat': 4.0};
    } else if (title.contains('beef')) {
      return {'calories': 400.0, 'protein': 30.0, 'carbs': 10.0, 'fat': 25.0};
    } else if (title.contains('fish') || title.contains('salmon')) {
      return {'calories': 280.0, 'protein': 25.0, 'carbs': 5.0, 'fat': 18.0};
    } else if (title.contains('pizza')) {
      return {'calories': 285.0, 'protein': 12.0, 'carbs': 36.0, 'fat': 10.0};
    } else if (title.contains('burger')) {
      return {'calories': 540.0, 'protein': 25.0, 'carbs': 40.0, 'fat': 31.0};
    } else if (title.contains('rice')) {
      return {'calories': 300.0, 'protein': 12.0, 'carbs': 42.0, 'fat': 10.0};
    } else if (title.contains('sandwich')) {
      return {'calories': 320.0, 'protein': 15.0, 'carbs': 42.0, 'fat': 12.0};
    } else if (title.contains('curry')) {
      return {'calories': 300.0, 'protein': 20.0, 'carbs': 18.0, 'fat': 18.0};
    } else if (title.contains('bread')) {
      return {'calories': 280.0, 'protein': 8.0, 'carbs': 45.0, 'fat': 8.0};
    } else if (title.contains('egg')) {
      return {'calories': 200.0, 'protein': 15.0, 'carbs': 2.0, 'fat': 14.0};
    } else if (title.contains('vegetable') || title.contains('veggie')) {
      return {'calories': 120.0, 'protein': 5.0, 'carbs': 20.0, 'fat': 3.0};
    } else if (title.contains('fruit')) {
      return {'calories': 80.0, 'protein': 1.0, 'carbs': 20.0, 'fat': 0.5};
    } else if (title.contains('cake') || title.contains('dessert')) {
      return {'calories': 350.0, 'protein': 5.0, 'carbs': 50.0, 'fat': 15.0};
    }

    // Default estimation for unknown recipes
    return {'calories': 250.0, 'protein': 15.0, 'carbs': 30.0, 'fat': 8.0};
  }

  // Create from Spoonacular API response
  factory Recipe.fromSpoonacularJson(Map<String, dynamic> json) {
    // Extract nutrition information
    final nutrition = json['nutrition'] as Map<String, dynamic>?;
    final nutrients = nutrition?['nutrients'] as List<dynamic>? ?? [];

    double findNutrient(String name) {
      try {
        final nutrient = nutrients.firstWhere(
              (n) => n['name']?.toString().toLowerCase() == name.toLowerCase(),
          orElse: () => {'amount': 0},
        );
        return (nutrient['amount'] as num?)?.toDouble() ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    // Get nutrition values from API
    double calories = findNutrient('Calories');
    double protein = findNutrient('Protein');
    double carbs = findNutrient('Carbohydrates');
    double fat = findNutrient('Fat');
    double fiber = findNutrient('Fiber');
    double sodium = findNutrient('Sodium');

    // If API nutrition is empty or zero, use estimates
    if (calories == 0) {
      final estimates = _estimateNutrition(json);
      calories = estimates['calories']!;
      protein = estimates['protein']!;
      carbs = estimates['carbs']!;
      fat = estimates['fat']!;
    }

    // Extract diet and health labels
    final List<String> diets = [];
    if (json['vegetarian'] == true) diets.add('Vegetarian');
    if (json['vegan'] == true) diets.add('Vegan');
    if (json['glutenFree'] == true) diets.add('Gluten Free');
    if (json['dairyFree'] == true) diets.add('Dairy Free');
    if (json['veryHealthy'] == true) diets.add('Healthy');
    if (json['cheap'] == true) diets.add('Budget Friendly');
    if (json['veryPopular'] == true) diets.add('Popular');

    // Extract ingredients
    final extendedIngredients = json['extendedIngredients'] as List<dynamic>? ?? [];
    final ingredients = extendedIngredients
        .map((ingredient) => ingredient['original']?.toString() ?? '')
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();

    // Extract cuisine
    final cuisines = json['cuisines'] as List<dynamic>? ?? [];
    final cuisine = cuisines.isNotEmpty ? cuisines[0].toString() : 'Unknown';

    return Recipe(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      readyInMinutes: (json['readyInMinutes'] as num?)?.toInt() ?? 30,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      calories: calories.toInt(),
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sodium: sodium,
      instructions: _extractInstructions(json),
      ingredients: ingredients,
      dietLabels: diets,
      healthLabels: _extractHealthLabels(json),
      sourceUrl: json['sourceUrl'] ?? '',
      summary: json['summary'],
      healthScore: (json['healthScore'] as num?)?.toDouble() ?? 0.0,
      cuisine: cuisine,
    );
  }

  static String _extractInstructions(Map<String, dynamic> json) {
    // Try to get analyzedInstructions first
    final analyzedInstructions = json['analyzedInstructions'] as List<dynamic>?;
    if (analyzedInstructions != null && analyzedInstructions.isNotEmpty) {
      final steps = analyzedInstructions[0]['steps'] as List<dynamic>? ?? [];
      return steps
          .map((step) => step['step']?.toString() ?? '')
          .where((step) => step.isNotEmpty)
          .join('\n');
    }

    // Fallback to instructions string
    return json['instructions']?.toString() ?? '';
  }

  static List<String> _extractHealthLabels(Map<String, dynamic> json) {
    final List<String> labels = [];

    if (json['lowFodmap'] == true) labels.add('Low FODMAP');
    if (json['sustainable'] == true) labels.add('Sustainable');
    if (json['ketogenic'] == true) labels.add('Keto');
    if (json['whole30'] == true) labels.add('Whole30');

    return labels;
  }

  // Copy with method for updates
  Recipe copyWith({
    String? id,
    String? title,
    String? image,
    int? readyInMinutes,
    int? servings,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sodium,
    String? instructions,
    List<String>? ingredients,
    List<String>? dietLabels,
    List<String>? healthLabels,
    String? sourceUrl,
    String? summary,
    double? healthScore,
    String? cuisine,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sodium: sodium ?? this.sodium,
      instructions: instructions ?? this.instructions,
      ingredients: ingredients ?? this.ingredients,
      dietLabels: dietLabels ?? this.dietLabels,
      healthLabels: healthLabels ?? this.healthLabels,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      summary: summary ?? this.summary,
      healthScore: healthScore ?? this.healthScore,
      cuisine: cuisine ?? this.cuisine,
    );
  }

  // Get nutrition as Nutrition object
  Nutrition get nutrition => Nutrition(
    calories: calories.toDouble(),
    protein: protein,
    carbs: carbs,
    fat: fat,
    fiber: fiber,
    sodium: sodium,
  );

  // Get nutrition per serving
  Nutrition get nutritionPerServing =>
      servings > 0 ? nutrition * (1.0 / servings) : nutrition;

  // Helper getters
  String get formattedTime {
    if (readyInMinutes < 60) {
      return '${readyInMinutes}min';
    } else {
      final hours = readyInMinutes ~/ 60;
      final minutes = readyInMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    }
  }

  String get difficultyLevel {
    if (readyInMinutes <= 15) return 'Quick';
    if (readyInMinutes <= 30) return 'Easy';
    if (readyInMinutes <= 60) return 'Medium';
    return 'Complex';
  }

  bool get isVegetarian =>
      dietLabels.any((label) => label.toLowerCase().contains('vegetarian'));

  bool get isVegan =>
      dietLabels.any((label) => label.toLowerCase().contains('vegan'));

  bool get isGlutenFree =>
      dietLabels.any((label) => label.toLowerCase().contains('gluten free'));

  bool get isDairyFree =>
      dietLabels.any((label) => label.toLowerCase().contains('dairy free'));

  bool get isHealthy =>
      healthLabels.isNotEmpty ||
          dietLabels.any((label) => label.toLowerCase().contains('healthy'));

  // Additional getters that might be used in UI
  String get formattedHealthScore => '${healthScore.toStringAsFixed(1)}/100';

  String get formattedCuisine => cuisine.isEmpty ? 'International' : cuisine;

  String get formattedCalories => '$calories cal';

  String get formattedServings =>
      servings == 1 ? '1 serving' : '$servings servings';

  // Popularity score (derived from health score and other factors)
  double get popularity {
    double score = healthScore / 10; // Base score from health
    if (isVegetarian) score += 1;
    if (isVegan) score += 1;
    if (isGlutenFree) score += 0.5;
    if (readyInMinutes <= 30) score += 1; // Quick recipes are popular
    return score.clamp(0, 10);
  }

  String get formattedPopularity => '${popularity.toStringAsFixed(1)}/10';

  // Recipe type based on meal timing
  String get mealType {
    if (readyInMinutes <= 15) return 'Quick';
    if (calories < 300) return 'Light';
    if (calories > 600) return 'Hearty';
    return 'Regular';
  }

  // Check if recipe matches a specific diet
  bool matchesDiet(String diet) {
    final dietLower = diet.toLowerCase();
    return dietLabels.any((label) => label.toLowerCase().contains(dietLower)) ||
        healthLabels.any((label) => label.toLowerCase().contains(dietLower));
  }

  // Get recipe complexity score
  int get complexityScore {
    int score = 0;
    score += ingredients.length; // More ingredients = more complex
    score += (readyInMinutes / 15).round(); // Longer time = more complex
    return score;
  }

  // Get macronutrient percentages
  Map<String, double> get macroPercentages {
    final totalMacros = protein + carbs + fat;
    if (totalMacros == 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'protein': (protein / totalMacros * 100),
      'carbs': (carbs / totalMacros * 100),
      'fat': (fat / totalMacros * 100),
    };
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, readyInMinutes: $readyInMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}