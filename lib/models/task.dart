import 'package:flutter/material.dart';

class TaskActivity {
  final String id;
  String name;
  Color color;

  TaskActivity({required this.id, required this.name, required this.color});
}


class Task {
  final String id;
  String name;
  bool isDone;
  Color? color;

 
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
