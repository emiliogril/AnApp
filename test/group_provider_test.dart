import 'package:flutter_test/flutter_test.dart';
import 'package:anapp/providers/group_provider.dart';
import 'package:anapp/models/group.dart';

void main() {
  group('GroupProvider monthly rotation', () {
    late GroupProvider provider;
    final groupA = Group(id: 'a', name: 'A');
    final groupB = Group(id: 'b', name: 'B');

    setUp(() {
      provider = GroupProvider();
      provider.addGroup(groupA);
      provider.addGroup(groupB);
    });

    test('handles 31-day month', () {
      provider.setRotationStart(DateTime(2023, 1, 1));
      final result = provider.groupForDate(DateTime(2023, 2, 1));
      expect(result, groupB);
    });

    test('handles 28-day month', () {
      provider.setRotationStart(DateTime(2023, 2, 1));
      final result = provider.groupForDate(DateTime(2023, 3, 1));
      expect(result, groupB);
    });

    test('handles 30-day month', () {
      provider.setRotationStart(DateTime(2023, 4, 1));
      final result = provider.groupForDate(DateTime(2023, 5, 1));
      expect(result, groupB);
    });
  });
}
