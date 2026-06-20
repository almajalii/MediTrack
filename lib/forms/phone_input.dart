import 'package:formz/formz.dart';

enum PhoneValidationError { empty, invalid }

class PhoneInput extends FormzInput<String, PhoneValidationError> {
  const PhoneInput.pure() : super.pure('');
  const PhoneInput.dirty([super.value = '']) : super.dirty();

  static final _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

  @override
  PhoneValidationError? validator(String value) {
    if (value.isEmpty) return PhoneValidationError.empty;
    final normalized = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!_phoneRegex.hasMatch(normalized)) return PhoneValidationError.invalid;
    return null;
  }
}

extension PhoneValidationErrorX on PhoneValidationError {
  String get text {
    switch (this) {
      case PhoneValidationError.empty:
        return "Phone number can't be empty";
      case PhoneValidationError.invalid:
        return 'Enter a valid phone number';
    }
  }
}
