import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/group_provider.dart';
import '../models/group.dart';
import 'group_admin_screen.dart';

class CalendarScreen extends StatefulWidget {
  static const routeName = '/calendar';
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<void> _showAssignGroupDialog(
      BuildContext context, DateTime date) async {
    final provider = Provider.of<GroupProvider>(context, listen: false);
    final groups = provider.groups;
    if (groups.isEmpty) return;
    final currentGroup = provider.groupForDate(date);
    Group? selectedGroup = currentGroup;
    final isHoliday = provider.isHoliday(date);

    // Calcular la semana anterior
    DateTime weekStart(DateTime d) =>
        d.subtract(Duration(days: d.weekday - DateTime.monday));
    final prevWeekStart = weekStart(date).subtract(const Duration(days: 7));
    List<Map<String, dynamic>> prevWeekGroups = [];
    DateTime d = prevWeekStart;
    for (int i = 0; i < 5; i++) {
      final g = provider.groupForDate(d);
      if (g != null) {
        prevWeekGroups.add({
          'date': d,
          'group': g,
        });
      }
      d = d.add(const Duration(days: 1));
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Opciones para la fecha'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentGroup != null) ...[
                  Text('Grupo asignado: ${currentGroup.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (currentGroup.members.isNotEmpty)
                    ...currentGroup.members.map((m) => Row(
                          children: [
                            const Icon(Icons.person, size: 18),
                            const SizedBox(width: 4),
                            Text(m.name),
                          ],
                        )),
                  if (currentGroup.members.isEmpty)
                    const Text('Sin miembros en este grupo'),
                  const Divider(),
                ],
                if (prevWeekGroups.isNotEmpty) ...[
                  const Text('Rotación semana anterior:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...prevWeekGroups.map((info) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${[
                                'Lun',
                                'Mar',
                                'Mié',
                                'Jue',
                                'Vie'
                              ][info['date'].weekday - 1]}: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(info['group'].name),
                            if (info['group'].members.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  children: info['group']
                                      .members
                                      .map<Widget>((m) => Chip(
                                          label: Text(m.name),
                                          visualDensity: VisualDensity.compact))
                                      .toList(),
                                ),
                              ),
                            ]
                          ],
                        ),
                      )),
                  const Divider(),
                ],
                DropdownButton<Group>(
                  isExpanded: true,
                  value: selectedGroup,
                  items: groups
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.name),
                          ))
                      .toList(),
                  onChanged: isHoliday
                      ? null
                      : (g) {
                          setState(() {
                            selectedGroup = g;
                          });
                          Navigator.of(context).pop(g);
                        },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(
                      isHoliday ? Icons.event_available : Icons.event_busy),
                  label: Text(
                      isHoliday ? 'Quitar feriado' : 'Marcar como feriado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isHoliday ? Colors.green : Colors.orange,
                  ),
                  onPressed: () {
                    if (isHoliday) {
                      provider.unmarkHoliday(date);
                    } else {
                      provider.markHoliday(date);
                    }
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 16),
                if (provider.groupForDate(date) != null &&
                    provider.groupForDate(date) == provider.groupForDate(date))
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Quitar asignación manual'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      provider.removeManualAssignment(date);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    ).then((g) {
      if (g != null && g is Group && !provider.isHoliday(date)) {
        provider.assignGroupToDate(date, g);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GroupProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Rotación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () =>
                Navigator.pushNamed(context, GroupAdminScreen.routeName),
          ),
        ],
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        onDaySelected: (selectedDay, focusedDay) async {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          await _showAssignGroupDialog(context, selectedDay);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            if (provider.isHoliday(day)) {
              return Center(
                child: Icon(Icons.beach_access, color: Colors.orange),
              );
            }
            final group = provider.groupForDate(day);
            if (group == null) return null;
            return Center(
              child: Text(
                group.name,
                style: TextStyle(
                  color: isSameDay(day, _selectedDay) ? Colors.white : null,
                ),
              ),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            if (provider.isHoliday(day)) {
              return Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.beach_access, color: Colors.white),
                ),
              );
            }
            final group = provider.groupForDate(day);
            if (group == null) return null;
            return Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  group.name,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
