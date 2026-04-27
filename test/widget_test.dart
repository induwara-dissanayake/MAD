import 'package:flutter_test/flutter_test.dart';
import 'package:village_connect/core/utils/validators.dart';

void main() {
  group('Village Connect validators', () {
    test('accepts old and new Sri Lankan NIC formats', () {
      expect(Validators.validateNic('987654321V'), isNull);
      expect(Validators.validateNic('200012345678'), isNull);
    });

    test('derives the Firebase Auth email from the NIC username', () {
      expect(
        Validators.nicToEmail('987654321V'),
        '987654321v@villageconnect.local',
      );
    });
  });
}
