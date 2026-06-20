part of 'signup_bloc.dart';

enum SignupStatus { initial, loading, success, failure }

final class SignupState extends Equatable {
  const SignupState({
    this.name = const NameInput.pure(),
    this.email = const EmailInput.pure(),
    this.phone = const PhoneInput.pure(),
    this.password = const PasswordInput.pure(),
    this.confirmPassword = const ConfirmPasswordInput.pure(),
    this.status = SignupStatus.initial,
    this.errorMessage,
  });

  final NameInput name;
  final EmailInput email;
  final PhoneInput phone;
  final PasswordInput password;
  final ConfirmPasswordInput confirmPassword;
  final SignupStatus status;
  final String? errorMessage;

  bool get isValid =>
      Formz.validate([name, email, phone, password, confirmPassword]);

  SignupState copyWith({
    NameInput? name,
    EmailInput? email,
    PhoneInput? phone,
    PasswordInput? password,
    ConfirmPasswordInput? confirmPassword,
    SignupStatus? status,
    String? errorMessage,
  }) {
    return SignupState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [name, email, phone, password, confirmPassword, status, errorMessage];
}
