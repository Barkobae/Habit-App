import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskService {
  static const _key = 'saved_tasks';

  Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list  = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => _taskFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs   = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map(_taskToJson).toList());
    await prefs.setString(_key, encoded);
  }

  // ── Serialization ─────────────────────────────────────────────────────

  Map<String, dynamic> _taskToJson(Task t) => {
        'id'        : t.id,
        'name'      : t.name,
        'isDone'    : t.isDone,
        'color'     : t.color?.value,
        'habitId'   : t.habitId,
        'createdAt' : t.createdAt.toIso8601String(),
        'activities': t.activities.map(_activityToJson).toList(),
      };

  Task _taskFromJson(Map<String, dynamic> j) => Task(
        id        : j['id'] as String,
        name      : j['name'] as String,
        isDone    : j['isDone'] as bool? ?? false,
        color     : j['color'] != null ? Color(j['color'] as int) : null,
        habitId   : j['habitId'] as String?,
        createdAt : DateTime.tryParse(j['createdAt'] as String? ?? '') ??
                    DateTime.now(),
        activities: ((j['activities'] as List<dynamic>?) ?? [])
            .map((e) => _activityFromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> _activityToJson(TaskActivity a) => {
        'id'   : a.id,
        'name' : a.name,
        'color': a.color.value,
      };

  TaskActivity _activityFromJson(Map<String, dynamic> j) => TaskActivity(
        id    : j['id'] as String,
        name  : j['name'] as String,
        color : Color(j['color'] as int),
      );
}
