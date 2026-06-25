import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState()=>_NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _blue =Color(0xFF1976D2);
  static const _times=['Morning', 'Afternoon', 'Evening'];

  final _notifService=NotificationService();
  final _habitService=HabitService();

  NotificationSettings _settings=const NotificationSettings();
  List<Habit> _habits =[];
  bool  _loading      =true;
  bool  _saving       =false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final habits  =await _habitService.loadHabits();
    final settings=await _notifService.loadSettings();

    String? token;
    try {
      token=await _notifService.getToken();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _habits  =habits;
      _settings=settings;
      _loading =false;
    });
  }

  Future<void> _save(NotificationSettings updated) async {
    setState(() { _settings=updated; _saving=true; });
    await _notifService.saveSettings(updated);

    final selectedNames=_habits
        .where((h)=>updated.selectedHabitIds.contains(h.id))
        .map((h)=>h.name)
        .toList();
    await _notifService.subscribeToHabits(updated, selectedNames);

    if (mounted) setState(()=>_saving=false);
  }

  void _toggleEnabled(bool v)=>_save(_settings.copyWith(enabled:v));

  void _toggleHabit(String id) {
    final ids=List<String>.from(_settings.selectedHabitIds);
    ids.contains(id) ? ids.remove(id) :ids.add(id);
    _save(_settings.copyWith(selectedHabitIds:ids));
  }

  void _toggleTime(String t) {
    final times=List<String>.from(_settings.selectedTimes);
    times.contains(t) ? times.remove(t) :times.add(t);
    _save(_settings.copyWith(selectedTimes:times));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color(0xFFF0F0F7),
      appBar:AppBar(
        backgroundColor:_blue,
        foregroundColor:Colors.white,
        elevation:0,
        leading:const BackButton(),
        title:const Text('Notifications',
            style:TextStyle(fontWeight:FontWeight.bold)),
        actions:[
          if (_saving)
            const Padding(
              padding:EdgeInsets.all(14),
              child:SizedBox(
                width:20, height:20,
                child:CircularProgressIndicator(
                    strokeWidth:2, color:Colors.white),
              ),
            ),
        ],
      ),
      body:_loading
          ? const Center(child:CircularProgressIndicator())
          :SingleChildScrollView(
              padding:const EdgeInsets.all(16),
              child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  _card(
                    child:Material(
                    color:Colors.transparent,
                      child:SwitchListTile(
                 contentPadding:EdgeInsets.zero,
                      title:const Text('Enable Notifications',
                            style:
                                TextStyle(fontWeight:FontWeight.w500)),
                        value:_settings.enabled,
                        onChanged:_toggleEnabled,
                      ),
                    ),
                  ),
                  const SizedBox(height:20),

                  // ── Habit chips ────────────────────────────────────
                  const Text('Select Habits for Notification',
                      style:TextStyle(
                          fontWeight:FontWeight.bold, fontSize:15)),
                  const SizedBox(height:10),
                  _habits.isEmpty
                      ? const Text(
                          'No habits yet — add some from the home screen.',
                          style:
                              TextStyle(color:Colors.grey, fontSize:13),
                        )
                      :Wrap(
                          spacing:8,
                          runSpacing:8,
                          children:_habits.map((h) {
                            final selected=_settings.selectedHabitIds
                                .contains(h.id);
                            return _HabitChip(
                              label:h.name,
                              color:h.color,
                              selected:selected,
                              onTap:_settings.enabled
                                  ? ()=>_toggleHabit(h.id)
                                  :null,
                            );
                          }).toList(),
                        ),
                  const SizedBox(height:20),
                  const Text('Select Times for Notification',
                      style:TextStyle(
                          fontWeight:FontWeight.bold, fontSize:15)),
                  const SizedBox(height:10),
                  Wrap(
                    spacing:8,
                    runSpacing:8,
                    children:_times.map((t) {
                      final selected =
                          _settings.selectedTimes.contains(t);
                      return _TimeChip(
                        label:t,
                        selected:selected,
                        onTap:_settings.enabled
                            ? ()=>_toggleTime(t)
                            :null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height:24),

        
                ],
              ),
            ),
    );
  }

  Widget _card({required Widget child})=>Container(
        width:double.infinity,
        padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(
          color:Colors.white,
          borderRadius:BorderRadius.circular(12),
        ),
        child:child,
      );
}

class _HabitChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _HabitChip({
    required this.label,
    required this.color,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor    =selected ? color.withAlpha(30)  :Colors.white;
    final borderColor=selected ? color                :Colors.grey.shade400;
    final textColor  =selected ? color                :Colors.grey.shade700;

    return GestureDetector(
      onTap:onTap,
      child:AnimatedContainer(
        duration:const Duration(milliseconds:150),
        padding:const EdgeInsets.symmetric(horizontal:14, vertical:8),
        decoration:BoxDecoration(
          color:bgColor,
          borderRadius:BorderRadius.circular(20),
          border:Border.all(color:borderColor),
        ),
        child:Row(
          mainAxisSize:MainAxisSize.min,
          children:[
            if (selected) ...[
              Icon(Icons.check, size:14, color:textColor),
              const SizedBox(width:4),
            ],
            Text(label,
                style:TextStyle(
                    color:textColor, fontWeight:FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _TimeChip(
      {required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:onTap,
      child:AnimatedContainer(
        duration:const Duration(milliseconds:150),
        padding:
            const EdgeInsets.symmetric(horizontal:16, vertical:8),
        decoration:BoxDecoration(
          color:selected ? const Color(0xFFEDE7F6) :Colors.white,
          borderRadius:BorderRadius.circular(20),
          border:Border.all(
            color:selected
                ? const Color(0xFF7E57C2)
                :Colors.grey.shade400,
          ),
        ),
        child:Row(
          mainAxisSize:MainAxisSize.min,
          children:[
            if (selected) ...[
              const Icon(Icons.check,
                  size:14, color:Color(0xFF7E57C2)),
              const SizedBox(width:4),
            ],
            Text(
              label,
              style:TextStyle(
                color:selected
                    ? const Color(0xFF7E57C2)
                    :Colors.grey.shade700,
                fontWeight:FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
