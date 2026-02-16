
class User {
  final String id;
  final String username;
  final String role; // 'super_admin', 'game_master', 'viewer'
  final String? profilePicture;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'profilePicture': profilePicture,
    };
  }
}
