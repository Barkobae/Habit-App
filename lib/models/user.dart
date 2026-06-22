/// Represents a registered user. Stored in SharedPreferences as JSON
/// so that data persists between app sessions (User Story 4).
class AppUser {
  final String username;
  final String email;
  final String password;

  AppUser({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        username: json['username'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
      );
}
