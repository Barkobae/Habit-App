import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthResult {
  final bool success;
  final String message;
  final AppUser? user; // non-null on successful login
  const AuthResult(this.success, this.message, {this.user});
}

class AuthService {
  static const _usersKey = 'registered_users';

  Future<List<AppUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw==null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String country,
  }) async {
    final users = await _loadUsers();
    final alreadyExists =
        users.any((u) => u.email.toLowerCase()==email.toLowerCase());
    if (alreadyExists) {
      return const AuthResult(
          false, 'An account with this email already exists.');
    }
    users.add(AppUser(
        username: username, email: email, password: password, country: country));
    await _saveUsers(users);
    return const AuthResult(true, 'Account created successfully.');
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();
    final matches = users.where((u) =>
        u.email.toLowerCase()==email.toLowerCase() &&
        u.password==password);
    if (matches.isEmpty) {
      return const AuthResult(false,
          'Login attempt was unsuccessful. Check your email and password.');
    }
    final user = matches.first;
    return AuthResult(true, user.username, user: user);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final users = await _loadUsers();
    final matches =
        users.where((u) => u.email.toLowerCase()==email.toLowerCase());
    return matches.isEmpty ? null : matches.first;
  }

  Future<String?> updateUser({
    required String currentEmail,
    required String username,
    required String email,
    required String password,
    required String country,
  }) async {
    final users = await _loadUsers();
    final idx = users.indexWhere(
        (u) => u.email.toLowerCase()==currentEmail.toLowerCase());
    if (idx==-1) return 'User not found.';
    if (email.toLowerCase() != currentEmail.toLowerCase()) {
      final taken = users.any((u) =>
          u.email.toLowerCase()==email.toLowerCase() &&
          u.email.toLowerCase() != currentEmail.toLowerCase());
      if (taken) return 'Another account already uses that email.';
    }
    users[idx] = AppUser(
        username: username, email: email, password: password, country: country);
    await _saveUsers(users);
    return null;
  }
}
