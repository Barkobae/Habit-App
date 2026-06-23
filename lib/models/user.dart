/// Represents a registered user. Stored in SharedPreferences as JSON.
class AppUser {
  final String username;
  final String email;
  final String password;
  final String country; // e.g. "Australia"

  AppUser({
    required this.username,
    required this.email,
    required this.password,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        'country': country,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        username: json['username'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        // Graceful fallback for accounts saved before this field existed.
        country: json['country'] as String? ?? '',
      );
}
