import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:meditrack/bloc/signup_bloc/signup_bloc.dart';
import 'package:meditrack/forms/name_input.dart';
import 'package:meditrack/forms/email_input.dart';
import 'package:meditrack/forms/phone_input.dart';
import 'package:meditrack/forms/password_input.dart';
import 'package:meditrack/forms/confirm_password_input.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/screens/main/home/navigation_main.dart';
import 'package:meditrack/screens/auth/login_screen.dart';
import 'package:meditrack/style/colors.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupBloc(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _myTextField = MyTextField();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignupSuccess(SignupState state) async {
    bool enableBiometrics = false;
    final canCheck = await _localAuth.canCheckBiometrics;
    final available = await _localAuth.getAvailableBiometrics();
    if (!mounted) return;

    if (canCheck && available.isNotEmpty) {
      enableBiometrics = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Enable Biometric Login?'),
              content: const Text('Use fingerprint or face ID next time?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes')),
              ],
            ),
          ) ??
          false;
    }

    if (enableBiometrics && mounted) {
      await _storage.write(key: 'biometric_enabled', value: 'true');
      await _storage.write(key: 'email', value: state.email.value.trim());
      await _storage.write(key: 'password', value: state.password.value.trim());
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful! Redirecting...')),
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavigationMain()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupBloc, SignupState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == SignupStatus.success) {
          _handleSignupSuccess(state);
        } else if (state.status == SignupStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signup failed: ${state.errorMessage ?? "Unknown error"}'),
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<SignupBloc>();
        final isLoading = state.status == SignupStatus.loading;

        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  SizedBox(
                      height: 200,
                      width: 200,
                      child: Image.asset('images/1.png')),
                  const SizedBox(height: 10),
                  Text(
                    'Create Your Account!',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: _myTextField.buildTextField(
                      'Username',
                      _usernameController,
                      prefixIcon: Icons.person,
                      onChanged: (v) => bloc.add(SignupNameChanged(v)),
                      errorText: state.name.displayError?.text,
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: _myTextField.buildTextField(
                      'Email',
                      _emailController,
                      prefixIcon: Icons.email,
                      onChanged: (v) => bloc.add(SignupEmailChanged(v)),
                      errorText: state.email.displayError?.text,
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: _myTextField.buildTextField(
                      'Phone Number',
                      _phoneController,
                      prefixIcon: Icons.phone,
                      onChanged: (v) => bloc.add(SignupPhoneChanged(v)),
                      errorText: state.phone.displayError?.text,
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: _myTextField.buildTextField(
                      'Password',
                      _passwordController,
                      prefixIcon: Icons.password,
                      obscureText: true,
                      onChanged: (v) => bloc.add(SignupPasswordChanged(v)),
                      errorText: state.password.displayError?.text,
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: _myTextField.buildTextField(
                      'Confirm Password',
                      _confirmPasswordController,
                      prefixIcon: Icons.password,
                      obscureText: true,
                      onChanged: (v) =>
                          bloc.add(SignupConfirmPasswordChanged(v)),
                      errorText: state.confirmPassword.displayError?.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => bloc.add(const SignupSubmitted()),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('REGISTER'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?',
                          style: TextStyle(color: AppColors.darkGray)),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        child: const Text('LOGIN'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
