import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// Persists the list of configured habits to SharedPreferences so they
/// survive app restarts.
class HabitService {
  static const _key = 'configured_habits';

  /// Load all saved habits. Returns [] on first run.
  Future<List<Habit>> loadHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save the full habit list, overwriting any previous data.
  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(habits.map(_toJson).toList());
    await prefs.setString(_key, encoded);
  }

  // ── serialization ────────────────────────────────────────────────────

  Map<String, dynamic> _toJson(Habit h) => {
        'id': h.id,
        'name': h.name,
        'color': h.color.value,
      };

  Habit _fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        color: Color(j['color'] as int),
      );
}
