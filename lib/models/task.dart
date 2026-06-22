import 'package:flutter/material.dart';

/// A sub-activity belonging to a task detail page.
class TaskActivity {
  final String id;
  String name;
  Color color;

  TaskActivity({required this.id, required this.name, required this.color});
}

/// A task card shown on the home screen.
class Task {
  final String id;
  String name;
  bool isDone;
  Color? color;

  /// Links this task to its habit in local storage so colour changes
  /// from Configure Habits propagate back to the card.
  final String? habitId;

  final DateTime createdAt;
  final List<TaskActivity> activities;

  Task({
    required this.id,
    required this.name,
    this.isDone = false,
    this.color,
    this.habitId,
    DateTime? createdAt,
    List<TaskActivity>? activities,
  })  : createdAt = createdAt ?? DateTime.now(),
        activities = activities ?? [];
}
