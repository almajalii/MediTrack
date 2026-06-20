import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:meditrack/bloc/login_bloc/login_bloc.dart';
import 'package:meditrack/forms/email_input.dart';
import 'package:meditrack/forms/password_input.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/screens/auth/signup_screen.dart';
import 'package:meditrack/screens/main/home/navigation_main.dart';
import 'package:meditrack/services/account_manager.dart';
import 'package:meditrack/style/colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  final _accountManager = AccountManager();
  final _myTextField = MyTextField();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLoginSuccess(LoginState state) async {
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

    if (!mounted) return;
    final savePassword = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Quick Account Switching'),
            content: const Text(
              'Save your password for quick switching between accounts?\n\n'
              'This allows you to switch accounts without re-entering your password.',
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No Thanks')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save')),
            ],
          ),
        ) ??
        false;

    if (savePassword && mounted) {
      await _accountManager.saveAccountPassword(
        state.email.value.trim(),
        state.password.value.trim(),
      );
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavigationMain()),
        (_) => false,
      );
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sending reset email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == LoginStatus.success) {
          _handleLoginSuccess(state);
        } else if (state.status == LoginStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${state.errorMessage ?? "Unknown error"}'),
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<LoginBloc>();
        final isLoading = state.status == LoginStatus.loading;

        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                      height: 200,
                      width: 200,
                      child: Image.asset('images/1.png')),
                  const SizedBox(height: 50),
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 300,
                    child: _myTextField.buildTextField(
                      'Email',
                      _emailController,
                      prefixIcon: Icons.person,
                      onChanged: (v) => bloc.add(LoginEmailChanged(v)),
                      errorText: state.email.displayError?.text,
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: _myTextField.buildTextField(
                      'Password',
                      _passwordController,
                      prefixIcon: Icons.password,
                      obscureText: true,
                      onChanged: (v) => bloc.add(LoginPasswordChanged(v)),
                      errorText: state.password.displayError?.text,
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:
                          isLoading ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => bloc.add(const LoginSubmitted()),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('LOGIN'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                          style: TextStyle(color: AppColors.darkGray)),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        ),
                        child: const Text('SIGNUP'),
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
