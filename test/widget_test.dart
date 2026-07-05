// Unit tests for pure-Dart app logic (no Firebase dependency).
//
// The previous file here was the Flutter template's counter smoke test, which
// fails against this app (there is no counter, and PetPalApp needs Firebase).
// Backend behavior — Firestore rules, Storage rules, Cloud Functions — is
// covered by the emulator suites under functions/test/ (`npm test` from
// functions/, requires JDK 21+).

import 'package:flutter_test/flutter_test.dart';

import 'package:petpal/core/utils/validators.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';

void main() {
  group('Validators.validateEmail', () {
    test('accepts a normal address', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(Validators.validateEmail('  user@example.com  '), isNull);
    });

    test('rejects empty input', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.validateEmail('not-an-email'), isNotNull);
      expect(Validators.validateEmail('a@b'), isNotNull);
      expect(Validators.validateEmail('a b@c.com'), isNotNull);
    });
  });

  group('Validators.validatePassword', () {
    test('accepts 6+ characters', () {
      expect(Validators.validatePassword('123456'), isNull);
    });

    test('rejects short or empty passwords', () {
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword(null), isNotNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('accepts matching passwords', () {
      expect(Validators.validateConfirmPassword('secret1', 'secret1'), isNull);
    });

    test('rejects mismatch and empty confirmation', () {
      expect(
          Validators.validateConfirmPassword('secret1', 'secret2'), isNotNull);
      expect(Validators.validateConfirmPassword('secret1', ''), isNotNull);
    });
  });

  group('UserRole.fromString', () {
    test('parses every storage variant', () {
      expect(UserRole.fromString('petOwner'), UserRole.petOwner);
      expect(UserRole.fromString('pet_owner'), UserRole.petOwner);
      expect(UserRole.fromString('serviceProvider'), UserRole.serviceProvider);
      expect(UserRole.fromString('service_provider'), UserRole.serviceProvider);
      expect(UserRole.fromString('provider'), UserRole.serviceProvider);
      expect(UserRole.fromString('admin'), UserRole.admin);
    });

    test('is case-insensitive and trims', () {
      expect(UserRole.fromString(' Admin '), UserRole.admin);
      expect(UserRole.fromString('PETOWNER'), UserRole.petOwner);
    });

    test('returns null for unknown or empty values', () {
      expect(UserRole.fromString('superuser'), isNull);
      expect(UserRole.fromString(''), isNull);
      expect(UserRole.fromString(null), isNull);
    });

    test('round-trips through firestoreValue', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromString(role.firestoreValue), role);
      }
    });
  });
}
