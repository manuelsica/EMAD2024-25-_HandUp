// lib/user.dart

class User {
  final String username;
  final int points;

  User({required this.username, required this.points});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      points: json['points'] as int,
    );
  }
}