import 'package:formz/formz.dart';

enum PasswordValidationError { empty, tooShort, noUppercase, noNumber }

class PasswordInput extends FormzInput<String, PasswordValidationError> {
  const PasswordInput.pure() : super.pure('');
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.empty;
    if (value.length < 8) return PasswordValidationError.tooShort;
    if (!value.contains(RegExp(r'[A-Z]'))) return PasswordValidationError.noUppercase;
    if (!value.contains(RegExp(r'[0-9]'))) return PasswordValidationError.noNumber;
    return null;
  }
}

extension PasswordValidationErrorX on PasswordValidationError {
  String get text {
    switch (this) {
      case PasswordValidationError.empty:
        return "Password can't be empty";
      case PasswordValidationError.tooShort:
        return 'Password must be at least 8 characters';
      case PasswordValidationError.noUppercase:
        return 'Password must have at least one uppercase letter';
      case PasswordValidationError.noNumber:
        return 'Password must have at least one number';
    }
  }
}
