part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

final class LoginState extends Equatable {
  const LoginState({
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.status = LoginStatus.initial,
    this.errorMessage,
  });

  final EmailInput email;
  final PasswordInput password;
  final LoginStatus status;
  final String? errorMessage;

  bool get isValid => Formz.validate([email, password]);

  LoginState copyWith({
    EmailInput? email,
    PasswordInput? password,
    LoginStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, password, status, errorMessage];
}
