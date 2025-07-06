import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/firebase_user_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseUserService _userService = FirebaseUserService();
  final _formKey = GlobalKey<FormState>();

  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _calorieGoalController = TextEditingController();
  final TextEditingController _waterGoalController = TextEditingController();

  String _selectedDietType = 'None';
  List<String> _selectedAllergies = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _calorieGoalController.dispose();
    _waterGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _userService.getUserProfile(user.uid);

        if (userData != null && mounted) {
          setState(() {
            _user = userData;
            _nameController.text = userData.name;
            _emailController.text = userData.email;
            _selectedDietType = userData.dietType;
            _selectedAllergies = List.from(userData.allergies);
            _calorieGoalController.text =
                userData.dailyCalorieGoal?.toString() ?? '2000';
            _waterGoalController.text =
                userData.dailyWaterGoal?.toString() ?? '8';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _showPasswordConfirmationDialog() async {
    String? password;
    final TextEditingController passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        title: const Row(
          children: [
            Icon(Icons.security, color: kPrimaryColor),
            SizedBox(width: 8),
            Text('Confirm Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To change your email, please confirm your current password for security.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                hintText: 'Enter your current password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
              ),
              onChanged: (value) => password = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (password != null && password!.isNotEmpty) {
                passwordController.dispose();
                Navigator.pop(context, password);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 🔥 Check if email was changed
      final currentEmail = user.email ?? '';
      final newEmail = _emailController.text.trim();
      final emailChanged = currentEmail != newEmail;

      // Update user preferences (diet, allergies, goals) first
      await _userService.updateUserPreferences(
        user.uid,
        dietType: _selectedDietType,
        allergies: _selectedAllergies,
        dailyCalorieGoal: int.tryParse(_calorieGoalController.text),
        dailyWaterGoal: int.tryParse(_waterGoalController.text),
      );

      // Handle email change with password confirmation
      if (emailChanged) {
        // 🔐 Show password confirmation dialog
        final password = await _showPasswordConfirmationDialog();

        if (password == null || password.isEmpty) {
          // User cancelled password confirmation
          setState(() {
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email change cancelled. Password required for security.'),
              backgroundColor: kWarningColor,
            ),
          );
          return;
        }

        // 🔥 Update email with verification-first approach
        await _userService.updateUserEmail(newEmail, password);

        // Show detailed verification instructions
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_unread, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Email Verification Required'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📧 We\'ve sent a verification email to:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      newEmail,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Important Steps:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('1. Check your email inbox (and spam folder)'),
                        Text('2. Click the verification link in the email'),
                        Text('3. Return to this app after verification'),
                        Text('4. Your email will be updated automatically'),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Cancel email change
                    try {
                      await _userService.cancelEmailChange();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email change cancelled'),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: kErrorColor,
                        ),
                      );
                    }
                  },
                  child: const Text('Cancel Change'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Got it!'),
                ),
              ],
            ),
          );
        }
      }

      // Update name (email handled separately above)
      await _userService.updateUserBasicInfo(
        user.uid,
        name: _nameController.text.trim(),
      );

      // Reload fresh data
      await _loadUserData();

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        if (!emailChanged) {
          // Only show this if email wasn't changed (email change has its own success message)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile updated successfully!'),
              backgroundColor: kSuccessColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Parse error message for user-friendly display
        String errorMessage = 'Error updating profile';

        if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many attempts. Please wait before trying again.';
        } else if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'Please log out and log back in before changing email.';
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: kErrorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    }
  }

  Widget _buildProfileHeader() {
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
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  _user?.name.isNotEmpty == true
                      ? _user!.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: kSpacingMD),
              Text(
                _user?.name ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _user?.email ?? '',
                style: const TextStyle(
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

  Widget _buildBasicInfoSection() {
    return Card(
      margin: const EdgeInsets.all(kSpacingMD),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: kPrimaryColor),
                    SizedBox(width: 8),
                    Text('Basic Information', style: kSubheadingStyle),
                  ],
                ),
                if (!_isEditing)
                  Container(
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      icon: const Icon(Icons.edit, color: kPrimaryColor),
                      tooltip: 'Edit Profile',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: kSpacingMD),
            if (_isEditing) ...[
              _buildTextFormField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: kSpacingMD),
              _buildTextFormField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ] else ...[
              _buildInfoRow(
                  'Name', _user?.name ?? 'Not set', Icons.person_outline),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                        'Email', _user?.email ?? 'Not set', Icons.email_outlined),
                  ),
                  const SizedBox(width: 8),
                  _buildEmailVerificationStatus(), // ✅ ADD THIS LINE
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: kLightTextColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: kBodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietPreferencesSection() {
    return Card(
      margin: const EdgeInsets.all(kSpacingMD),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant, color: kPrimaryColor),
                SizedBox(width: 8),
                Text('Diet Preferences', style: kSubheadingStyle),
              ],
            ),
            const SizedBox(height: kSpacingMD),

            // Diet Type
            const Text(
              'Diet Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: kSpacingSM),
            if (_isEditing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
                child: DropdownButton<String>(
                  value: _selectedDietType,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: kDietTypes.map((diet) {
                    return DropdownMenuItem(
                      value: diet,
                      child: Text(diet),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDietType = value;
                      });
                    }
                  },
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedDietType,
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: kSpacingMD),

            // Allergies
            const Text(
              'Allergies',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: kSpacingSM),
            if (_isEditing) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCommonAllergies.map((allergy) {
                  final isSelected = _selectedAllergies.contains(allergy);
                  return FilterChip(
                    label: Text(allergy),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAllergies.add(allergy);
                        } else {
                          _selectedAllergies.remove(allergy);
                        }
                      });
                    },
                    selectedColor: kPrimaryColor.withOpacity(0.2),
                    checkmarkColor: kPrimaryColor,
                  );
                }).toList(),
              ),
            ] else ...[
              _selectedAllergies.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('None'),
              )
                  : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedAllergies.map((allergy) {
                  return Chip(
                    label: Text(allergy),
                    backgroundColor: kErrorColor.withOpacity(0.1),
                    labelStyle: const TextStyle(color: kErrorColor),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailChangeStatus() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userService.getEmailChangeStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final status = snapshot.data!;
        final hasPendingChange = status['hasPendingChange'] as bool;

        if (!hasPendingChange) return const SizedBox.shrink();

        final pendingEmail = status['pendingEmail'] as String?;

        return Container(
          margin: const EdgeInsets.all(kSpacingMD),
          padding: const EdgeInsets.all(kSpacingMD),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Email Change Pending',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Verification email sent to: $pendingEmail'),
              const SizedBox(height: 8),
              const Text(
                'Please check your email and click the verification link to complete the change.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _userService.completeEmailUpdate();
                        await _loadUserData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Email status refreshed'),
                            backgroundColor: kSuccessColor,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: kErrorColor,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Check Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      try {
                        await _userService.cancelEmailChange();
                        await _loadUserData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email change cancelled'),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: kErrorColor,
                          ),
                        );
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmailVerificationStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: _userService.isEmailVerified(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final isVerified = snapshot.data!;

        if (isVerified) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSuccessColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: kSuccessColor, size: 16),
                SizedBox(width: 4),
                Text(
                  'Email Verified',
                  style: TextStyle(
                    color: kSuccessColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kWarningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning, color: kWarningColor, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Email Not Verified',
                  style: TextStyle(
                    color: kWarningColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    try {
                      await _userService.resendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Verification email sent!'),
                          backgroundColor: kSuccessColor,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to send email: $e'),
                          backgroundColor: kErrorColor,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Resend',
                    style: TextStyle(
                      color: kWarningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildGoalsSection() {
    return Card(
      margin: const EdgeInsets.all(kSpacingMD),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag, color: kPrimaryColor),
                SizedBox(width: 8),
                Text('Daily Goals', style: kSubheadingStyle),
              ],
            ),
            const SizedBox(height: kSpacingMD),
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _calorieGoalController,
                      label: 'Calorie Goal',
                      icon: Icons.local_fire_department,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: kSpacingMD),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _waterGoalController,
                      label: 'Water Goal',
                      icon: Icons.water_drop,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildGoalCard(
                      'Daily Calories',
                      '${_user?.dailyCalorieGoal ?? 2000}',
                      'kcal',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: kSpacingMD),
                  Expanded(
                    child: _buildGoalCard(
                      'Water Goal',
                      '${_user?.dailyWaterGoal ?? 8}',
                      'glasses',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(
      String title,
      String value,
      String unit,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(kSpacingMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: kSpacingSM),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: kLightTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(kSpacingMD),
      child: Column(
        children: [
          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                      setState(() {
                        _isEditing = false;
                      });
                      _loadUserData(); // Reset to original values
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: kSpacingMD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: kSpacingMD),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: kErrorColor),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: kErrorColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kErrorColor),
                  padding: const EdgeInsets.symmetric(vertical: kSpacingMD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: _loadUserData,
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
            Text('Loading profile...'),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildEmailChangeStatus(),
              _buildBasicInfoSection(),
              _buildDietPreferencesSection(),
              _buildGoalsSection(),
              _buildActionButtons(),
              const SizedBox(height: kSpacingLG),
            ],
          ),
        ),
      ),
    );
  }
}