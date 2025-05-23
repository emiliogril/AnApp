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
    final colorScheme = Theme.of(context).colorScheme;

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Opciones para ${date.day}/${date.month}/${date.year}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentGroup != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grupo asignado: ${currentGroup.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (currentGroup.members.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: currentGroup.members
                                  .map<Widget>((m) => Chip(
                                        avatar:
                                            const Icon(Icons.person, size: 16),
                                        label: Text(m.name),
                                        backgroundColor:
                                            colorScheme.surfaceVariant,
                                      ))
                                  .toList(),
                            ),
                          if (currentGroup.members.isEmpty)
                            const Text('Sin miembros en este grupo'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (prevWeekGroups.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rotación semana anterior:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...prevWeekGroups
                              .map<Widget>((info) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${[
                                            'Lun',
                                            'Mar',
                                            'Mié',
                                            'Jue',
                                            'Vie'
                                          ][info['date'].weekday - 1]}: ${info['group'].name}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (info['group'].members.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: info['group']
                                                .members
                                                .map<Widget>((m) => Chip(
                                                      label: Text(m.name),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      backgroundColor:
                                                          colorScheme
                                                              .surfaceVariant,
                                                    ))
                                                .toList(),
                                          ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<Group>(
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar grupo',
                            border: OutlineInputBorder(),
                          ),
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
                          icon: Icon(isHoliday
                              ? Icons.event_available
                              : Icons.event_busy),
                          label: Text(isHoliday
                              ? 'Quitar feriado'
                              : 'Marcar como feriado'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isHoliday ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
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
                        if (provider.groupForDate(date) != null &&
                            provider.groupForDate(date) ==
                                provider.groupForDate(date))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text('Quitar asignación manual'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                provider.removeManualAssignment(date);
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;

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
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar(
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
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: colorScheme.error),
                holidayTextStyle: TextStyle(color: colorScheme.error),
                todayDecoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (provider.isHoliday(day)) {
                    return Center(
                      child: Icon(
                        Icons.beach_access,
                        color: colorScheme.tertiary,
                        size: 20,
                      ),
                    );
                  }
                  final group = provider.groupForDate(day);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSameDay(day, _selectedDay)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (group != null)
                        Text(
                          group.name,
                          style: TextStyle(
                            color: isSameDay(day, _selectedDay)
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  if (provider.isHoliday(day)) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.beach_access, color: Colors.white),
                      ),
                    );
                  }
                  final group = provider.groupForDate(day);
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (group != null)
                            Text(
                              group.name,
                              style: TextStyle(
                                color: colorScheme.onPrimary.withOpacity(0.9),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
