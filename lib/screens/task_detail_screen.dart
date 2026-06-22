import 'package:flutter/material.dart';

import '../models/task.dart';

const List<MapEntry<String, Color>> kActivityColors = [
  MapEntry('Amber',  Color(0xFFFFC107)),
  MapEntry('Green',  Color(0xFF4CAF50)),
  MapEntry('Teal',   Color(0xFF009688)),
  MapEntry('Blue',   Color(0xFF2196F3)),
  MapEntry('Purple', Color(0xFF9C27B0)),
  MapEntry('Red',    Color(0xFFF44336)),
  MapEntry('Orange', Color(0xFFFF9800)),
  MapEntry('Pink',   Color(0xFFE91E63)),
];

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final VoidCallback onDelete;
  final ValueChanged<Task> onUpdate;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const _blue = Color(0xFF1976D2);

  final _habitNameCtrl = TextEditingController();
  MapEntry<String, Color> _selectedColor = kActivityColors.first;

  @override
  void dispose() {
    _habitNameCtrl.dispose();
    super.dispose();
  }

  void _addActivity() {
    final name = _habitNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name.')),
      );
      return;
    }
    setState(() {
      widget.task.activities.add(TaskActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        color: _selectedColor.value,
      ));
      _habitNameCtrl.clear();
    });
    widget.onUpdate(widget.task);
  }

  void _deleteActivity(String id) {
    setState(() => widget.task.activities.removeWhere((a) => a.id == id));
    widget.onUpdate(widget.task);
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Remove "${widget.task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDelete();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F7),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.task.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Habit name input ──────────────────────────────────────
            TextField(
              controller: _habitNameCtrl,
              decoration: InputDecoration(
                hintText: 'Habit Name',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFDDDDDD)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Color label ───────────────────────────────────────────
            const Text(
              'Select Color:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),

            // ── Color dropdown ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: const Border.fromBorderSide(
                    BorderSide(color: Color(0xFFDDDDDD))),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MapEntry<String, Color>>(
                  value: _selectedColor,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(8),
                  // Selected display: coloured bar
                  selectedItemBuilder: (context) => kActivityColors
                      .map(
                        (e) => Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: e.value,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  // Dropdown items: circle + label
                  items: kActivityColors
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              CircleAvatar(
                                  backgroundColor: e.value, radius: 10),
                              const SizedBox(width: 10),
                              Text(e.key),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedColor = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Add Habit button ──────────────────────────────────────
            ElevatedButton(
              onPressed: _addActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
              ),
              child: const Text(
                'Add Habit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // ── Activity list (static, no Expanded needed) ────────────
            if (widget.task.activities.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    'No habits yet. Add one above!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...widget.task.activities.map(
                (activity) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: activity.color,
                        radius: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          activity.name,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteActivity(activity.id),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
