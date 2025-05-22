import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/group_provider.dart';
import 'group_admin_screen.dart';

class CalendarScreen extends StatelessWidget {
  static const routeName = '/calendar';
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GroupProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Rotación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed:
                () => Navigator.pushNamed(context, GroupAdminScreen.routeName),
          ),
        ],
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final group = provider.groupForDate(day);
            if (group == null) return null;
            return Center(child: Text(group.name));
          },
        ),
      ),
    );
  }
}
