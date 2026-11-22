/// A single requirement a new password must satisfy.
enum PasswordRule {
  minLength,
  upperAndLowercase,
  number,
  symbol;

  static const int minimumLength = 8;

  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _symbol = RegExp(r'[^A-Za-z0-9\s]');

  bool isSatisfiedBy(String password) {
    switch (this) {
      case PasswordRule.minLength:
        return password.length >= minimumLength;
      case PasswordRule.upperAndLowercase:
        return _upper.hasMatch(password) && _lower.hasMatch(password);
      case PasswordRule.number:
        return _digit.hasMatch(password);
      case PasswordRule.symbol:
        return _symbol.hasMatch(password);
    }
  }
}

/// Password policy for new accounts. Single source of truth for both the
/// register form validator and the live requirements checklist.
class PasswordPolicy {
  PasswordPolicy._();

  static const List<PasswordRule> rules = PasswordRule.values;

  static int satisfiedCount(String password) =>
      rules.where((rule) => rule.isSatisfiedBy(password)).length;

  static bool isValid(String password) =>
      rules.every((rule) => rule.isSatisfiedBy(password));
}
