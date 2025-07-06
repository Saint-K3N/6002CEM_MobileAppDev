import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (_currentUserId == null) {
      print('❌ No user logged in');
      return null;
    }

    try {
      print('👤 Getting user data for: $_currentUserId');

      final doc =
          await _firestore.collection('users').doc(_currentUserId).get();

      if (doc.exists) {
        final userData = doc.data()!;
        userData['id'] = doc.id;
        print('✅ User data loaded: ${userData['username']}');
        return userData;
      } else {
        print('❌ User document not found');
        return null;
      }
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> userData) async {
    if (_currentUserId == null) return false;

    try {
      print('📝 Updating user profile: ${userData['username']}');

      await _firestore.collection('users').doc(_currentUserId).update({
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ User profile updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating user profile: $e');
      return false;
    }
  }

  // Update user preferences
  Future<bool> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (_currentUserId == null) return false;

    try {
      print('⚙️ Updating user preferences');

      await _firestore.collection('users').doc(_currentUserId).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ User preferences updated');
      return true;
    } catch (e) {
      print('❌ Error updating preferences: $e');
      return false;
    }
  }

  // Track user activity
  Future<void> trackActivity(
      String activityType, Map<String, dynamic> data) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('activities')
          .add({
        'type': activityType,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('📊 Activity tracked: $activityType');
    } catch (e) {
      print('❌ Error tracking activity: $e');
    }
  }

  // Update user stats
  Future<void> updateUserStats(Map<String, dynamic> stats) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'stats': stats,
        'statsUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('📈 User stats updated');
    } catch (e) {
      print('❌ Error updating user stats: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    if (_currentUserId == null) return {};

    try {
      final doc =
          await _firestore.collection('users').doc(_currentUserId).get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['stats'] ?? {};
      }
      return {};
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {};
    }
  }

  // Update water intake
  Future<bool> updateWaterIntake(int waterIntake) async {
    if (_currentUserId == null) return false;

    try {
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('hydration')
          .doc(dateString)
          .set({
        'waterIntake': waterIntake,
        'date': today,
        'dateString': dateString,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('💧 Water intake updated: $waterIntake cups');
      return true;
    } catch (e) {
      print('❌ Error updating water intake: $e');
      return false;
    }
  }

  // Get today's water intake
  Future<int> getTodayWaterIntake() async {
    if (_currentUserId == null) return 0;

    try {
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('hydration')
          .doc(dateString)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return data['waterIntake'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting water intake: $e');
      return 0;
    }
  }

  // Get user's favorite recipes
  Future<List<Map<String, dynamic>>> getFavoriteRecipes() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting favorite recipes: $e');
      return [];
    }
  }

  // Add recipe to favorites
  Future<bool> addToFavorites(Map<String, dynamic> recipe) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .doc(recipe['id'].toString())
          .set({
        ...recipe,
        'addedAt': FieldValue.serverTimestamp(),
      });

      print('⭐ Recipe added to favorites: ${recipe['title']}');
      return true;
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return false;
    }
  }

  // Remove from favorites
  Future<bool> removeFromFavorites(String recipeId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .doc(recipeId)
          .delete();

      print('🗑️ Recipe removed from favorites');
      return true;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      return false;
    }
  }

  // Check if recipe is favorited
  Future<bool> isRecipeFavorited(String recipeId) async {
    if (_currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .doc(recipeId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking if favorited: $e');
      return false;
    }
  }
}
