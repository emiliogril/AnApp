import 'member.dart';

class Group {
  final String id;
  final String name;
  final List<Member> members;

  Group({required this.id, required this.name, this.members = const []});
}
