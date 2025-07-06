import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../models/nutrition.dart';
import '../services/recipe_service.dart';
import '../services/firebase_meal_service.dart';
import '../constants.dart';
import 'meal_planning_screen.dart' as meal_planning;
import 'recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final RecipeService _recipeService = RecipeService();
  final FirebaseMealService _mealService = FirebaseMealService();

  List<Recipe> _recommendedRecipes = [];
  bool _isLoadingRecipes = true;
  Nutrition _todayNutrition = const Nutrition(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
    sodium: 0,
  );
  bool _isLoadingNutrition = true;
  String? _userId;
  int _todayMealCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadRecommendedRecipes(),
      _loadTodayNutrition(),
    ]);
  }

  Future<void> _loadRecommendedRecipes() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRecipes = true;
    });

    try {
      final recipes = await _recipeService.getRecommendedRecipes(
        limit: 10,
        dietType: null,
        allergies: [],
      );

      if (mounted) {
        setState(() {
          _recommendedRecipes = recipes;
          _isLoadingRecipes = false;
        });
      }
    } catch (e) {
      print('Error loading recommended recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecipes = false;
        });
      }
    }
  }

  Future<void> _loadTodayNutrition() async {
    if (_userId == null || !mounted) return;

    setState(() {
      _isLoadingNutrition = true;
    });

    try {
      final today = DateTime.now();
      final meals = await _mealService.getMealsForDate(_userId!, today);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final meal in meals) {
        totalCalories += meal.nutrition.calories;
        totalProtein += meal.nutrition.protein;
        totalCarbs += meal.nutrition.carbs;
        totalFat += meal.nutrition.fat;
      }

      if (mounted) {
        setState(() {
          _todayNutrition = Nutrition(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: 0,
            sodium: 0,
          );
          _todayMealCount = meals.length;
          _isLoadingNutrition = false;
        });
      }
    } catch (e) {
      print('Error loading today nutrition: $e');
      if (mounted) {
        setState(() {
          _isLoadingNutrition = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildWelcomeSection() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor,
            kPrimaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kSpacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: kSpacingMD),
              const Text(
                'Ready to plan your healthy meals today?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      margin: const EdgeInsets.all(kSpacingMD),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(kSpacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.today,
                    color: kPrimaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: kSpacingSM),
                  const Text(
                    'Today\'s Summary',
                    style: kHeadingStyle,
                  ),
                  const Spacer(),
                  if (_isLoadingNutrition)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kPrimaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: kSpacingMD),
              if (_todayMealCount > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildNutritionCard(
                        'Calories',
                        _todayNutrition.calories.toStringAsFixed(0),
                        'kcal',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: kSpacingSM),
                    Expanded(
                      child: _buildNutritionCard(
                        'Protein',
                        _todayNutrition.protein.toStringAsFixed(1),
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
                        _todayNutrition.carbs.toStringAsFixed(1),
                        'g',
                        Icons.grain,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: kSpacingSM),
                    Expanded(
                      child: _buildNutritionCard(
                        'Fat',
                        _todayNutrition.fat.toStringAsFixed(1),
                        'g',
                        Icons.opacity,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpacingMD),
                Container(
                  padding: const EdgeInsets.all(kSpacingSM),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: kSpacingSM),
                      Text(
                        '$_todayMealCount meals logged today',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(kSpacingLG),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: kSpacingSM),
                      Text(
                        'No meals logged today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start tracking your nutrition',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
            style: kCaptionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpacingMD),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(kSpacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: kHeadingStyle,
              ),
              const SizedBox(height: kSpacingMD),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const meal_planning.MealPlanningScreen(),
                      ),
                    );
                    if (result == true && mounted) {
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Start Meal Planning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: kSpacingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedRecipes() {
    return Container(
      margin: const EdgeInsets.all(kSpacingMD),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(kSpacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.recommend,
                    color: kPrimaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: kSpacingSM),
                  const Text(
                    'Recommended Recipes',
                    style: kHeadingStyle,
                  ),
                  const Spacer(),
                  if (_isLoadingRecipes)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kPrimaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: kSpacingMD),
              if (_recommendedRecipes.isNotEmpty)
                SizedBox(
                  height:
                      280, // ✅ Increased from 260 to 280 to prevent overflow
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendedRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recommendedRecipes[index];
                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: kSpacingMD),
                        child: _buildRecipeCard(recipe),
                      );
                    },
                  ),
                )
              else if (!_isLoadingRecipes)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(kSpacingLG),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: kSpacingSM),
                      Text(
                        'No recipes available',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: InkWell(
        onTap: () async {
          // Navigate to recipe details screen WITHOUT selectedDate
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(
                recipe: recipe,
                // Don't pass selectedDate - this makes it view-only
              ),
            ),
          );
          if (result == true && mounted) {
            _loadData();
          }
        },
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image - Fixed height to prevent overflow
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kBorderRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kBorderRadius),
                ),
                child: recipe.image.isNotEmpty
                    ? Image.network(
                  recipe.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.restaurant,
                        size: 40,
                        color: kPrimaryColor,
                      ),
                    );
                  },
                )
                    : const Icon(
                  Icons.restaurant,
                  size: 40,
                  color: kPrimaryColor,
                ),
              ),
            ),

            // Recipe Info
            Container(
              height: 115,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 35,
                    child: Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${recipe.calories > 0 ? recipe.calories : 250} cal',
                    style: const TextStyle(
                      fontSize: 11,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    height: 18,
                    child: recipe.dietLabels.isNotEmpty
                        ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
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
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text(
                        'View Recipe',
                        style: TextStyle(
                          fontSize: 11,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
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
    super.build(context);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: kPrimaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildWelcomeSection(),
              _buildTodaySummary(),
              _buildQuickActions(),
              _buildRecommendedRecipes(),
              const SizedBox(height: kSpacingLG),
            ],
          ),
        ),
      ),
    );
  }
}
