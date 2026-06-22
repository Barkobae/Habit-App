import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Simple result wrapper so screens can show success/error feedback
/// (User Story 3) without throwing exceptions for expected failures.
class AuthResult {
  final bool success;
  final String message;
  const AuthResult(this.success, this.message);
}

/// Handles registration, login, and persistence of user accounts.
///
/// Accounts are stored locally via SharedPreferences as a JSON-encoded
/// list, so registered users remain available across app restarts
/// (User Story 4).
class AuthService {
  static const _usersKey = 'User Details';

  Future<List<AppUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, encoded);
  }

  /// Registers a new user (User Story 1).
  /// Fails if an account with the same email already exists.
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();

    final alreadyExists = users.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );

    if (alreadyExists) {
      return const AuthResult(
        false,
        'An account with this email already exists.',
      );
    }

    users.add(AppUser(username: username, email: email, password: password));
    await _saveUsers(users);

    return const AuthResult(true, 'Account created successfully.');
  }

  /// Authenticates a user against stored accounts (User Story 2).
  /// Returns a failure message if email/password don't match
  /// (User Story 3).
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();

    final matches = users.where(
      (u) =>
          u.email.toLowerCase() == email.toLowerCase() &&
          u.password == password,
    );

    if (matches.isEmpty) {
      return const AuthResult(
        false,
        'Login attempt was unsuccessful. Check your email and password.',
      );
    }

    return AuthResult(true, matches.first.username);
  }
}
