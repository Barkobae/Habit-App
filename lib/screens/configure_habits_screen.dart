import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';

const List<MapEntry<String, Color>> kHabitColors = [
  MapEntry('None',   Colors.transparent),
  MapEntry('Amber',  Color(0xFFFFC107)),
  MapEntry('Green',  Color(0xFF4CAF50)),
  MapEntry('Teal',   Color(0xFF009688)),
  MapEntry('Blue',   Color(0xFF2196F3)),
  MapEntry('Purple', Color(0xFF9C27B0)),
  MapEntry('Red',    Color(0xFFF44336)),
  MapEntry('Orange', Color(0xFFFF9800)),
  MapEntry('Pink',   Color(0xFFE91E63)),
];

/// Shows every habit the user has created from the home screen.
/// Allows changing the colour or deleting a habit — but NOT adding new
/// ones (habits are added via the + FAB on the home screen).
class ConfigureHabitsScreen extends StatefulWidget {
  const ConfigureHabitsScreen({super.key});

  @override
  State<ConfigureHabitsScreen> createState() => _ConfigureHabitsScreenState();
}

class _ConfigureHabitsScreenState extends State<ConfigureHabitsScreen> {
  static const _blue = Color(0xFF1976D2);

  final _service = HabitService();
  List<Habit> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits = await _service.loadHabits();
    if (mounted) setState(() { _habits = habits; _loading = false; });
  }

  Future<void> _updateColor(Habit habit, Color color) async {
    final updated = _habits.map((h) {
      if (h.id == habit.id) {
        return Habit(id: h.id, name: h.name, color: color);
      }
      return h;
    }).toList();
    setState(() => _habits = updated);
    await _service.saveHabits(updated);
  }

  Future<void> _delete(String id) async {
    final updated = _habits.where((h) => h.id != id).toList();
    setState(() => _habits = updated);
    await _service.saveHabits(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F7),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(),
        title: const Text(
          'Configure Habits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const Center(
                  child: Text(
                    'No habits yet.\nUse the + button on the home screen to add some.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (_, i) {
                    final h = _habits[i];
                    final isNone = h.color == Colors.transparent;
                    // Find the matching entry in the colour list so the
                    // dropdown shows the right selected value.
                    final currentEntry = kHabitColors.firstWhere(
                      (e) => e.value == h.color,
                      orElse: () => kHabitColors.first,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Colour circle
                            CircleAvatar(
                              backgroundColor: isNone
                                  ? const Color(0xFFDDDDDD)
                                  : h.color,
                              radius: 20,
                              child: isNone
                                  ? const Icon(Icons.block,
                                      size: 14, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Name + colour dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(h.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  const SizedBox(height: 6),
                                  // Inline colour picker
                                  Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: const Border.fromBorderSide(
                                          BorderSide(
                                              color: Color(0xFFDDDDDD))),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<
                                          MapEntry<String, Color>>(
                                        value: currentEntry,
                                        isExpanded: true,
                                        isDense: true,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        items: kHabitColors.map((e) {
                                          final none = e.value ==
                                              Colors.transparent;
                                          return DropdownMenuItem(
                                            value: e,
                                            child: Row(children: [
                                              CircleAvatar(
                                                backgroundColor: none
                                                    ? const Color(
                                                        0xFFDDDDDD)
                                                    : e.value,
                                                radius: 8,
                                                child: none
                                                    ? const Icon(
                                                        Icons.block,
                                                        size: 10,
                                                        color: Colors.grey)
                                                    : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(e.key,
                                                  style: const TextStyle(
                                                      fontSize: 13)),
                                            ]),
                                          );
                                        }).toList(),
                                        onChanged: (v) {
                                          if (v != null) {
                                            _updateColor(h, v.value);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Delete
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () => _delete(h.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
