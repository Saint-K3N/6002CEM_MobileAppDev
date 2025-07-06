import 'package:flutter/material.dart';
import 'screens/home_screen.dart' as home;
import 'screens/meal_planning_screen.dart' as meal_planning;
import 'screens/camera_screen.dart' as camera;
import 'screens/profile_screen.dart' as profile;
import 'screens/recipe_screen.dart' as recipe;
import 'screens/analytics_dashboard.dart' as analytics;

// Local constants
const Color kPrimaryColor = Color(0xFF4CAF50);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // 🔥 Get screen by index
  Widget _getScreenAtIndex(int index) {
    switch (index) {
      case 0:
        return const home.HomeScreen();
      case 1:
        return const recipe.RecipeScreen();
      case 2:
        return const camera.CameraScreen();
      case 3:
        return const meal_planning.MealPlanningScreen();
      case 4:
        return const analytics.AnalyticsDashboard();
      case 5:
        return const profile.ProfileScreen();
      default:
        return const home.HomeScreen();
    }
  }

  // 🔥 Handle tab navigation with auto-redirect for camera
  void _onTabTapped(int index) async {
    if (index == 2) {
      // Camera tab - navigate to camera screen and handle result
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const camera.CameraScreen(),
        ),
      );

      // If meal added successfully, auto switch to Meal Plan tab
      if (result == true && mounted) {
        setState(() {
          _currentIndex = 3; // Meal Plan tab
        });

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('🎉 Meal added! Switched to Meal Plan'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreenAtIndex(_currentIndex),

      // 🔥 Simple BottomNavigationBar - NO MORE OVERFLOW!
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex == 2
            ? 0
            : _currentIndex > 2
                ? _currentIndex - 1
                : _currentIndex,
        onTap: (index) {
          // Adjust index for camera handling
          if (index >= 2) {
            _onTabTapped(index + 1); // Skip camera in normal navigation
          } else {
            _onTabTapped(index);
          }
        },
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 10,
        unselectedFontSize: 9,
        iconSize: 22,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Meal Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),

      // 🔥 Camera FAB positioned on the LEFT side
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onTabTapped(2), // Camera tab
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Scan Food',
        elevation: 6,
        child: const Icon(Icons.camera_alt, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
