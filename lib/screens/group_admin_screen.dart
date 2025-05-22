import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';
import '../models/member.dart';

class GroupAdminScreen extends StatefulWidget {
  static const routeName = '/groups';
  const GroupAdminScreen({Key? key}) : super(key: key);

  @override
  State<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends State<GroupAdminScreen> {
  final _controller = TextEditingController();
  final Map<String, TextEditingController> _memberControllers = {};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GroupProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Grupos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del grupo',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final name = _controller.text.trim();
                    if (name.isEmpty) return;
                    provider.addGroup(Group(id: name, name: name));
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                const Text('Inicio de rotación: '),
                Text(
                  '${provider.rotationStart.day.toString().padLeft(2, '0')}/'
                  '${provider.rotationStart.month.toString().padLeft(2, '0')}/'
                  '${provider.rotationStart.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Cambiar'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: provider.rotationStart,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      final isWeekend = picked.weekday == DateTime.saturday ||
                          picked.weekday == DateTime.sunday;
                      final isHoliday = provider.isHoliday(picked);
                      if (isWeekend || isHoliday) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'El inicio de rotación no puede ser fin de semana ni feriado.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      provider.setRotationStart(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.groups.length,
              itemBuilder: (context, index) {
                final group = provider.groups[index];
                _memberControllers.putIfAbsent(
                    group.id, () => TextEditingController());
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ExpansionTile(
                    title: Text(group.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => provider.removeGroup(group),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _memberControllers[group.id],
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del miembro',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_add),
                              onPressed: () {
                                final name =
                                    _memberControllers[group.id]!.text.trim();
                                if (name.isEmpty) return;
                                provider.addMemberToGroup(
                                  Member(id: name, name: name),
                                  group,
                                );
                                _memberControllers[group.id]!.clear();
                              },
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: group.members.length,
                        itemBuilder: (context, mIndex) {
                          final member = group.members[mIndex];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.person),
                            title: Text(member.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                provider.removeMemberFromGroup(member, group);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
