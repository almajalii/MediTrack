import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formz/formz.dart';
import 'package:meditrack/forms/confirm_password_input.dart';
import 'package:meditrack/forms/email_input.dart';
import 'package:meditrack/forms/name_input.dart';
import 'package:meditrack/forms/password_input.dart';
import 'package:meditrack/forms/phone_input.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc() : super(const SignupState()) {
    on<SignupNameChanged>(_onNameChanged);
    on<SignupEmailChanged>(_onEmailChanged);
    on<SignupPhoneChanged>(_onPhoneChanged);
    on<SignupPasswordChanged>(_onPasswordChanged);
    on<SignupConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<SignupSubmitted>(_onSubmitted);
  }

  void _onNameChanged(SignupNameChanged event, Emitter<SignupState> emit) {
    emit(state.copyWith(name: NameInput.dirty(event.name)));
  }

  void _onEmailChanged(SignupEmailChanged event, Emitter<SignupState> emit) {
    emit(state.copyWith(email: EmailInput.dirty(event.email)));
  }

  void _onPhoneChanged(SignupPhoneChanged event, Emitter<SignupState> emit) {
    emit(state.copyWith(phone: PhoneInput.dirty(event.phone)));
  }

  void _onPasswordChanged(SignupPasswordChanged event, Emitter<SignupState> emit) {
    // Re-validate confirm password against the new password if already dirty
    final confirmPassword = state.confirmPassword.isPure
        ? state.confirmPassword
        : ConfirmPasswordInput.dirty(
            value: state.confirmPassword.value,
            password: event.password,
          );
    emit(state.copyWith(
      password: PasswordInput.dirty(event.password),
      confirmPassword: confirmPassword,
    ));
  }

  void _onConfirmPasswordChanged(
      SignupConfirmPasswordChanged event, Emitter<SignupState> emit) {
    emit(state.copyWith(
      confirmPassword: ConfirmPasswordInput.dirty(
        value: event.confirmPassword,
        password: state.password.value,
      ),
    ));
  }

  Future<void> _onSubmitted(
      SignupSubmitted event, Emitter<SignupState> emit) async {
    // Mark all fields dirty to trigger validation display
    final name = NameInput.dirty(state.name.value);
    final email = EmailInput.dirty(state.email.value);
    final phone = PhoneInput.dirty(state.phone.value);
    final password = PasswordInput.dirty(state.password.value);
    final confirmPassword = ConfirmPasswordInput.dirty(
      value: state.confirmPassword.value,
      password: state.password.value,
    );

    emit(state.copyWith(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
    ));

    if (!Formz.validate([name, email, phone, password, confirmPassword])) return;

    emit(state.copyWith(status: SignupStatus.loading));

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: state.email.value.trim(),
        password: state.password.value.trim(),
      );

      await credential.user?.updateDisplayName(state.name.value.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': state.email.value.trim(),
        'phonenumber': state.phone.value.trim(),
        'displayName': state.name.value.trim(),
        'allergies': '',
        'medicalConditions': '',
        'emergencyContact': '',
      });

      emit(state.copyWith(status: SignupStatus.success));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: SignupStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SignupStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
