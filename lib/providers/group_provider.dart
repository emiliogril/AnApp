import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../services/notification_service.dart';
import 'dart:math';

class GroupProvider extends ChangeNotifier {
  final List<Group> _groups = [];
  DateTime _rotationStart = DateTime.now();
  final NotificationService _notifications = NotificationService();
  final Map<DateTime, Group> _manualAssignments = {};
  final Set<DateTime> _holidays = {};
  final Map<DateTime, List<Group>> _weeklyManualOrder = {};

  List<Group> get groups => List.unmodifiable(_groups);
  DateTime get rotationStart => _rotationStart;

  /// Sets the start date for rotation. Mainly used for testing.
  void setRotationStart(DateTime date) {
    _rotationStart = date;
    notifyListeners();
  }

  void addGroup(Group group) {
    if (_groups.any((g) => g.id == group.id)) {
      throw Exception('Ya existe un grupo con ese ID');
    }
    _groups.add(group);
    notifyListeners();
  }

  void removeGroup(Group group) {
    _groups.remove(group);
    notifyListeners();
  }

  void assignGroupToDate(DateTime date, Group group) {
    final key = DateTime(date.year, date.month, date.day);
    _manualAssignments[key] = group;
    final weekStart =
        key.subtract(Duration(days: key.weekday - DateTime.monday));
    List<DateTime> businessDays = [];
    DateTime d = weekStart;
    for (int i = 0; i < 7; i++) {
      if (d.weekday != DateTime.saturday &&
          d.weekday != DateTime.sunday &&
          !isHoliday(d)) {
        businessDays.add(d);
      }
      d = d.add(const Duration(days: 1));
    }
    List<Group> currentOrder = List<Group>.from(_groups);
    if (_weeklyManualOrder.containsKey(weekStart)) {
      currentOrder = List<Group>.from(_weeklyManualOrder[weekStart]!);
    } else {
      DateTime startWeek = _rotationStart
          .subtract(Duration(days: _rotationStart.weekday - DateTime.monday));
      int weeksPassed = weekStart.difference(startWeek).inDays ~/ 7;
      for (int i = 0; i < weeksPassed; i++) {
        if (currentOrder.length > 1) {
          final first = currentOrder.removeAt(0);
          currentOrder.add(first);
        }
      }
    }
    int dayIndex = businessDays.indexWhere((d) => d == key);
    // Generar todas las permutaciones posibles de los grupos para los días hábiles
    List<Group> baseGroups = List<Group>.from(currentOrder);
    baseGroups.removeWhere((g) => g.id == group.id);
    List<Group> permGroups = [group, ...baseGroups];
    // Backtracking para encontrar la mejor permutación
    List<List<Group>> allPerms = [];
    void permute(List<Group> arr, int l) {
      if (l == arr.length - 1) {
        allPerms.add(List<Group>.from(arr));
        return;
      }
      for (int i = l; i < arr.length; i++) {
        arr = List<Group>.from(arr);
        Group tmp = arr[l];
        arr[l] = arr[i];
        arr[i] = tmp;
        permute(arr, l + 1);
      }
    }

    permute(permGroups, 0);
    // Obtener la semana anterior
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevOrder = _weeklyManualOrder[prevWeekStart];
    int minRepeats = businessDays.length + 1;
    List<Group> bestOrder = permGroups;
    for (final perm in allPerms) {
      int repeats = 0;
      if (prevOrder != null && prevOrder.length == perm.length) {
        for (int i = 0; i < perm.length; i++) {
          if (perm[i].id == prevOrder[i].id) repeats++;
        }
      }
      if (repeats < minRepeats) {
        minRepeats = repeats;
        bestOrder = perm;
        if (minRepeats == 0) break;
      }
    }
    _weeklyManualOrder[weekStart] = bestOrder;
    notifyListeners();
  }

  /// Rotación semanal avanzada: si hay un orden manual para la semana, usarlo como base para esa semana y las siguientes.
  Group? groupForDate(DateTime date) {
    if (_groups.isEmpty) return null;
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday)
      return null;

    // Calcular el inicio de la semana
    DateTime weekStart(DateTime d) =>
        d.subtract(Duration(days: d.weekday - DateTime.monday));
    final currentWeek = weekStart(date);
    DateTime startWeek = weekStart(_rotationStart);
    int weeksPassed = currentWeek.difference(startWeek).inDays ~/ 7;

    // Rotar la lista de grupos según las semanas transcurridas
    List<Group> rotated = List<Group>.from(_groups);
    for (int i = 0; i < weeksPassed; i++) {
      final first = rotated.removeAt(0);
      rotated.add(first);
    }

    // Índice del día hábil en la semana (lunes=0, martes=1, ...)
    int dayIndex = date.weekday - DateTime.monday;
    if (dayIndex < 0 || dayIndex >= rotated.length) return null;
    return rotated[dayIndex];
  }

  /// Add a member to a group.
  void addMemberToGroup(Member member, Group group) {
    final idx = _groups.indexOf(group);
    if (idx == -1) return;

    final currentGroup = _groups[idx];
    if (currentGroup.members.any((m) => m.id == member.id)) {
      throw Exception('El miembro ya está en este grupo');
    }

    final updatedGroup = currentGroup.copyWith(
      members: [...currentGroup.members, member],
    );
    _groups[idx] = updatedGroup;
    notifyListeners();
  }

  /// Remove a member from a group.
  void removeMemberFromGroup(Member member, Group group) {
    final idx = _groups.indexOf(group);
    if (idx == -1) return;

    final currentGroup = _groups[idx];
    final updatedGroup = currentGroup.copyWith(
      members: currentGroup.members.where((m) => m.id != member.id).toList(),
    );
    _groups[idx] = updatedGroup;
    notifyListeners();
  }

  /// Schedule a reminder notification for remote work.
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

  void removeManualAssignment(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    if (_manualAssignments.containsKey(key)) {
      _manualAssignments.remove(key);
      notifyListeners();
    }
  }

  void markHoliday(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    _holidays.add(key);
    notifyListeners();
  }

  void unmarkHoliday(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    if (_holidays.contains(key)) {
      _holidays.remove(key);
      notifyListeners();
    }
  }

  bool isHoliday(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _holidays.contains(key);
  }

  List<Group> _findBestWeekOrder(
      List<Group> baseOrder, List<Group>? prevOrder) {
    // Generar todas las permutaciones posibles
    List<List<Group>> allPerms = [];
    void permute(List<Group> arr, int l) {
      if (l == arr.length - 1) {
        allPerms.add(List<Group>.from(arr));
        return;
      }
      for (int i = l; i < arr.length; i++) {
        arr = List<Group>.from(arr);
        Group tmp = arr[l];
        arr[l] = arr[i];
        arr[i] = tmp;
        permute(arr, l + 1);
      }
    }

    permute(baseOrder, 0);
    int minRepeats = baseOrder.length + 1;
    List<Group> bestOrder = baseOrder;
    for (final perm in allPerms) {
      int repeats = 0;
      if (prevOrder != null && prevOrder.length == perm.length) {
        for (int i = 0; i < perm.length; i++) {
          if (perm[i].id == prevOrder[i].id) repeats++;
        }
      }
      if (repeats < minRepeats) {
        minRepeats = repeats;
        bestOrder = perm;
        if (minRepeats == 0) break;
      }
    }
    return bestOrder;
  }
}
