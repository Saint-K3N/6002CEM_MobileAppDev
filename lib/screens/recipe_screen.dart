import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/recipe_service.dart';
import '../services/firebase_user_service.dart';
import '../services/firebase_meal_service.dart';
import '../models/recipe.dart';
import '../models/user_model.dart';
import '../models/meal_plan_model.dart';
import '../constants.dart';
import 'recipe_detail_screen.dart';


class RecipeScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const RecipeScreen({
    super.key,
    this.selectedDate,
  });

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  final FirebaseUserService _userService = FirebaseUserService();
  final FirebaseMealService _mealService = FirebaseMealService();
  final TextEditingController _searchController = TextEditingController();

  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  UserModel? _user;
  bool _isLoading = true;
  String _selectedDietFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();

    _recipeService.testAPI();

  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _userService.getUserProfile(user.uid);

        print('🍽️ USER DIET PREFERENCE: ${userData?.dietType}');
        print('🍽️ USER ALLERGIES: ${userData?.allergies}');

        List<Recipe> recipes;
        // ✅ FIXED: Only filter if diet is NOT "None"
        if (userData != null && userData.dietType != 'None' && userData.dietType.isNotEmpty) {
          print('📱 Loading recipes with diet filter: ${userData.dietType}');
          recipes = await _recipeService.searchRecipes(
            dietType: userData.dietType,
            allergies: userData.allergies,
            limit: 50,
          );
        } else {
          print('📱 Loading ALL recipes (diet = None)');
          recipes = await _recipeService.searchRecipes(
            dietType: 'None', // ✅ Explicitly pass 'None'
            allergies: userData?.allergies ?? [],
            limit: 50,
          );
        }

        if (mounted) {
          setState(() {
            _user = userData;
            _recipes = recipes;
            _filteredRecipes = recipes;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _recipes.where((recipe) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recipe.ingredients.any((ingredient) =>
                ingredient.toLowerCase().contains(_searchQuery.toLowerCase()));

        // Diet filter
        bool matchesDiet = _selectedDietFilter == 'All' ||
            recipe.dietLabels.any((label) => label
                .toLowerCase()
                .contains(_selectedDietFilter.toLowerCase()));

        return matchesSearch && matchesDiet;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterRecipes();
  }

  void _onDietFilterChanged(String diet) {
    setState(() {
      _selectedDietFilter = diet;
    });
    _filterRecipes();
  }

  Future<void> _addToMealPlan(Recipe recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final targetDate = widget.selectedDate ?? DateTime.now();

      // Show meal category selection
      final selectedCategory = await _showMealCategoryDialog();
      if (selectedCategory == null) return;

      final meal = MealPlan(
        id: '',
        userId: user.uid,
        foodName: recipe.title,
        nutrition: recipe.nutrition,
        mealCategory: selectedCategory,
        date: targetDate,
        createdAt: DateTime.now(),
      );

      await _mealService.addMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${recipe.title} successfully added to $selectedCategory!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Show success notification but DON'T go back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${recipe.title} successfully added to $selectedCategory!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'View Meal Plan',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ),
        );

        // Don't navigate back automatically - user stays in recipe screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error adding to meal plan: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
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

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(kSpacingMD),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
            ),
            onChanged: _onSearchChanged,
          ),

          const SizedBox(height: kSpacingSM),

          // Diet filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'All',
                'Vegetarian',
                'Vegan',
                'Keto',
                'Mediterranean',
                'Gluten Free'
              ]
                  .map((diet) => Padding(
                        padding: const EdgeInsets.only(right: kSpacingSM),
                        child: FilterChip(
                          label: Text(diet),
                          selected: _selectedDietFilter == diet,
                          onSelected: (_) => _onDietFilterChanged(diet),
                          selectedColor: kPrimaryColor.withValues(alpha: 0.2),
                          checkmarkColor: kPrimaryColor,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(kSpacingLG),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpacingLG),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: kSpacingMD),
              Text(
                _searchQuery.isNotEmpty || _selectedDietFilter != 'All'
                    ? 'No recipes found matching your criteria'
                    : 'No recipes available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kSpacingSM),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onDietFilterChanged('All');
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(kSpacingMD),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72, // Changed from 0.8 to 0.72 for more height
        crossAxisSpacing: kSpacingMD,
        mainAxisSpacing: kSpacingMD,
      ),
      itemCount: _filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _filteredRecipes[index];
        return _buildRecipeCard(recipe);
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(
                recipe: recipe,
                selectedDate: widget.selectedDate,
              ),
            ),
          );

          // Auto reload if something was added
          if (result == true && mounted) {
            Navigator.pop(context, true);
          }
        },
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image - Fixed height to prevent overflow
            Container(
              height: 120, // Fixed height instead of Expanded
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(kBorderRadius),
                  topRight: Radius.circular(kBorderRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(kBorderRadius),
                  topRight: Radius.circular(kBorderRadius),
                ),
                child: recipe.image.isNotEmpty
                    ? Image.network(
                        recipe.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),

            // Recipe Info - Fixed height with proper spacing
            Container(
              height: 110, // Increased from 100 to 110 for more space
              padding: const EdgeInsets.all(6), // Reduced padding from 8 to 6
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title - Fixed height
                  SizedBox(
                    height: 32, // Fixed height for title
                    child: Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Time and calories - Fixed height
                  SizedBox(
                    height: 16, // Fixed height
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          recipe.formattedTime,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${recipe.calories} cal',
                          style: const TextStyle(
                            fontSize: 10,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 2), // Reduced spacing

                  // Diet label - Fixed height
                  SizedBox(
                    height: 18, // Fixed height for diet label area
                    child: recipe.dietLabels.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              recipe.dietLabels.first,
                              style: const TextStyle(
                                fontSize: 9,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 4), // Fixed spacing

                  // Add button - Fixed height
                  SizedBox(
                    width: double.infinity,
                    height: 26, // Reduced from 28 to 26
                    child: ElevatedButton(
                      onPressed: () => _addToMealPlan(recipe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.selectedDate != null)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${widget.selectedDate!.day}/${widget.selectedDate!.month}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh recipes',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: kPrimaryColor,
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildRecipeGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
