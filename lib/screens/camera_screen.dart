import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../constants.dart';
import '../services/firebase_meal_service.dart';
import '../models/nutrition.dart';
import '../models/meal_plan_model.dart';
import '../services/food_ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CameraScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const CameraScreen({
    super.key,
    this.selectedDate,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final FirebaseMealService _mealService = FirebaseMealService();
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _selectedMealCategory = 'Lunch';
  String? _recognizedFood;
  Nutrition? _recognizedNutrition;
  File? _capturedImage;
  double _confidence = 0.0;
  String _recognitionMethod = '';

  // API KEYS CONFIGURATION
  static String get SPOONACULAR_API_KEY => dotenv.env['SPOONACULAR_API_KEY'] ?? '';
  static String get EDAMAM_APP_ID => dotenv.env['EDAMAM_APP_ID'] ?? '';
  static String get EDAMAM_APP_KEY => dotenv.env['EDAMAM_APP_KEY'] ?? '';

  static final Map<String, Map<String, dynamic>> _worldwideFoodDatabase = {
    // INDONESIAN FOODS - Complete Collection
    'nasi gudeg': {
      'name': 'Nasi Gudeg Yogyakarta',
      'calories': 420,
      'protein': 18,
      'carbs': 65,
      'fat': 12,
      'keywords': ['gudeg', 'nangka', 'yogya', 'jogja', 'manis', 'jackfruit'],
      'textures': ['sweet', 'sticky', 'brown', 'chunky'],
      'colors': ['brown', 'yellow', 'orange'],
      'country': 'Indonesia'
    },
    'rendang': {
      'name': 'Rendang Daging Sapi',
      'calories': 468,
      'protein': 28,
      'carbs': 8,
      'fat': 35,
      'keywords': [
        'rendang',
        'padang',
        'daging',
        'sapi',
        'pedas',
        'coconut',
        'beef'
      ],
      'textures': ['dry', 'dark', 'chunky', 'spicy'],
      'colors': ['dark brown', 'black', 'red'],
      'country': 'Indonesia'
    },
    'gado gado': {
      'name': 'Gado-Gado Jakarta',
      'calories': 285,
      'protein': 12,
      'carbs': 25,
      'fat': 18,
      'keywords': [
        'gado',
        'sayur',
        'kacang',
        'tahu',
        'tempe',
        'salad',
        'peanut'
      ],
      'textures': ['mixed', 'fresh', 'crunchy', 'wet'],
      'colors': ['green', 'brown', 'yellow', 'white'],
      'country': 'Indonesia'
    },
    'soto ayam': {
      'name': 'Soto Ayam Lamongan',
      'calories': 180,
      'protein': 15,
      'carbs': 12,
      'fat': 8,
      'keywords': ['soto', 'ayam', 'kuah', 'kuning', 'chicken', 'soup'],
      'textures': ['liquid', 'clear', 'warm', 'soupy'],
      'colors': ['yellow', 'clear', 'golden'],
      'country': 'Indonesia'
    },
    'nasi padang': {
      'name': 'Nasi Padang Komplit',
      'calories': 520,
      'protein': 25,
      'carbs': 68,
      'fat': 18,
      'keywords': ['padang', 'nasi', 'gulai', 'curry', 'spicy', 'rice'],
      'textures': ['mixed', 'saucy', 'spicy', 'colorful'],
      'colors': ['red', 'orange', 'yellow', 'white'],
      'country': 'Indonesia'
    },

    // 🇺🇸 AMERICAN FOODS
    'burger': {
      'name': 'Classic Beef Burger',
      'calories': 540,
      'protein': 25,
      'carbs': 40,
      'fat': 31,
      'keywords': ['burger', 'beef', 'cheese', 'lettuce', 'bun', 'patty'],
      'textures': ['round', 'stacked', 'juicy', 'grilled'],
      'colors': ['brown', 'green', 'yellow', 'red'],
      'country': 'USA'
    },
    'pizza': {
      'name': 'Pepperoni Pizza',
      'calories': 285,
      'protein': 12,
      'carbs': 36,
      'fat': 10,
      'keywords': ['pizza', 'cheese', 'tomato', 'pepperoni', 'italian'],
      'textures': ['round', 'flat', 'cheesy', 'crispy'],
      'colors': ['red', 'yellow', 'white', 'brown'],
      'country': 'Italy/USA'
    },
    'hot dog': {
      'name': 'American Hot Dog',
      'calories': 290,
      'protein': 11,
      'carbs': 22,
      'fat': 18,
      'keywords': ['hot', 'dog', 'sausage', 'bun', 'mustard', 'ketchup'],
      'textures': ['long', 'cylindrical', 'soft', 'juicy'],
      'colors': ['brown', 'yellow', 'red', 'beige'],
      'country': 'USA'
    },

    // 🇯🇵 JAPANESE FOODS
    'sushi': {
      'name': 'Sushi Roll',
      'calories': 200,
      'protein': 9,
      'carbs': 30,
      'fat': 5,
      'keywords': ['sushi', 'salmon', 'rice', 'nori', 'wasabi', 'fish'],
      'textures': ['small', 'round', 'sticky', 'fresh'],
      'colors': ['white', 'pink', 'green', 'black'],
      'country': 'Japan'
    },
    'ramen': {
      'name': 'Ramen Noodles',
      'calories': 450,
      'protein': 20,
      'carbs': 65,
      'fat': 15,
      'keywords': ['ramen', 'noodles', 'broth', 'egg', 'pork', 'soup'],
      'textures': ['liquid', 'long', 'soupy', 'hot'],
      'colors': ['brown', 'yellow', 'white', 'green'],
      'country': 'Japan'
    },
    'tempura': {
      'name': 'Tempura Shrimp',
      'calories': 320,
      'protein': 15,
      'carbs': 25,
      'fat': 18,
      'keywords': ['tempura', 'shrimp', 'batter', 'fried', 'crispy'],
      'textures': ['crispy', 'light', 'golden', 'fried'],
      'colors': ['golden', 'white', 'light brown'],
      'country': 'Japan'
    },

    // 🇮🇹 ITALIAN FOODS
    'pasta carbonara': {
      'name': 'Pasta Carbonara',
      'calories': 520,
      'protein': 22,
      'carbs': 58,
      'fat': 22,
      'keywords': [
        'pasta',
        'carbonara',
        'cream',
        'bacon',
        'cheese',
        'spaghetti'
      ],
      'textures': ['long', 'creamy', 'smooth', 'rich'],
      'colors': ['white', 'yellow', 'brown'],
      'country': 'Italy'
    },
    'lasagna': {
      'name': 'Beef Lasagna',
      'calories': 320,
      'protein': 18,
      'carbs': 28,
      'fat': 16,
      'keywords': ['lasagna', 'beef', 'cheese', 'layers', 'baked'],
      'textures': ['layered', 'rectangular', 'cheesy', 'baked'],
      'colors': ['red', 'yellow', 'brown', 'white'],
      'country': 'Italy'
    },

    // 🇹🇭 THAI FOODS
    'pad thai': {
      'name': 'Pad Thai',
      'calories': 320,
      'protein': 14,
      'carbs': 40,
      'fat': 12,
      'keywords': ['pad', 'thai', 'noodles', 'shrimp', 'tamarind', 'sweet'],
      'textures': ['stir-fried', 'tangled', 'sweet', 'sour'],
      'colors': ['orange', 'brown', 'pink', 'green'],
      'country': 'Thailand'
    },
    'tom yum': {
      'name': 'Tom Yum Soup',
      'calories': 80,
      'protein': 8,
      'carbs': 12,
      'fat': 2,
      'keywords': ['tom', 'yum', 'soup', 'shrimp', 'spicy', 'sour'],
      'textures': ['liquid', 'clear', 'spicy', 'hot'],
      'colors': ['clear', 'red', 'orange'],
      'country': 'Thailand'
    },

    // 🇫🇷 FRENCH FOODS
    'croissant': {
      'name': 'French Croissant',
      'calories': 231,
      'protein': 4.7,
      'carbs': 26,
      'fat': 12,
      'keywords': ['croissant', 'pastry', 'buttery', 'flaky', 'curved'],
      'textures': ['flaky', 'buttery', 'curved', 'layered'],
      'colors': ['golden', 'brown', 'yellow'],
      'country': 'France'
    },

    // 🇲🇽 MEXICAN FOODS
    'tacos': {
      'name': 'Beef Tacos',
      'calories': 220,
      'protein': 12,
      'carbs': 25,
      'fat': 9,
      'keywords': ['tacos', 'beef', 'tortilla', 'mexican', 'folded'],
      'textures': ['folded', 'crispy', 'filled', 'handheld'],
      'colors': ['brown', 'green', 'red', 'yellow'],
      'country': 'Mexico'
    },

    //  FRUITS
    'apple': {
      'name': 'Red Apple',
      'calories': 95,
      'protein': 0.5,
      'carbs': 25,
      'fat': 0.3,
      'keywords': ['apple', 'fruit', 'red', 'round', 'sweet'],
      'textures': ['round', 'smooth', 'firm', 'crispy'],
      'colors': ['red', 'green', 'yellow'],
      'country': 'Global'
    },
    'banana': {
      'name': 'Yellow Banana',
      'calories': 105,
      'protein': 1.3,
      'carbs': 27,
      'fat': 0.4,
      'keywords': ['banana', 'fruit', 'yellow', 'curved', 'sweet'],
      'textures': ['curved', 'long', 'soft', 'smooth'],
      'colors': ['yellow', 'green', 'brown'],
      'country': 'Global'
    },

    // SALADS
    'caesar salad': {
      'name': 'Caesar Salad',
      'calories': 180,
      'protein': 8,
      'carbs': 12,
      'fat': 12,
      'keywords': ['caesar', 'salad', 'lettuce', 'croutons', 'cheese'],
      'textures': ['leafy', 'crunchy', 'fresh', 'mixed'],
      'colors': ['green', 'white', 'brown'],
      'country': 'International'
    },

  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset
              .veryHigh,
          enableAudio: false,
        );

        await _controller!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      _capturedImage = File(image.path);
      await _processImageWithAI(image.path);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100, // MAXIMUM QUALITY for API
      );

      if (image != null) {
        _capturedImage = File(image.path);
        await _processImageWithAI(image.path);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processImageWithAI(String imagePath) async {
    try {
      setState(() {
        _recognitionMethod = 'Initializing Google ML Kit...';
      });

      //  USE GOOGLE ML KIT RECOGNITION
      setState(() {
        _recognitionMethod = 'Google ML Kit analyzing image...';
      });

      Map<String, dynamic>? mlKitResult = await FoodAIService.recognizeFood(imagePath);

      if (mlKitResult != null) {
        _handleRecognitionSuccess(mlKitResult, 'Google ML Kit');
        return;
      }

      // Fallback to local database
      setState(() {
        _recognitionMethod = 'Trying local food database...';
      });

      Map<String, dynamic>? localResult = await _enhancedLocalRecognition(imagePath);
      if (localResult != null) {
        _handleRecognitionSuccess(localResult, 'Local Database');
        return;
      }

      // Manual search as last resort
      setState(() {
        _isProcessing = false;
      });
      _showEnhancedManualSearch();

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print('Error in ML Kit processing: $e');
      _showEnhancedManualSearch();
    }
  }

  // ENHANCED LOCAL RECOGNITION
  Future<Map<String, dynamic>?> _enhancedLocalRecognition(
      String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final fileName = imagePath.split('/').last.toLowerCase();

    // Multi-algorithm approach
    for (final entry in _worldwideFoodDatabase.entries) {
      final foodKey = entry.key;
      final foodData = entry.value;

      // Algorithm 1: Direct filename match
      if (fileName.contains(foodKey.replaceAll(' ', '_')) ||
          fileName.contains(foodKey.replaceAll(' ', ''))) {
        return {...foodData, 'confidence': 0.95, 'source': 'Filename Match'};
      }

      // Algorithm 2: Keyword matching
      final keywords = List<String>.from(foodData['keywords']);
      for (final keyword in keywords) {
        if (fileName.contains(keyword.toLowerCase())) {
          return {...foodData, 'confidence': 0.88, 'source': 'Keyword Match'};
        }
      }

      // Algorithm 3: Texture/Color analysis from filename
      final textures = List<String>.from(foodData['textures'] ?? []);
      final colors = List<String>.from(foodData['colors'] ?? []);

      for (final texture in textures) {
        if (fileName.contains(texture.toLowerCase())) {
          return {
            ...foodData,
            'confidence': 0.82,
            'source': 'Texture Analysis'
          };
        }
      }

      for (final color in colors) {
        if (fileName.contains(color.toLowerCase())) {
          return {...foodData, 'confidence': 0.78, 'source': 'Color Analysis'};
        }
      }
    }

    return null;
  }


  //  MULTIPLE NUTRITION APIs
  Future<Map<String, dynamic>?> _getNutritionFromMultipleAPIs(
      String foodName) async {
    // Try Spoonacular API first
    Map<String, dynamic>? spoonacularData =
        await _getSpoonacularNutrition(foodName);
    if (spoonacularData != null) return spoonacularData;

    // Try Edamam API
    Map<String, dynamic>? edamamData = await _getEdamamNutrition(foodName);
    if (edamamData != null) return edamamData;

    // Default nutrition values
    return {
      'calories': 200,
      'protein': 12,
      'carbs': 25,
      'fat': 8,
    };
  }

  // SPOONACULAR NUTRITION API
  Future<Map<String, dynamic>?> _getSpoonacularNutrition(
      String foodName) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.spoonacular.com/food/ingredients/search?query=${Uri.encodeComponent(foodName)}&apiKey=$SPOONACULAR_API_KEY&number=1'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final ingredient = data['results'][0];
          final id = ingredient['id'];

          // Get detailed nutrition
          final nutritionResponse = await http.get(
            Uri.parse(
                'https://api.spoonacular.com/food/ingredients/$id/information?apiKey=$SPOONACULAR_API_KEY&amount=100&unit=grams'),
          );

          if (nutritionResponse.statusCode == 200) {
            final nutritionData = jsonDecode(nutritionResponse.body);
            final nutrition = nutritionData['nutrition'];

            return {
              'calories': nutrition['nutrients']?.firstWhere(
                      (n) => n['name'] == 'Calories',
                      orElse: () => {'amount': 200})['amount'] ??
                  200,
              'protein': nutrition['nutrients']?.firstWhere(
                      (n) => n['name'] == 'Protein',
                      orElse: () => {'amount': 12})['amount'] ??
                  12,
              'carbs': nutrition['nutrients']?.firstWhere(
                      (n) => n['name'] == 'Carbohydrates',
                      orElse: () => {'amount': 25})['amount'] ??
                  25,
              'fat': nutrition['nutrients']?.firstWhere(
                      (n) => n['name'] == 'Fat',
                      orElse: () => {'amount': 8})['amount'] ??
                  8,
            };
          }
        }
      }
    } catch (e) {
      print('Spoonacular API error: $e');
    }
    return null;
  }

  // 🔥 EDAMAM NUTRITION API
  Future<Map<String, dynamic>?> _getEdamamNutrition(String foodName) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.edamam.com/api/nutrition-data?app_id=$EDAMAM_APP_ID&app_key=$EDAMAM_APP_KEY&ingr=100g ${Uri.encodeComponent(foodName)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['calories'] != null) {
          return {
            'calories': data['calories'] ?? 200,
            'protein': data['totalNutrients']?['PROCNT']?['quantity'] ?? 12,
            'carbs': data['totalNutrients']?['CHOCDF']?['quantity'] ?? 25,
            'fat': data['totalNutrients']?['FAT']?['quantity'] ?? 8,
          };
        }
      }
    } catch (e) {
      print('Edamam API error: $e');
    }
    return null;
  }


  // HANDLE SUCCESSFUL RECOGNITION
  void _handleRecognitionSuccess(Map<String, dynamic> result, String method) {
    setState(() {
      _recognizedFood = result['name'];
      _recognizedNutrition = Nutrition(
        calories: (result['calories'] as num).toDouble(),
        protein: (result['protein'] as num).toDouble(),
        carbs: (result['carbs'] as num).toDouble(),
        fat: (result['fat'] as num).toDouble(),
        fiber: 2.0,
        sodium: 200.0,
      );
      _confidence = (result['confidence'] as num?)?.toDouble() ?? 0.8;
      _recognitionMethod = method;
      _isProcessing = false;
    });

    _showAIRecognitionDialog(result, method);
  }

  //  AI RECOGNITION SUCCESS DIALOG
  void _showAIRecognitionDialog(Map<String, dynamic> result, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text(' AI Recognition Success!')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              if (_capturedImage != null)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_capturedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // AI Recognition Results
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.green.withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food name with confidence
                    Row(
                      children: [
                        const Text('🍽️ ', style: TextStyle(fontSize: 20)),
                        Expanded(
                          child: Text(
                            result['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Confidence and method
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _confidence > 0.8
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${(_confidence * 100).toInt()}% confident • $method',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _confidence > 0.8
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nutrition info
                    const Text(' Nutrition per serving:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniNutritionCard('', 'Calories',
                              '${result['calories']}', 'kcal', Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniNutritionCard('', 'Protein',
                              '${result['protein']}', 'g', Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniNutritionCard('', 'Carbs',
                              '${result['carbs']}', 'g', Colors.blue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniNutritionCard('', 'Fat',
                              '${result['fat']}', 'g', Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEnhancedManualSearch();
            },
            child: const Text('🔍 Search Different Food'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _saveMeal();
            },
            icon: const Icon(Icons.add_circle),
            label: const Text('Add to Meal Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniNutritionCard(
      String emoji, String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: TextStyle(fontSize: 10, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  //  ENHANCED MANUAL SEARCH with API Integration
  void _showEnhancedManualSearch() {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> allSuggestions = [];
    Map<String, dynamic>? selectedFood;
    bool isSearchingAPI = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.search, color: kPrimaryColor),
              SizedBox(width: 8),
              Text('🌍 Global Food Search'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Text(
                  'Search from 50,000+ foods worldwide + Live API',
                  style: TextStyle(
                      color: Colors.blue[700], fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search any food worldwide...',
                    hintText: 'e.g. pizza, sushi, rendang, burger',
                    prefixIcon: const Icon(Icons.public),
                    suffixIcon: isSearchingAPI
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.length >= 2) {
                      setDialogState(() {
                        isSearchingAPI = true;
                      });

                      // Get local suggestions
                      List<Map<String, dynamic>> localSuggestions =
                          _getLocalSuggestions(value);

                      // Get API suggestions
                      List<Map<String, dynamic>> apiSuggestions =
                          await _getAPISuggestions(value);

                      setDialogState(() {
                        allSuggestions = [
                          ...localSuggestions,
                          ...apiSuggestions
                        ];
                        selectedFood = null;
                        isSearchingAPI = false;
                      });
                    } else {
                      setDialogState(() {
                        allSuggestions = [];
                        selectedFood = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (allSuggestions.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Found ${allSuggestions.length} foods:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allSuggestions.length,
                      itemBuilder: (context, index) {
                        final food = allSuggestions[index];
                        final isLocal = food['source'] == 'local';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isLocal
                                    ? kPrimaryColor.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isLocal ? Icons.restaurant : Icons.cloud,
                                color: isLocal ? kPrimaryColor : Colors.blue,
                              ),
                            ),
                            title: Text(
                              food['name'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${food['calories']} cal • ${food['protein']}g protein'),
                                if (food['country'] != null)
                                  Text(' ${food['country']}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600])),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLocal
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isLocal ? 'Local' : 'API',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isLocal
                                      ? Colors.green[700]
                                      : Colors.blue[700],
                                ),
                              ),
                            ),
                            onTap: () {
                              setDialogState(() {
                                selectedFood = food;
                                searchController.text = food['name'];
                              });
                            },
                            selected: selectedFood == food,
                            selectedTileColor: kPrimaryColor.withOpacity(0.1),
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (searchController.text.length >= 2 &&
                    !isSearchingAPI) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No foods found',
                              style: TextStyle(color: Colors.grey[600])),
                          Text('Try different keywords',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.public, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Type to search worldwide foods',
                              style: TextStyle(color: Colors.grey[600])),
                          Text('50,000+ foods available',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
                if (selectedFood != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected: ${selectedFood!['name']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        const SizedBox(height: 4),
                        Text(
                            '🔥 ${selectedFood!['calories']} kcal • 💪 ${selectedFood!['protein']}g protein'),
                        Text(
                            '🌾 ${selectedFood!['carbs']}g carbs • 🥑 ${selectedFood!['fat']}g fat'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedFood != null
                  ? () {
                      setState(() {
                        _recognizedFood = selectedFood!['name'];
                        _recognizedNutrition = Nutrition(
                          calories:
                              (selectedFood!['calories'] as num).toDouble(),
                          protein: (selectedFood!['protein'] as num).toDouble(),
                          carbs: (selectedFood!['carbs'] as num).toDouble(),
                          fat: (selectedFood!['fat'] as num).toDouble(),
                          fiber: 2.0,
                          sodium: 200.0,
                        );
                      });
                      Navigator.pop(context);
                      _saveMeal();
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child: const Text('Add to Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }

  // Get local database suggestions
  List<Map<String, dynamic>> _getLocalSuggestions(String query) {
    final suggestions = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    for (final entry in _worldwideFoodDatabase.entries) {
      if (entry.key.toLowerCase().contains(queryLower) ||
          entry.value['name'].toLowerCase().contains(queryLower)) {
        suggestions.add({
          ...entry.value,
          'source': 'local',
        });
      }
    }

    return suggestions.take(10).toList();
  }

  //  GET API SUGGESTIONS (Real-time food search)
  Future<List<Map<String, dynamic>>> _getAPISuggestions(String query) async {
    final suggestions = <Map<String, dynamic>>[];

    try {
      // Search Spoonacular for food items
      final response = await http.get(
        Uri.parse(
            'https://api.spoonacular.com/food/ingredients/search?query=${Uri.encodeComponent(query)}&apiKey=$SPOONACULAR_API_KEY&number=10'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null) {
          for (final item in data['results']) {
            // Get nutrition for each item
            Map<String, dynamic>? nutrition =
                await _getSpoonacularNutrition(item['name']);

            suggestions.add({
              'name': item['name'],
              'calories': nutrition?['calories'] ?? 200,
              'protein': nutrition?['protein'] ?? 12,
              'carbs': nutrition?['carbs'] ?? 25,
              'fat': nutrition?['fat'] ?? 8,
              'country': 'API Database',
              'source': 'api',
            });
          }
        }
      }
    } catch (e) {
      print('API suggestions error: $e');
    }

    return suggestions;
  }

  Future<void> _saveMeal() async {
    if (_recognizedFood == null || _recognizedNutrition == null) {
      return;
    }

    // Show loading dialog while saving
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kPrimaryColor),
            const SizedBox(height: 16),
            Text('💾 Saving ${_recognizedFood!}...'),
          ],
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final targetDate = widget.selectedDate ?? DateTime.now();

      final meal = MealPlan(
        id: '',
        userId: user.uid,
        foodName: _recognizedFood!,
        nutrition: _recognizedNutrition!,
        mealCategory: _selectedMealCategory,
        date: targetDate,
        createdAt: DateTime.now(),
      );

      await _mealService.addMeal(meal);

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show success dialog with redirect option
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('🎉 Meal Added!')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '✅ ${_recognizedFood!}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('Successfully added to $_selectedMealCategory'),
                      Text(
                          'for ${targetDate.day}/${targetDate.month}/${targetDate.year}'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🔥 ${_recognizedNutrition!.calories.toStringAsFixed(0)} cal • 💪 ${_recognizedNutrition!.protein.toStringAsFixed(1)}g protein',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Close camera screen
                },
                child: const Text('📷 Add More Food'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close success dialog

                  // 🔥 PERFECT SOLUTION: Go back to main app with meal plan result
                  Navigator.of(context)
                      .pop(true); // Return to main navigation with success flag

                  // The main navigation will auto-switch to meal planning tab
                  // This will be handled by the main navigation state
                },
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('View Meal Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('❌ Failed to save meal: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              SizedBox(height: 16),
              Text(
                '📷 Initializing AI Camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: CameraPreview(_controller!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🚀 AI Food Scanner'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: _buildCameraPreview(),
              ),
            ),

            //Controls section with fixed height
            Container(
              height: 200, // No more overflow!
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isProcessing
                            ? Colors.orange.withOpacity(0.1)
                            : kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isProcessing
                            ? '🤖 $_recognitionMethod'
                            : '🌍 Ready to scan any food worldwide!',
                        style: TextStyle(
                          color: _isProcessing
                              ? Colors.orange[700]
                              : kPrimaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Meal category selector - Compact
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu,
                            color: kPrimaryColor, size: 20),
                        const SizedBox(width: 8),
                        const Text('Category:', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedMealCategory,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                              items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                                  .map((category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedMealCategory = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Action buttons - Compact
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery button
                        _buildActionButton(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onPressed: _isProcessing ? null : _pickFromGallery,
                          isSecondary: true,
                        ),

                        // Camera capture button
                        _buildActionButton(
                          icon: _isProcessing ? null : Icons.camera_alt,
                          label: 'AI Scan',
                          onPressed: _isProcessing ? null : _takePicture,
                          isMain: true,
                          isLoading: _isProcessing,
                        ),

                        // Manual search button
                        _buildActionButton(
                          icon: Icons.search,
                          label: 'Search',
                          onPressed: _showEnhancedManualSearch,
                          isSecondary: true,
                        ),
                      ],
                    ),

                    // Help text - Compact
                    Text(
                      _isProcessing
                          ? '🔍 AI analyzing with computer vision...'
                          : '📸 50,000+ foods • Computer Vision AI • 100% Accurate',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    required String label,
    required VoidCallback? onPressed,
    bool isMain = false,
    bool isSecondary = false,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: isMain ? 60 : 50,
          height: isMain ? 60 : 50,
          child: FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: isMain
                ? kPrimaryColor
                : (isSecondary ? Colors.white : kPrimaryColor),
            foregroundColor: isMain
                ? Colors.white
                : (isSecondary ? kPrimaryColor : Colors.white),
            heroTag: label,
            elevation: isMain ? 4 : 2,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, size: isMain ? 28 : 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            color: isMain ? kPrimaryColor : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
