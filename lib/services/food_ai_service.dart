import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image/image.dart' as img;
import '../models/nutrition.dart';

class FoodAIService {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static final _imageLabeler = ImageLabeler(options: ImageLabelerOptions());

  static final Map<String, Nutrition> _foodDatabase = {
    // FRUITS
    'apple': const Nutrition(calories: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4, sodium: 2),
    'banana': const Nutrition(calories: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3, sodium: 1),
    'orange': const Nutrition(calories: 47, protein: 0.9, carbs: 12, fat: 0.1, fiber: 2.4, sodium: 0),
    'strawberry': const Nutrition(calories: 32, protein: 0.7, carbs: 8, fat: 0.3, fiber: 2, sodium: 1),
    'grapes': const Nutrition(calories: 67, protein: 0.6, carbs: 17, fat: 0.2, fiber: 0.9, sodium: 2),
    'mango': const Nutrition(calories: 60, protein: 0.8, carbs: 15, fat: 0.4, fiber: 1.6, sodium: 1),
    'pineapple': const Nutrition(calories: 50, protein: 0.5, carbs: 13, fat: 0.1, fiber: 1.4, sodium: 1),
    'watermelon': const Nutrition(calories: 30, protein: 0.6, carbs: 8, fat: 0.2, fiber: 0.4, sodium: 1),

    // VEGETABLES
    'broccoli': const Nutrition(calories: 25, protein: 3, carbs: 5, fat: 0.3, fiber: 2.6, sodium: 33),
    'carrot': const Nutrition(calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8, sodium: 69),
    'spinach': const Nutrition(calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, sodium: 79),
    'tomato': const Nutrition(calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2, sodium: 5),
    'potato': const Nutrition(calories: 77, protein: 2, carbs: 17, fat: 0.1, fiber: 2.2, sodium: 6),
    'onion': const Nutrition(calories: 40, protein: 1.1, carbs: 9, fat: 0.1, fiber: 1.7, sodium: 4),
    'lettuce': const Nutrition(calories: 15, protein: 1.4, carbs: 3, fat: 0.2, fiber: 1.3, sodium: 28),

    // PROTEINS
    'chicken': const Nutrition(calories: 231, protein: 43.5, carbs: 0, fat: 5.0, fiber: 0, sodium: 74),
    'beef': const Nutrition(calories: 271, protein: 27, carbs: 0, fat: 17, fiber: 0, sodium: 56),
    'salmon': const Nutrition(calories: 208, protein: 22, carbs: 0, fat: 12, fiber: 0, sodium: 59),
    'egg': const Nutrition(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0, sodium: 124),
    'tofu': const Nutrition(calories: 76, protein: 8.1, carbs: 1.9, fat: 4.8, fiber: 0.3, sodium: 7),
    'fish': const Nutrition(calories: 140, protein: 25, carbs: 0, fat: 4, fiber: 0, sodium: 80),
    'pork': const Nutrition(calories: 242, protein: 23, carbs: 0, fat: 16, fiber: 0, sodium: 62),

    // GRAINS & CARBS
    'rice': const Nutrition(calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4, sodium: 1),
    'bread': const Nutrition(calories: 265, protein: 9, carbs: 49, fat: 3.2, fiber: 2.7, sodium: 477),
    'pasta': const Nutrition(calories: 220, protein: 8, carbs: 44, fat: 1, fiber: 3, sodium: 6),
    'quinoa': const Nutrition(calories: 120, protein: 4.4, carbs: 22, fat: 1.9, fiber: 2.8, sodium: 7),
    'oats': const Nutrition(calories: 68, protein: 2.4, carbs: 12, fat: 1.4, fiber: 1.7, sodium: 49),
    'noodles': const Nutrition(calories: 138, protein: 4.5, carbs: 25, fat: 0.9, fiber: 1.8, sodium: 6),

    // POPULAR DISHES
    'pizza': const Nutrition(calories: 285, protein: 12, carbs: 36, fat: 10, fiber: 2, sodium: 640),
    'burger': const Nutrition(calories: 540, protein: 25, carbs: 40, fat: 31, fiber: 3, sodium: 1040),
    'sandwich': const Nutrition(calories: 320, protein: 15, carbs: 42, fat: 12, fiber: 3, sodium: 680),
    'salad': const Nutrition(calories: 150, protein: 6, carbs: 12, fat: 10, fiber: 4, sodium: 420),
    'soup': const Nutrition(calories: 120, protein: 6, carbs: 15, fat: 4, fiber: 2, sodium: 480),
    'curry': const Nutrition(calories: 300, protein: 20, carbs: 18, fat: 18, fiber: 4, sodium: 580),

    // ASIAN FOODS
    'sushi': const Nutrition(calories: 200, protein: 9, carbs: 30, fat: 5, fiber: 1, sodium: 320),
    'ramen': const Nutrition(calories: 450, protein: 20, carbs: 65, fat: 15, fiber: 4, sodium: 1200),
    'fried rice': const Nutrition(calories: 300, protein: 12, carbs: 42, fat: 10, fiber: 2, sodium: 420),
    'nasi lemak': const Nutrition(calories: 350, protein: 12, carbs: 45, fat: 15, fiber: 3, sodium: 420),
    'rendang': const Nutrition(calories: 468, protein: 28, carbs: 8, fat: 35, fiber: 2, sodium: 380),
    'pad thai': const Nutrition(calories: 320, protein: 14, carbs: 40, fat: 12, fiber: 3, sodium: 580),

    // DAIRY
    'milk': const Nutrition(calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, fiber: 0, sodium: 43),
    'cheese': const Nutrition(calories: 403, protein: 25, carbs: 1.3, fat: 33, fiber: 0, sodium: 621),
    'yogurt': const Nutrition(calories: 100, protein: 17, carbs: 6, fat: 0.7, fiber: 0, sodium: 60),

    // SNACKS
    'nuts': const Nutrition(calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12, sodium: 1),
    'chocolate': const Nutrition(calories: 534, protein: 8, carbs: 59, fat: 30, fiber: 11, sodium: 24),
    'cookies': const Nutrition(calories: 480, protein: 7, carbs: 65, fat: 20, fiber: 2, sodium: 320),
  };

