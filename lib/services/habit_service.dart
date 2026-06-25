import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

/// Singleton habit store. All callers share the same in-memory list,
/// so adds from the home screen are immediately visible in Configure
/// and Notifications without any async delay.
class HabitService {
  // ── Singleton ─────────────────────────────────────────────────────────
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  static const _key = 'configured_habits';

  List<Habit>? _cache; // null = not yet loaded from disk

  // ── Public API ────────────────────────────────────────────────────────

  /// Returns the current habit list. Loads from SharedPreferences on
  /// the first call; returns the cached copy on every subsequent call.
  Future<List<Habit>> loadHabits() async {
    if (_cache != null) return List.unmodifiable(_cache!);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_key);
      if (raw==null || raw.isEmpty) {
        _cache = [];
      } else {
        final list = jsonDecode(raw) as List<dynamic>;
        _cache = list
            .map((e) => _fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('HabitService.loadHabits error: $e');
      _cache = [];
    }
    return List.unmodifiable(_cache!);
  }

  /// Replaces the full habit list and persists it.
  Future<void> saveHabits(List<Habit> habits) async {
    _cache = List.from(habits); // update cache immediately
    try {
      final prefs   = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cache!.map(_toJson).toList());
      await prefs.setString(_key, encoded);
    } catch (e) {
      debugPrint('HabitService.saveHabits error: $e');
    }
  }

  /// Appends a single habit and persists. Convenience wrapper used by
  /// the home screen FAB so callers don't need to load first.
  Future<void> addHabit(Habit habit) async {
    await loadHabits();            // ensure cache is warm
    final updated = [..._cache!, habit];
    await saveHabits(updated);
  }

  /// Updates the colour of a single habit by ID.
  Future<void> updateColor(String id, Color color) async {
    await loadHabits();
    final updated = _cache!.map((h) {
      return h.id==id ? Habit(id: h.id, name: h.name, color: color) : h;
    }).toList();
    await saveHabits(updated);
  }

  /// Removes a habit by ID.
  Future<void> deleteHabit(String id) async {
    await loadHabits();
    await saveHabits(_cache!.where((h) => h.id != id).toList());
  }

  // ── Serialization ─────────────────────────────────────────────────────

  Map<String, dynamic> _toJson(Habit h) {
    // Store ARGB as four separate bytes for full compatibility across
    // Flutter versions (avoids Color.value deprecation concerns).
    final c = h.color;
    return {
      'id'   : h.id,
      'name' : h.name,
      'alpha': c.alpha,
      'red'  : c.red,
      'green': c.green,
      'blue' : c.blue,
    };
  }

  Habit _fromJson(Map<String, dynamic> j) {
    final color = j.containsKey('alpha')
        ? Color.fromARGB(
            j['alpha'] as int,
            j['red']   as int,
            j['green'] as int,
            j['blue']  as int,
          )
        // Legacy fallback: older entries stored as 'color' int
        : Color(j['color'] as int);

    return Habit(
      id   : j['id']   as String,
      name : j['name'] as String,
      color: color,
    );
  }
}
