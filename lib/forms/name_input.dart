import 'package:formz/formz.dart';

enum NameValidationError { empty }

class NameInput extends FormzInput<String, NameValidationError> {
  const NameInput.pure() : super.pure('');
  const NameInput.dirty([super.value = '']) : super.dirty();

  @override
  NameValidationError? validator(String value) {
    return value.trim().isEmpty ? NameValidationError.empty : null;
  }
}

extension NameValidationErrorX on NameValidationError {
  String get text => "Name can't be empty";
}