  //  MAIN FOOD RECOGNITION FUNCTION
  static Future<Map<String, dynamic>?> recognizeFood(String imagePath) async {
    try {
      print('🔍 Starting Google ML Kit food recognition...');

      // Step 1: Try text recognition (for food labels/packaging)
      final textResult = await _recognizeTextInImage(imagePath);
      if (textResult != null) {
        print('✅ Text recognition successful: ${textResult['foodName']}');
        return textResult;
      }

      // Step 2: Try image labeling (for general object recognition)
      final labelResult = await _recognizeImageLabels(imagePath);
      if (labelResult != null) {
        print('✅ Image labeling successful: ${labelResult['foodName']}');
        return labelResult;
      }

      // Step 3: Enhanced filename analysis
      final filenameResult = _analyzeFilename(imagePath);
      if (filenameResult != null) {
        print('✅ Filename analysis successful: ${filenameResult['foodName']}');
        return filenameResult;
      }

      // Step 4: Smart fallback
      print('⚠️ Using smart fallback recognition');
      return _getSmartFallbackFood();

    } catch (e) {
      print('❌ Error in ML Kit recognition: $e');
      return _getSmartFallbackFood();
    }
  }

  // TEXT RECOGNITION (for food labels, menus, packaging)
  static Future<Map<String, dynamic>?> _recognizeTextInImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final detectedText = recognizedText.text.toLowerCase();
      print('📝 Detected text: $detectedText');

      if (detectedText.isEmpty) {
        return null;
      }

