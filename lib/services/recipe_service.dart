import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecipeService {
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';
  static String get _apiKey => dotenv.env['SPOONACULAR_API_KEY'] ?? 'ef02d78de38f48a883f0684ad5133cc7';

  // Search recipes with enhanced nutrition information
  Future<List<Recipe>> searchRecipes({
    String query = '',
    String? dietType,
    List<String>? allergies,
    int limit = 10,
  }) async {
    try {
      print('🔍 Recipe Search Debug:');
      print('  Query: "$query"');
      print('  Diet Type: $dietType');
      print('  Allergies: $allergies');
      print('  Limit: $limit');

      // Try API call first
      final List<Recipe> apiResults = await _searchRecipesFromAPI(
        query: query,
        dietType: dietType,
        allergies: allergies,
        limit: limit,
      );

      if (apiResults.isNotEmpty) {
        print('✅ API Success: ${apiResults.length} recipes found');
        return apiResults;
      } else {
        print('⚠️ API returned empty, using fallback');
      }

      // Fallback to mock data
      print('📱 Using enhanced mock data');
      return _getMockRecipes(
        query: query,
        dietType: dietType,
        allergies: allergies,
        limit: limit,
      );
    } catch (e) {
      print('❌ Search error: $e');
      return _getMockRecipes(
        query: query,
        dietType: dietType,
        allergies: allergies,
        limit: limit,
      );
    }
  }

  Future<List<Recipe>> _searchRecipesFromAPI({
    String query = '',
    String? dietType,
    List<String>? allergies,
    int limit = 10,
  }) async {
    try {
      // Build API URL
      String url = '$_baseUrl/complexSearch?apiKey=$_apiKey&number=$limit&addRecipeInformation=true&fillIngredients=true&addRecipeNutrition=true';

      if (query.isNotEmpty) {
        url += '&query=${Uri.encodeComponent(query)}';
      }

      if (dietType != null && dietType != 'None' && dietType != 'All') {
        // Map diet types to API format
        String apiDiet = dietType.toLowerCase();
        if (apiDiet == 'gluten free') apiDiet = 'gluten-free';
        if (apiDiet == 'dairy free') apiDiet = 'dairy-free';
        url += '&diet=$apiDiet';
      }

      if (allergies != null && allergies.isNotEmpty) {
        final intolerances = allergies.map((allergy) => allergy.toLowerCase()).join(',');
        url += '&intolerances=${Uri.encodeComponent(intolerances)}';
      }

      print('🌐 API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MealPlanner/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Response Status: ${response.statusCode}');
      print('📊 Response Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for API error messages
        if (data.containsKey('message')) {
          print('⚠️ API Message: ${data['message']}');
          if (data['message'].toString().contains('quota')) {
            print('💳 API quota exceeded');
          }
          return [];
        }

        final results = data['results'] as List<dynamic>? ?? [];
        print('📋 Raw results count: ${results.length}');

        if (results.isEmpty) {
          print('⚠️ No results from API');
          return [];
        }

        final recipes = <Recipe>[];
        for (int i = 0; i < results.length; i++) {
          try {
            final recipe = Recipe.fromSpoonacularJson(results[i] as Map<String, dynamic>);
            recipes.add(recipe);
            print('✅ Parsed recipe ${i + 1}: ${recipe.title}');
          } catch (e) {
            print('❌ Failed to parse recipe ${i + 1}: $e');
          }
        }

        print('🎯 Final recipe count: ${recipes.length}');
        return recipes;

      } else {
        print('❌ API Error ${response.statusCode}');
        print('Response: ${response.body.substring(0, 200)}...');
        return [];
      }
    } catch (e) {
      print('💥 API Exception: $e');
      return [];
    }
  }

  // Get recommended recipes based on user preferences
  Future<List<Recipe>> getRecommendedRecipes({
    String? dietType,
    List<String>? allergies,
    int limit = 6,
  }) async {
    try {
      // Try API first
      final List<Recipe> apiResults = await _getRecommendedFromAPI(
        dietType: dietType,
        allergies: allergies,
        limit: limit,
      );

      if (apiResults.isNotEmpty) {
        return apiResults;
      }

      // Fallback to mock data
      return _getMockRecommendations(
        dietType: dietType,
        allergies: allergies,
        limit: limit,
      );
    } catch (e) {
      print('Error getting recommended recipes: $e');
      return _getMockRecommendations(
        dietType: dietType,
        allergies: allergies,
        limit: limit,
      );
    }
  }

  // Get recipes by meal type
  Future<List<Recipe>> getRecipesByMealType({
    required String mealType,
    String? dietType,
    List<String>? allergies,
    int limit = 10,
  }) async {
    try {
      final recipes = await searchRecipes(
        query: mealType,
        dietType: dietType,
        allergies: allergies,
        limit: limit,
      );

      return recipes;
    } catch (e) {
      print('Error getting recipes by meal type: $e');
      return [];
    }
  }

  // Private method to get recommendations from API
  Future<List<Recipe>> _getRecommendedFromAPI({
    String? dietType,
    List<String>? allergies,
    int limit = 6,
  }) async {
    try {
      String url =
          '$_baseUrl/random?apiKey=$_apiKey&number=$limit&addRecipeInformation=true&addRecipeNutrition=true';

      if (dietType != null && dietType != 'None') {
        url += '&tags=${Uri.encodeComponent(dietType.toLowerCase())}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipes = data['recipes'] as List<dynamic>? ?? [];

        List<Recipe> results = recipes.map((recipeData) {
          return Recipe.fromSpoonacularJson(recipeData as Map<String, dynamic>);
        }).toList();

        // Filter by allergies client-side
        if (allergies != null && allergies.isNotEmpty) {
          results = results.where((recipe) {
            return !allergies.any((allergy) => recipe.ingredients.any(
                (ingredient) =>
                    ingredient.toLowerCase().contains(allergy.toLowerCase())));
          }).toList();
        }

        return results;
      }

      return [];
    } catch (e) {
      print('API recommendations error: $e');
      return [];
    }
  }

  Future<void> testAPI() async {
    try {
      print('🧪 Testing Spoonacular API...');

      final response = await http.get(
        Uri.parse('$_baseUrl/random?apiKey=$_apiKey&number=1'),
        headers: {'User-Agent': 'MealPlanner/1.0'},
      ).timeout(const Duration(seconds: 10));

      print('Test Status: ${response.statusCode}');
      print('Test Response Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['recipes'] != null && data['recipes'].isNotEmpty) {
          print('✅ API is working! Recipe: ${data['recipes'][0]['title']}');
        } else {
          print('⚠️ API response has no recipes');
        }
      } else if (response.statusCode == 402) {
        print('💳 API quota exceeded - Status 402');
      } else if (response.statusCode == 401) {
        print('🔑 API key invalid - Status 401');
      } else {
        print('❌ API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 API Test failed: $e');
    }
  }

  // Enhanced mock recipes with more variety and proper diet filtering
  List<Recipe> _getMockRecipes({
    String query = '',
    String? dietType,
    List<String>? allergies,
    int limit = 10,
  }) {
    final List<Recipe> allMockRecipes = [
      // Mediterranean Recipes
      const Recipe(
        id: 'med1',
        title: 'Mediterranean Grilled Chicken',
        image: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6',
        readyInMinutes: 30,
        servings: 4,
        calories: 320,
        protein: 35.0,
        carbs: 8.0,
        fat: 16.0,
        fiber: 2.0,
        sodium: 180.0,
        instructions:
            'Marinate chicken in olive oil, lemon, and herbs. Grill for 6-8 minutes per side.',
        ingredients: [
          'Chicken breast',
          'Olive oil',
          'Lemon',
          'Oregano',
          'Garlic'
        ],
        dietLabels: ['Mediterranean', 'Gluten Free'],
        healthLabels: ['High Protein', 'Low Carb'],
        sourceUrl: 'https://example.com/med-chicken',
      ),
      const Recipe(
        id: 'med2',
        title: 'Mediterranean Quinoa Bowl',
        image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b',
        readyInMinutes: 25,
        servings: 2,
        calories: 380,
        protein: 14.0,
        carbs: 52.0,
        fat: 12.0,
        fiber: 8.0,
        sodium: 220.0,
        instructions: 'Cook quinoa, add vegetables, olives, and feta cheese.',
        ingredients: [
          'Quinoa',
          'Tomatoes',
          'Cucumber',
          'Olives',
          'Feta cheese'
        ],
        dietLabels: ['Mediterranean', 'Vegetarian'],
        healthLabels: ['High Fiber', 'Complete Protein'],
        sourceUrl: 'https://example.com/med-quinoa',
      ),
      // Vegetarian Recipes
      const Recipe(
        id: 'veg1',
        title: 'Vegetarian Buddha Bowl',
        image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
        readyInMinutes: 20,
        servings: 2,
        calories: 420,
        protein: 18.0,
        carbs: 65.0,
        fat: 14.0,
        fiber: 12.0,
        sodium: 160.0,
        instructions:
            'Arrange cooked grains, roasted vegetables, and protein in a bowl.',
        ingredients: [
          'Brown rice',
          'Sweet potato',
          'Chickpeas',
          'Spinach',
          'Tahini'
        ],
        dietLabels: ['Vegetarian', 'Vegan'],
        healthLabels: ['High Fiber', 'Plant Based'],
        sourceUrl: 'https://example.com/buddha-bowl',
      ),
      const Recipe(
        id: 'veg2',
        title: 'Caprese Stuffed Portobello',
        image: 'https://images.unsplash.com/photo-1565299507177-b0ac66763828',
        readyInMinutes: 25,
        servings: 2,
        calories: 280,
        protein: 16.0,
        carbs: 12.0,
        fat: 20.0,
        fiber: 4.0,
        sodium: 240.0,
        instructions:
            'Stuff portobello mushrooms with tomatoes, mozzarella, and basil.',
        ingredients: [
          'Portobello mushrooms',
          'Mozzarella',
          'Tomatoes',
          'Basil',
          'Balsamic'
        ],
        dietLabels: ['Vegetarian', 'Keto', 'Gluten Free'],
        healthLabels: ['Low Carb', 'High Protein'],
        sourceUrl: 'https://example.com/caprese-portobello',
      ),
      // Vegan Recipes
      const Recipe(
        id: 'vegan1',
        title: 'Vegan Lentil Curry',
        image: 'https://images.unsplash.com/photo-1585032226651-759b368d7246',
        readyInMinutes: 35,
        servings: 4,
        calories: 340,
        protein: 16.0,
        carbs: 58.0,
        fat: 8.0,
        fiber: 14.0,
        sodium: 280.0,
        instructions:
            'Simmer lentils with coconut milk, curry spices, and vegetables.',
        ingredients: [
          'Red lentils',
          'Coconut milk',
          'Curry powder',
          'Onion',
          'Spinach'
        ],
        dietLabels: ['Vegan', 'Vegetarian', 'Gluten Free'],
        healthLabels: ['High Fiber', 'Plant Based', 'High Protein'],
        sourceUrl: 'https://example.com/lentil-curry',
      ),
      // Keto Recipes
      const Recipe(
        id: 'keto1',
        title: 'Keto Salmon with Avocado',
        image: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288',
        readyInMinutes: 20,
        servings: 2,
        calories: 480,
        protein: 42.0,
        carbs: 6.0,
        fat: 32.0,
        fiber: 4.0,
        sodium: 220.0,
        instructions:
            'Bake salmon and serve with sliced avocado and leafy greens.',
        ingredients: [
          'Salmon fillet',
          'Avocado',
          'Spinach',
          'Olive oil',
          'Lemon'
        ],
        dietLabels: ['Keto', 'Paleo', 'Gluten Free'],
        healthLabels: ['High Protein', 'Low Carb', 'Omega-3'],
        sourceUrl: 'https://example.com/keto-salmon',
      ),
      // Gluten Free Recipes
      const Recipe(
        id: 'gf1',
        title: 'Gluten Free Chicken Stir Fry',
        image: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b',
        readyInMinutes: 15,
        servings: 3,
        calories: 290,
        protein: 28.0,
        carbs: 18.0,
        fat: 12.0,
        fiber: 5.0,
        sodium: 320.0,
        instructions: 'Stir fry chicken with vegetables in tamari sauce.',
        ingredients: [
          'Chicken strips',
          'Bell peppers',
          'Broccoli',
          'Tamari sauce',
          'Ginger'
        ],
        dietLabels: ['Gluten Free', 'Dairy Free'],
        healthLabels: ['High Protein', 'Low Carb'],
        sourceUrl: 'https://example.com/gf-stirfry',
      ),
      // Breakfast Options
      const Recipe(
        id: 'breakfast1',
        title: 'Mediterranean Breakfast Bowl',
        image: 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543',
        readyInMinutes: 10,
        servings: 1,
        calories: 350,
        protein: 18.0,
        carbs: 25.0,
        fat: 22.0,
        fiber: 6.0,
        sodium: 180.0,
        instructions: 'Combine Greek yogurt with nuts, berries, and honey.',
        ingredients: [
          'Greek yogurt',
          'Almonds',
          'Berries',
          'Honey',
          'Chia seeds'
        ],
        dietLabels: ['Mediterranean', 'Vegetarian', 'Gluten Free'],
        healthLabels: ['High Protein', 'Probiotics'],
        sourceUrl: 'https://example.com/med-breakfast',
      ),
      // More variety recipes
      const Recipe(
        id: 'paleo1',
        title: 'Paleo Beef and Vegetable Skillet',
        image: 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba',
        readyInMinutes: 25,
        servings: 4,
        calories: 380,
        protein: 32.0,
        carbs: 12.0,
        fat: 24.0,
        fiber: 4.0,
        sodium: 160.0,
        instructions: 'Brown ground beef with mixed vegetables and herbs.',
        ingredients: [
          'Ground beef',
          'Zucchini',
          'Bell peppers',
          'Onion',
          'Herbs'
        ],
        dietLabels: ['Paleo', 'Keto', 'Gluten Free', 'Dairy Free'],
        healthLabels: ['High Protein', 'Low Carb'],
        sourceUrl: 'https://example.com/paleo-beef',
      ),
    ];

    // Filter by query
    List<Recipe> filteredRecipes = allMockRecipes;
    if (query.isNotEmpty) {
      filteredRecipes = filteredRecipes
          .where((recipe) =>
              recipe.title.toLowerCase().contains(query.toLowerCase()) ||
              recipe.ingredients.any((ingredient) =>
                  ingredient.toLowerCase().contains(query.toLowerCase())))
          .toList();
    }

    // Filter by diet type (strict filtering)
    if (dietType != null && dietType != 'None' && dietType != 'All') {
      filteredRecipes = filteredRecipes
          .where((recipe) => recipe.dietLabels
          .any((label) => label.toLowerCase() == dietType.toLowerCase()))
          .toList();
    }

    // Filter by allergies
    if (allergies != null && allergies.isNotEmpty) {
      filteredRecipes = filteredRecipes.where((recipe) {
        return !allergies.any((allergy) => recipe.ingredients.any(
            (ingredient) =>
                ingredient.toLowerCase().contains(allergy.toLowerCase())));
      }).toList();
    }

    return filteredRecipes.take(limit).toList();
  }

  // Enhanced mock recommendations
  List<Recipe> _getMockRecommendations({
    String? dietType,
    List<String>? allergies,
    int limit = 6,
  }) {
    return _getMockRecipes(
      dietType: dietType,
      allergies: allergies,
      limit: limit,
    );
  }

  // Get recipe details by ID
  Future<Recipe?> getRecipeById(String id) async {
    try {
      // Try API first
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/$id/information?apiKey=$_apiKey&includeNutrition=true'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Recipe.fromSpoonacularJson(data);
      }

      // Fallback to mock data
      final mockRecipes = _getMockRecipes(limit: 100);
      return mockRecipes.firstWhere(
        (recipe) => recipe.id == id,
        orElse: () => mockRecipes.first,
      );
    } catch (e) {
      print('Error getting recipe by ID: $e');
      return null;
    }
  }

}
