import 'member.dart';

class Group {
  final String id;
  final String name;
  final List<Member> _members;

  Group({
    required this.id,
    required this.name,
    List<Member>? members,
  }) : _members = members ?? [];

  List<Member> get members => List.unmodifiable(_members);

  Group copyWith({
    String? id,
    String? name,
    List<Member>? members,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? _members,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
