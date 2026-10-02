import 'package:flutter_test/flutter_test.dart';
import 'package:konfide/core/models/companion.dart';

void main() {
  group('Companion model tests', () {
    test('default companion properties', () {
      final defaultComp = Companion.defaultCompanion;
      expect(defaultComp.id, Companion.defaultId);
      expect(defaultComp.name, 'General');
      expect(defaultComp.isDefault, isTrue);
      expect(defaultComp.initials, 'GE');
    });

    test('initials generation for multi-word and single-word names', () {
      final comp1 = Companion(
        id: '1',
        name: 'Sarah Connor',
        createdAt: DateTime.now(),
      );
      expect(comp1.initials, 'SC');

      final comp2 = Companion(
        id: '2',
        name: 'Joe',
        createdAt: DateTime.now(),
      );
      expect(comp2.initials, 'JO');
    });

    test('toJson and fromJson serialization', () {
      final original = Companion(
        id: 'comp_123',
        name: 'Mary Jane',
        createdAt: DateTime(2026, 1, 1),
        colorIndex: 3,
      );

      final json = original.toJson();
      final restored = Companion.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.colorIndex, original.colorIndex);
      expect(restored.createdAt, original.createdAt);
      expect(restored, original);
    });
  });
}
