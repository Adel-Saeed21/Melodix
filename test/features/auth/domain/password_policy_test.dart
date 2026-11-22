import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/auth/domain/validators/password_policy.dart';

void main() {
  group('PasswordRule', () {
    test('minLength needs 8 characters', () {
      expect(PasswordRule.minLength.isSatisfiedBy('Ab1!xyz'), isFalse);
      expect(PasswordRule.minLength.isSatisfiedBy('Ab1!wxyz'), isTrue);
    });

    test('upperAndLowercase needs both cases', () {
      expect(PasswordRule.upperAndLowercase.isSatisfiedBy('abcdef'), isFalse);
      expect(PasswordRule.upperAndLowercase.isSatisfiedBy('ABCDEF'), isFalse);
      expect(PasswordRule.upperAndLowercase.isSatisfiedBy('aBcdef'), isTrue);
    });

    test('number needs a digit', () {
      expect(PasswordRule.number.isSatisfiedBy('abcdef'), isFalse);
      expect(PasswordRule.number.isSatisfiedBy('abc3ef'), isTrue);
    });

    test('symbol needs a non-alphanumeric character, not a space', () {
      expect(PasswordRule.symbol.isSatisfiedBy('abc def'), isFalse);
      expect(PasswordRule.symbol.isSatisfiedBy('abc#def'), isTrue);
    });
  });

  group('PasswordPolicy', () {
    test('counts satisfied rules', () {
      expect(PasswordPolicy.satisfiedCount(''), 0);
      expect(PasswordPolicy.satisfiedCount('abc1'), 1);
      expect(PasswordPolicy.satisfiedCount('Abcdefg1'), 3);
    });

    test('isValid only when every rule passes', () {
      expect(PasswordPolicy.isValid('Abcdefg1'), isFalse);
      expect(PasswordPolicy.isValid('Abcdef1!'), isTrue);
    });
  });
}
