import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Primary Colors
const Color kPrimaryColor = Color(0xFF4CAF50);
const Color kAccentColor = Color(0xFF81C784);
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF333333);
const Color kLightTextColor = Color(0xFF666666);
const Color kErrorColor = Color(0xFFE53E3E);
const Color kWarningColor = Color(0xFFFF8C00);
const Color kSuccessColor = Color(0xFF38A169);

// Text Styles
const TextStyle kHeadingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

const TextStyle kSubheadingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: kTextColor,
);

const TextStyle kBodyStyle = TextStyle(
  fontSize: 16,
  color: kTextColor,
);

const TextStyle kCaptionStyle = TextStyle(
  fontSize: 14,
  color: kLightTextColor,
);

// Spacing
const double kSpacingXS = 4.0;
const double kSpacingSM = 8.0;
const double kSpacingMD = 16.0;
const double kSpacingLG = 24.0;
const double kSpacingXL = 32.0;

// Border Radius
const double kBorderRadius = 12.0;
const double kBorderRadiusLG = 16.0;

// App Configuration
const String kAppName = 'Meal Planner';
const String kAppVersion = '1.0.0';

// API Configuration
String get kSpoonacularApiKey => dotenv.env['SPOONACULAR_API_KEY'] ?? '';
String get kOpenFoodFactsBaseUrl => dotenv.env['OPEN_FOOD_FACTS_BASE_URL'] ?? 'https://world.openfoodfacts.org/api/v0';
// Nutrition Goals (default values)
const double kDefaultDailyCalories = 2000;
const double kDefaultProteinGoal = 125; // grams
const double kDefaultCarbsGoal = 225; // grams
const double kDefaultFatGoal = 67; // grams
const double kDefaultWaterGoal = 2.0; // liters

// Meal Categories
const List<String> kMealCategories = [
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snack',
];

// Diet Types
const List<String> kDietTypes = [
  'None',
  'Vegetarian',
  'Vegan',
  'Keto',
  'Paleo',
  'Mediterranean',
  'Low Carb',
  'Gluten Free',
  'Dairy Free',
];

// Activity Levels
const List<String> kActivityLevels = [
  'Sedentary',
  'Light',
  'Moderate',
  'Active',
  'Very Active',
];

// Common Food Allergies
const List<String> kCommonAllergies = [
  'Nuts',
  'Dairy',
  'Eggs',
  'Shellfish',
  'Fish',
  'Soy',
  'Gluten',
  'Sesame',
  'Peanuts',
];

// App Limits
const int kMaxRecipesPerPage = 20;
const int kMaxMealsPerDay = 50;
const int kMaxFoodNameLength = 100;

// Firebase Collections
const String kUsersCollection = 'users';
const String kMealPlansCollection = 'meal_plans';

// Durations
const Duration kAnimationDuration = Duration(milliseconds: 300);
const Duration kTimeoutDuration = Duration(seconds: 30);

// Error Messages
const String kNetworkError = 'Network error. Please check your connection.';
const String kUnknownError = 'An unknown error occurred. Please try again.';
const String kAuthError =
    'Authentication failed. Please check your credentials.';

// Success Messages
const String kProfileUpdated = 'Profile updated successfully!';
const String kMealAdded = 'Meal added to your plan!';
const String kPasswordChanged = 'Password changed successfully!';
const String kDataSaved = 'Data saved successfully!';
