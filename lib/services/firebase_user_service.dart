import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirebaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Getter untuk firestore
  FirebaseFirestore get firestore => _firestore;

  // Getter untuk collection
  String get collection => _collection;

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> updateUserEmail(String newEmail, String currentPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // STEP 1: Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      print('✅ User re-authenticated successfully');

      // STEP 2: Use verifyBeforeUpdateEmail instead of updateEmail
      await user.verifyBeforeUpdateEmail(newEmail);
      print('✅ Email verification sent to: $newEmail');

      // STEP 3: Update Firestore document (but keep email as pending)
      await _firestore.collection(_collection).doc(user.uid).update({
        'pendingEmail': newEmail, // Store as pending until verified
        'emailChangeRequested': true,
        'emailChangeRequestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Email change request saved to Firestore');
    } catch (e) {
      print('❌ Error updating email: $e');

      // Handle specific Firebase errors
      if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many attempts. Please wait before trying again.');
      } else if (e.toString().contains('requires-recent-login')) {
        throw Exception('Please log out and log back in before changing email.');
      } else if (e.toString().contains('email-already-in-use')) {
        throw Exception('This email is already in use by another account.');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Please enter a valid email address.');
      } else {
        throw Exception('Failed to update email: ${e.toString()}');
      }
    }
  }
  Future<void> completeEmailUpdate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reload user to get latest email verification status
      await user.reload();

      // Check if email was actually updated
      final doc = await _firestore.collection(_collection).doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final pendingEmail = data['pendingEmail'] as String?;

        if (pendingEmail != null && user.email == pendingEmail) {
          // Email was successfully updated, clean up pending fields
          await _firestore.collection(_collection).doc(user.uid).update({
            'email': user.email,
            'pendingEmail': FieldValue.delete(),
            'emailChangeRequested': FieldValue.delete(),
            'emailChangeRequestedAt': FieldValue.delete(),
            'emailVerified': user.emailVerified,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Email update completed in Firestore');
        }
      }
    } catch (e) {
      print('❌ Error completing email update: $e');
    }
  }

  Future<Map<String, dynamic>> getEmailChangeStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'hasPendingChange': false};
      }

      final doc = await _firestore.collection(_collection).doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'hasPendingChange': data['emailChangeRequested'] == true,
          'pendingEmail': data['pendingEmail'],
          'requestedAt': data['emailChangeRequestedAt'],
        };
      }

      return {'hasPendingChange': false};
    } catch (e) {
      print('❌ Error getting email change status: $e');
      return {'hasPendingChange': false};
    }
  }

  Future<void> cancelEmailChange() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection(_collection).doc(user.uid).update({
        'pendingEmail': FieldValue.delete(),
        'emailChangeRequested': FieldValue.delete(),
        'emailChangeRequestedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Email change cancelled');
    } catch (e) {
      print('❌ Error cancelling email change: $e');
      throw Exception('Failed to cancel email change: $e');
    }
  }

// Add method to check email verification status
  Future<bool> isEmailVerified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Reload user to get latest verification status
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      print('❌ Error checking email verification: $e');
      return false;
    }
  }

// Add method to resend verification email
  Future<void> resendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      await user.sendEmailVerification();
      print('✅ Verification email resent');
    } catch (e) {
      print('❌ Error resending verification email: $e');
      throw Exception('Failed to resend verification email: $e');
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(
    String uid, {
    String? dietType,
    List<String>? allergies,
    int? dailyCalorieGoal,
    int? dailyWaterGoal,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (dietType != null) updates['dietType'] = dietType;
      if (allergies != null) updates['allergies'] = allergies;
      if (dailyCalorieGoal != null) {
        updates['dailyCalorieGoal'] = dailyCalorieGoal;
      }
      if (dailyWaterGoal != null) updates['dailyWaterGoal'] = dailyWaterGoal;

      if (updates.isNotEmpty) {
        await _firestore.collection(_collection).doc(uid).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  // Update user basic info
  // In firebase_user_service.dart
  Future<void> updateUserBasicInfo(
      String uid, {
        String? name,
        // Remove email parameter since it's handled separately
      }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;

      if (updates.isNotEmpty) {
        await _firestore.collection(_collection).doc(uid).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update user info: $e');
    }
  }

  // Get user data (alias for getUserProfile for compatibility)
  Future<UserModel?> getUserData(String uid) async {
    return await getUserProfile(uid);
  }

  // Update user goals (new method for analytics dashboard)
  Future<void> updateUserGoals(
    String uid, {
    double? dailyCalorieGoal,
    double? dailyProteinGoal,
    double? dailyCarbsGoal,
    double? dailyFatGoal,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (dailyCalorieGoal != null) {
        updates['dailyCalorieGoal'] = dailyCalorieGoal.toInt();
      }
      if (dailyProteinGoal != null) {
        updates['dailyProteinGoal'] = dailyProteinGoal;
      }
      if (dailyCarbsGoal != null) updates['dailyCarbsGoal'] = dailyCarbsGoal;
      if (dailyFatGoal != null) updates['dailyFatGoal'] = dailyFatGoal;

      if (updates.isNotEmpty) {
        await _firestore.collection(_collection).doc(uid).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update user goals: $e');
    }
  }

  // Get user goals
  Future<Map<String, double>> getUserGoals(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'calories': (data['dailyCalorieGoal'] as num?)?.toDouble() ?? 2000.0,
          'protein': (data['dailyProteinGoal'] as num?)?.toDouble() ?? 150.0,
          'carbs': (data['dailyCarbsGoal'] as num?)?.toDouble() ?? 250.0,
          'fat': (data['dailyFatGoal'] as num?)?.toDouble() ?? 65.0,
        };
      }
      return {
        'calories': 2000.0,
        'protein': 150.0,
        'carbs': 250.0,
        'fat': 65.0,
      };
    } catch (e) {
      throw Exception('Failed to get user goals: $e');
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get user count (for admin dashboard)
  Future<int> getUserCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get user count: $e');
    }
  }

  // Search users by name or email (for admin)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query\uf8ff')
          .get();

      final List<UserModel> users = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Also search by email
      final emailSnapshot = await _firestore
          .collection(_collection)
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: '$query\uf8ff')
          .get();

      final emailUsers = emailSnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Combine and remove duplicates
      final allUsers = [...users, ...emailUsers];
      final uniqueUsers = <String, UserModel>{};
      for (final user in allUsers) {
        uniqueUsers[user.uid] = user;
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
