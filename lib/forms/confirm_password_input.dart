import 'package:formz/formz.dart';

enum ConfirmPasswordValidationError { empty, mismatch }

class ConfirmPasswordInput extends FormzInput<String, ConfirmPasswordValidationError> {
  const ConfirmPasswordInput.pure()
      : _password = '',
        super.pure('');

  const ConfirmPasswordInput.dirty({
    required String value,
    required String password,
  })  : _password = password,
        super.dirty(value);

  final String _password;

  @override
  ConfirmPasswordValidationError? validator(String value) {
    if (value.isEmpty) return ConfirmPasswordValidationError.empty;
    if (value != _password) return ConfirmPasswordValidationError.mismatch;
    return null;
  }
}

extension ConfirmPasswordValidationErrorX on ConfirmPasswordValidationError {
  String get text {
    switch (this) {
      case ConfirmPasswordValidationError.empty:
        return 'Please confirm your password';
      case ConfirmPasswordValidationError.mismatch:
        return 'Passwords do not match';
    }
  }
}
