import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';

class GroupAdminScreen extends StatefulWidget {
  static const routeName = '/groups';
  const GroupAdminScreen({Key? key}) : super(key: key);

  @override
  State<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends State<GroupAdminScreen> {
  final _controller = TextEditingController();

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
          Expanded(
            child: ListView.builder(
              itemCount: provider.groups.length,
              itemBuilder: (context, index) {
                final group = provider.groups[index];
                return ListTile(
                  title: Text(group.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.removeGroup(group),
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
