import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/analytics_service.dart';
import '../services/firebase_user_service.dart';
import '../models/user_model.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final FirebaseUserService _userService = FirebaseUserService();

  String _selectedPeriod = 'Today';
  Map<String, dynamic> _analyticsData = {};
  UserModel? _userModel;
  bool _isLoading = true;

  // Custom goals - now editable!
  double _customCalorieGoal = 2000;
  double _customProteinGoal = 150;
  double _customCarbsGoal = 250;
  double _customFatGoal = 65;

  final TextEditingController _calorieController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _calorieController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _userService.getUserProfile(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _userModel = userData;
            _customCalorieGoal = userData.dailyCalorieGoal?.toDouble() ?? 2000;
            _customProteinGoal = 150;
            _customCarbsGoal = 250;
            _customFatGoal = 65;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> data;

        switch (_selectedPeriod) {
          case 'Today':
            data = await _analyticsService.getDailyNutritionSummary(
                user.uid, DateTime.now());
            break;
          case '7 Days':
            data = await _analyticsService.getWeeklyNutritionSummary(user.uid);
            break;
          case '30 Days':
            data = await _analyticsService.getMonthlyNutritionSummary(user.uid);
            break;
          default:
            data = await _analyticsService.getDailyNutritionSummary(
                user.uid, DateTime.now());
        }

        if (mounted) {
          setState(() {
            _analyticsData = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showGoalsDialog() async {
    _calorieController.text = _customCalorieGoal.toString();
    _proteinController.text = _customProteinGoal.toString();
    _carbsController.text = _customCarbsGoal.toString();
    _fatController.text = _customFatGoal.toString();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        title: const Row(
          children: [
            Icon(Icons.flag, color: kPrimaryColor),
            SizedBox(width: 8),
            Text('Set Your Daily Goals'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set your daily nutrition targets to track your progress',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              _buildGoalInput(
                controller: _calorieController,
                label: 'Daily Calorie Goal',
                suffix: 'kcal',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildGoalInput(
                controller: _proteinController,
                label: 'Daily Protein Goal',
                suffix: 'g',
                icon: Icons.fitness_center,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              _buildGoalInput(
                controller: _carbsController,
                label: 'Daily Carbs Goal',
                suffix: 'g',
                icon: Icons.grain,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildGoalInput(
                controller: _fatController,
                label: 'Daily Fat Goal',
                suffix: 'g',
                icon: Icons.opacity,
                color: Colors.green,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveGoals();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Goals'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalInput({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, color: color),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Future<void> _saveGoals() async {
    try {
      final newCalorieGoal =
          double.tryParse(_calorieController.text) ?? _customCalorieGoal;
      final newProteinGoal =
          double.tryParse(_proteinController.text) ?? _customProteinGoal;
      final newCarbsGoal =
          double.tryParse(_carbsController.text) ?? _customCarbsGoal;
      final newFatGoal = double.tryParse(_fatController.text) ?? _customFatGoal;

      setState(() {
        _customCalorieGoal = newCalorieGoal;
        _customProteinGoal = newProteinGoal;
        _customCarbsGoal = newCarbsGoal;
        _customFatGoal = newFatGoal;
      });

      // Save to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userService.updateUserPreferences(
          user.uid,
          dailyCalorieGoal: newCalorieGoal.toInt(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Goals updated successfully!'),
            backgroundColor: kSuccessColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating goals: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: ['Today', '7 Days', '30 Days'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  _loadAnalytics();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelected ? kPrimaryColor : Colors.grey[300],
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(period),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoalsAchievement() {
    if (_analyticsData.isEmpty) return const SizedBox.shrink();

    final totalCalories =
        (_analyticsData['totalCalories'] as num?)?.toDouble() ?? 0.0;
    final totalProtein =
        (_analyticsData['totalProtein'] as num?)?.toDouble() ?? 0.0;
    final totalCarbs =
        (_analyticsData['totalCarbs'] as num?)?.toDouble() ?? 0.0;
    final totalFat = (_analyticsData['totalFat'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: kPrimaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '$_selectedPeriod Goals Achievement',
                      style: kSubheadingStyle,
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _showGoalsDialog,
                    icon: const Icon(Icons.settings, color: kPrimaryColor),
                    tooltip: 'Set Goals',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGoalProgress(
              'Calories',
              totalCalories,
              _customCalorieGoal,
              'kcal',
              Icons.local_fire_department,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildGoalProgress(
              'Protein',
              totalProtein,
              _customProteinGoal,
              'g',
              Icons.fitness_center,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildGoalProgress(
              'Carbs',
              totalCarbs,
              _customCarbsGoal,
              'g',
              Icons.grain,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildGoalProgress(
              'Fat',
              totalFat,
              _customFatGoal,
              'g',
              Icons.opacity,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress(
    String label,
    double current,
    double goal,
    String unit,
    IconData icon,
    Color color,
  ) {
    final percentage = goal > 0 ? (current / goal * 100).clamp(0, 100) : 0.0;
    final remaining = (goal - current).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${current.toStringAsFixed(1)}/${goal.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% achieved',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (remaining > 0)
                Text(
                  '${remaining.toStringAsFixed(1)} $unit remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                )
              else
                Text(
                  '🎉 Goal reached!',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    if (_analyticsData.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.analytics, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No data available for $_selectedPeriod',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start logging meals to see your analytics',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalCalories =
        (_analyticsData['totalCalories'] as num?)?.toDouble() ?? 0.0;
    final totalProtein =
        (_analyticsData['totalProtein'] as num?)?.toDouble() ?? 0.0;
    final totalCarbs =
        (_analyticsData['totalCarbs'] as num?)?.toDouble() ?? 0.0;
    final totalFat = (_analyticsData['totalFat'] as num?)?.toDouble() ?? 0.0;
    final mealCount = (_analyticsData['mealCount'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: kPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  'Nutrition Summary - $_selectedPeriod',
                  style: kSubheadingStyle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Calories',
                    '${totalCalories.toStringAsFixed(0)} kcal',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNutritionCard(
                    'Meals',
                    '$mealCount',
                    Icons.restaurant,
                    kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Protein',
                    '${totalProtein.toStringAsFixed(1)}g',
                    Icons.fitness_center,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNutritionCard(
                    'Carbs',
                    '${totalCarbs.toStringAsFixed(1)}g',
                    Icons.grain,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionCard(
                    'Fat',
                    '${totalFat.toStringAsFixed(1)}g',
                    Icons.opacity,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNutritionCard(
                    'Avg/Day',
                    _selectedPeriod == 'Today'
                        ? '${totalCalories.toStringAsFixed(0)} kcal'
                        : '${(totalCalories / (_selectedPeriod == '7 Days' ? 7 : 30)).toStringAsFixed(0)} kcal',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
        title: const Text('Analytics'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kPrimaryColor),
                  SizedBox(height: 16),
                  Text('Loading analytics...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: kPrimaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildPeriodSelector(),
                    _buildGoalsAchievement(),
                    _buildNutritionSummary(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
