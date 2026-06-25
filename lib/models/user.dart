class AppUser {
  final String username;
  final String email;
  final String password;
  final String country;

  AppUser({
    required this.username,
    required this.email,
    required this.password,
    required this.country,
  });

  Map<String, dynamic> toJson()=>{
        'username': username,
        'email': email,
        'password': password,
        'country': country,
      };

  factory AppUser.fromJson(Map<String, dynamic> json)=>AppUser(
        username: json['username'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        country: json['country'] as String? ?? '',
      );
}
