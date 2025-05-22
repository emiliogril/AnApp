import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../services/notification_service.dart';

class GroupProvider extends ChangeNotifier {
  final List<Group> _groups = [];
  DateTime _rotationStart = DateTime.now();
  final NotificationService _notifications = NotificationService();

  List<Group> get groups => List.unmodifiable(_groups);
  DateTime get rotationStart => _rotationStart;

  void addGroup(Group group) {
    _groups.add(group);
    notifyListeners();
  }

  void removeGroup(Group group) {
    _groups.remove(group);
    notifyListeners();
  }

  /// Returns the [Group] assigned for the given [date] based on monthly rotation.
  Group? groupForDate(DateTime date) {
    if (_groups.isEmpty) return null;
    final months = date.difference(_rotationStart).inDays ~/ 30;
    final index = months % _groups.length;
    return _groups[index];
  }

  /// Simple example to add members to groups.
  void addMemberToGroup(Member member, Group group) {
    final idx = _groups.indexOf(group);
    if (idx == -1) return;
    _groups[idx].members.add(member);
    notifyListeners();
  }

  /// Example method to schedule a reminder notification for remote work.
  Future<void> scheduleForDate(DateTime date) async {
    final group = groupForDate(date);
    if (group == null) return;
    await _notifications.scheduleNotification(
      date,
      'Trabajo remoto',
      'Grupo ${group.name} trabaja de forma remota',
      date.millisecondsSinceEpoch ~/ 1000,
    );
  }
}
