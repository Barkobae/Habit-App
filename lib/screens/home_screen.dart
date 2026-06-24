import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/task.dart';
import '../services/habit_service.dart';
import '../services/task_service.dart';
import 'configure_habits_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'personal_info_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String email;
  const HomeScreen({super.key, required this.username, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _blue = Color(0xFF1976D2);
  final _habitService = HabitService();
  final _taskService  = TaskService();

  final List<Task> _tasks = [];
  List<Habit> _habits = [];
  late String _displayUsername;
  late String _currentEmail;

  List<Task> get _pendingTasks => _tasks.where((t) => !t.isDone).toList();
  List<Task> get _doneTasks    => _tasks.where((t) => t.isDone).toList();

  @override
  void initState() {
    super.initState();
    _displayUsername = widget.username;
    _currentEmail    = widget.email;
    _loadHabits();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.loadTasks();
    if (mounted) setState(() { _tasks.addAll(tasks); });
  }

  Future<void> _loadHabits() async {
    final habits = await _habitService.loadHabits();
    if (!mounted) return;
    setState(() {
      _habits = habits;
      // Sync task card colours with any changes made in Configure Habits
      for (final task in _tasks) {
        if (task.habitId == null) continue;
        final match = habits.where((h) => h.id == task.habitId);
        if (match.isNotEmpty) {
          task.color = match.first.color == Colors.transparent
              ? null
              : match.first.color;
        }
      }
    });
  }

  void _addTask(String name, Color? color, {String? habitId}) {
    setState(() {
      _tasks.add(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        color: color,
        habitId: habitId,
      ));
    });
    _taskService.saveTasks(_tasks);
  }

  void _markDone(String id) {
    setState(() => _tasks.firstWhere((t) => t.id == id).isDone = true);
    _taskService.saveTasks(_tasks);
  }

  void _deleteTask(String id) {
    setState(() => _tasks.removeWhere((t) => t.id == id));
    _taskService.saveTasks(_tasks);
  }

  // ── FAB: show habit picker bottom sheet ──────────────────────────────

  Future<void> _openHabitPicker() async {
    final result = await showModalBottomSheet<({String name, Color? color, String habitId})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _HabitPickerSheet(),
    );

    if (result == null || !mounted) return;

    final newHabit = Habit(
      id   : result.habitId,
      name : result.name,
      color: result.color ?? Colors.transparent,
    );

    // Persist habit first, then add task so both stores are consistent.
    await _habitService.addHabit(newHabit);
    _addTask(result.name, result.color, habitId: result.habitId);

    final updated = await _habitService.loadHabits();
    if (mounted) setState(() => _habits = List.from(updated));
  }

  // ── drawer ────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: _blue,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: const Text(
              'Menu',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          _drawerItem(
            icon: Icons.settings,
            label: 'Configure',
            onTap: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ConfigureHabitsScreen(),
              ));
              // Reload habits so colour changes from Configure are
              // reflected on the home screen task cards immediately.
              _loadHabits();
            },
          ),
          _drawerItem(
            icon: Icons.person_outline,
            label: 'Personal Info',
            onTap: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PersonalInfoScreen(
                  currentEmail: _currentEmail,
                  onUpdated: (updated) {
                    setState(() {
                      _displayUsername = updated.username;
                      _currentEmail    = updated.email;
                    });
                  },
                ),
              ));
            },
          ),
          _drawerItem(
            icon: Icons.bar_chart,
            label: 'Reports',
            onTap: () => Navigator.of(context).pop(),
          ),
          _drawerItem(
            icon: Icons.notifications_none,
            label: 'Notifications',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ));
            },
          ),
          _drawerItem(
            icon: Icons.logout,
            label: 'Sign Out',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(label, style: const TextStyle(fontSize: 15)),
        onTap: onTap,
      );

  // ── task card ─────────────────────────────────────────────────────────

  Widget _taskCard(Task task) {
    final cardColor = task.color ?? Colors.white;
    final textColor = task.color != null
        ? _contrastColor(task.color!)
        : Colors.black87;

    return Dismissible(
      key: ValueKey(task.id),
      background: _swipeBg(
          color: Colors.green.shade600,
          icon: Icons.check,
          alignment: Alignment.centerLeft),
      secondaryBackground: _swipeBg(
          color: Colors.red.shade600,
          icon: Icons.delete,
          alignment: Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) return true;
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text('Remove "${task.name}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.startToEnd) {
          _markDone(task.id);
        } else {
          _deleteTask(task.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: task.color == null
              ? const BorderSide(color: Color(0xFFE0E0E0))
              : BorderSide.none,
        ),
        child: ListTile(
          title: Text(task.name,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w500)),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline,
                color: textColor.withAlpha(180)),
            onPressed: () => _deleteTask(task.id),
          ),
        ),
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(10)),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(icon, color: Colors.white),
      );

  /// Returns black or white depending on background brightness.
  Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pending = _pendingTasks;
    final done    = _doneTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F7),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(_displayUsername,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── To Do section ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(children: [
              Text('To Do',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Icon(Icons.edit_note, size: 20),
            ]),
          ),
          Expanded(
            child: pending.isEmpty
                ? const Center(
                    child: Text(
                      'Use the + button to create some habits!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView(children: pending.map(_taskCard).toList()),
          ),

          // ── Done section ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Done',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  const Icon(Icons.check_box, size: 20),
                  if (done.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.green.shade600,
                      child: Text('${done.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(
                  done.isEmpty
                      ? 'Swipe right on an activity to mark as done.'
                      : done.map((t) => t.name).join(', '),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openHabitPicker,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Add Habit bottom sheet ────────────────────────────────────────────────

const List<MapEntry<String, Color>> _kColors = [
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

class _HabitPickerSheet extends StatefulWidget {
  const _HabitPickerSheet();

  @override
  State<_HabitPickerSheet> createState() => _HabitPickerSheetState();
}

class _HabitPickerSheetState extends State<_HabitPickerSheet> {
  static const _blue = Color(0xFF1976D2);
  final _ctrl = TextEditingController();
  MapEntry<String, Color> _selected = _kColors.first;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name.')),
      );
      return;
    }
    final color = _selected.value == Colors.transparent
        ? null
        : _selected.value;
    final habitId = DateTime.now().millisecondsSinceEpoch.toString();
    Navigator.of(context).pop((name: name, color: color, habitId: habitId));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Habit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          // ── Name field ─────────────────────────────────────────────
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Habit Name',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Color label ────────────────────────────────────────────
          const Text('Select Color:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),

          // ── Color dropdown ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: const Border.fromBorderSide(
                  BorderSide(color: Color(0xFFDDDDDD))),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MapEntry<String, Color>>(
                value: _selected,
                isExpanded: true,
                borderRadius: BorderRadius.circular(8),
                selectedItemBuilder: (context) => _kColors.map((e) {
                  final isNone = e.value == Colors.transparent;
                  return Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isNone ? const Color(0xFFEEEEEE) : e.value,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      e.key,
                      style: TextStyle(
                        color: isNone ? Colors.black54 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                items: _kColors.map((e) {
                  final isNone = e.value == Colors.transparent;
                  return DropdownMenuItem(
                    value: e,
                    child: Row(children: [
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor:
                            isNone ? const Color(0xFFDDDDDD) : e.value,
                        radius: 10,
                        child: isNone
                            ? const Icon(Icons.block,
                                size: 12, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(e.key),
                    ]),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selected = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Add button ─────────────────────────────────────────────
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
            ),
            child: const Text('Add Habit',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
