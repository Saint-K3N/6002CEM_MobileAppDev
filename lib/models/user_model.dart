class UserModel {
  final String uid;
  final String email;
  final String name;
  final String dietType;
  final List<String> allergies;
  final int? dailyCalorieGoal;
  final int? dailyWaterGoal;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.dietType,
    required this.allergies,
    this.dailyCalorieGoal,
    this.dailyWaterGoal,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'dietType': dietType,
      'allergies': allergies,
      'dailyCalorieGoal': dailyCalorieGoal,
      'dailyWaterGoal': dailyWaterGoal,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map (Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      dietType: map['dietType'] ?? 'None',
      allergies: List<String>.from(map['allergies'] ?? []),
      dailyCalorieGoal: map['dailyCalorieGoal'],
      dailyWaterGoal: map['dailyWaterGoal'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? dietType,
    List<String>? allergies,
    int? dailyCalorieGoal,
    int? dailyWaterGoal,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      dietType: dietType ?? this.dietType,
      allergies: allergies ?? this.allergies,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, dietType: $dietType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