      // Search for food names in detected text
      for (final entry in _foodDatabase.entries) {
        final foodName = entry.key;
        final nutrition = entry.value;

        // Check for exact matches or partial matches
        if (detectedText.contains(foodName) ||
            _containsKeywords(detectedText, foodName)) {
          return {
            'foodName': _formatFoodName(foodName),
            'nutrition': nutrition,
            'confidence': 0.9,
            'source': 'Google ML Kit Text Recognition',
            'detectedText': detectedText,
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Text recognition error: $e');
      return null;
    }
  }

  // 🏷️ IMAGE LABELING (for general object recognition)
  static Future<Map<String, dynamic>?> _recognizeImageLabels(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);

      print('🏷️ Detected labels: ${labels.map((l) => '${l.label} (${l.confidence.toStringAsFixed(2)})').join(', ')}');

      if (labels.isEmpty) {
        return null;
      }

      // Look for food-related labels
      for (final label in labels) {
        if (label.confidence > 0.7) {
          final labelText = label.label.toLowerCase();

          // Direct match
          if (_foodDatabase.containsKey(labelText)) {
            return {
              'foodName': _formatFoodName(labelText),
              'nutrition': _foodDatabase[labelText],
              'confidence': label.confidence,
              'source': 'Google ML Kit Image Labeling',
              'allLabels': labels.map((l) => l.label).toList(),
            };
          }

          // Partial match
          for (final entry in _foodDatabase.entries) {
            if (entry.key.contains(labelText) || labelText.contains(entry.key)) {
              return {
                'foodName': _formatFoodName(entry.key),
                'nutrition': entry.value,
                'confidence': label.confidence * 0.8,
                'source': 'Google ML Kit Image Labeling (Partial)',
                'matchedLabel': label.label,
              };
            }
          }

          // Look for food-related terms
          final foodTerms = ['food', 'fruit', 'vegetable', 'meat', 'dish', 'meal', 'snack'];
          if (foodTerms.any((term) => labelText.contains(term))) {
            // Return a generic food based on the category
            return _getCategoryBasedFood(labelText);
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Image labeling error: $e');
      return null;
    }
  }

  // 📁 ENHANCED FILENAME ANALYSIS
  static Map<String, dynamic>? _analyzeFilename(String imagePath) {
    final fileName = imagePath.split('/').last.toLowerCase();

    for (final entry in _foodDatabase.entries) {
      final foodName = entry.key;

      // Direct filename match
      if (fileName.contains(foodName.replaceAll(' ', '')) ||
          fileName.contains(foodName.replaceAll(' ', '_'))) {
        return {
          'foodName': _formatFoodName(foodName),
          'nutrition': entry.value,
          'confidence': 0.85,
          'source': 'Filename Analysis',
        };
      }

      // Keyword match
      final keywords = foodName.split(' ');
      for (final keyword in keywords) {
        if (keyword.length > 3 && fileName.contains(keyword)) {
          return {
            'foodName': _formatFoodName(foodName),
            'nutrition': entry.value,
            'confidence': 0.75,
            'source': 'Filename Keyword Match',
          };
        }
      }
    }

    return null;
  }

  // SMART FALLBACK
  static Map<String, dynamic> _getSmartFallbackFood() {
    final commonFoods = [
      'apple', 'banana', 'chicken', 'rice', 'bread', 'egg', 'salmon',
      'pasta', 'pizza', 'sandwich', 'salad', 'soup'
    ];

    final random = Random();
    final selectedFood = commonFoods[random.nextInt(commonFoods.length)];

    return {
      'foodName': _formatFoodName(selectedFood),
      'nutrition': _foodDatabase[selectedFood]!,
      'confidence': 0.6,
      'source': 'Smart Fallback',
      'note': 'Could not identify food precisely. Please verify and edit if needed.',
    };
  }

  // 🏷CATEGORY-BASED FOOD SELECTION
  static Map<String, dynamic> _getCategoryBasedFood(String category) {
    final categoryMap = {
      'fruit': ['apple', 'banana', 'orange', 'strawberry'],
      'vegetable': ['broccoli', 'carrot', 'spinach', 'tomato'],
      'meat': ['chicken', 'beef', 'salmon', 'pork'],
      'food': ['rice', 'bread', 'pasta', 'pizza'],
    };

    for (final entry in categoryMap.entries) {
      if (category.contains(entry.key)) {
        final foods = entry.value;
        final selectedFood = foods[Random().nextInt(foods.length)];
        return {
          'foodName': _formatFoodName(selectedFood),
          'nutrition': _foodDatabase[selectedFood]!,
          'confidence': 0.7,
          'source': 'Category-Based Recognition',
          'category': entry.key,
        };
      }
    }

    return _getSmartFallbackFood();
  }

  // HELPER FUNCTIONS
  static bool _containsKeywords(String text, String foodName) {
    final foodKeywords = foodName.split(' ');
    return foodKeywords.any((keyword) =>
    keyword.length > 2 && text.contains(keyword));
  }

  static String _formatFoodName(String rawName) {
    return rawName.split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // CLEANUP
  static void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
  }

  // SEARCH FUNCTION
  static Nutrition? searchFoodInDatabase(String query) {
    final normalizedQuery = query.toLowerCase().trim();

    // Direct match
    if (_foodDatabase.containsKey(normalizedQuery)) {
      return _foodDatabase[normalizedQuery];
    }

    // Partial match
    for (final entry in _foodDatabase.entries) {
      if (entry.key.contains(normalizedQuery) ||
          normalizedQuery.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  //  GET FOOD DATABASE INFO
  static int get totalFoodsCount => _foodDatabase.length;

  static List<String> getAllFoodNames() {
    return _foodDatabase.keys.toList()..sort();
  }

  static List<String> searchFoodNames(String query) {
    final normalizedQuery = query.toLowerCase();
    return _foodDatabase.keys
        .where((food) => food.toLowerCase().contains(normalizedQuery))
        .toList();
  }
}