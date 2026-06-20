import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formz/formz.dart';
import 'package:meditrack/forms/email_input.dart';
import 'package:meditrack/forms/password_input.dart';
import 'package:meditrack/services/account_manager.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
  }

  final _accountManager = AccountManager();

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(
      email: EmailInput.dirty(event.email),
      status: LoginStatus.initial,
    ));
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(
      password: PasswordInput.dirty(event.password),
      status: LoginStatus.initial,
    ));
  }

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    // Mark all fields dirty so errors show even if untouched
    final email = EmailInput.dirty(state.email.value);
    final password = PasswordInput.dirty(state.password.value);
    emit(state.copyWith(email: email, password: password));

    if (!Formz.validate([email, password])) return;

    emit(state.copyWith(status: LoginStatus.loading));

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: state.email.value.trim(),
        password: state.password.value.trim(),
      );
      await _accountManager.saveCurrentAccount();
      emit(state.copyWith(status: LoginStatus.success));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.message,
      ));
    }
  }
}
