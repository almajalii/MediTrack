import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/style/colors.dart';

class AcceptInvitationScreen extends StatefulWidget {
  const AcceptInvitationScreen({super.key});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final tokenController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isValidating = false;

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  void _validateAndAcceptInvitation() {
    if (formKey.currentState!.validate()) {
      setState(() => isValidating = true);

      // First validate the token
      context.read<FamilyBloc>().add(
        ValidateInvitationEvent(tokenController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join Family',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is InvitationValidatedState) {
            setState(() => isValidating = false);
            if (!state.isValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Invalid invitation'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            } else if (state.invitation != null) {
              _showAcceptConfirmationDialog(state.invitation!);
            }
          } else if (state is InvitationAcceptedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully joined the family!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is FamilyErrorState) {
            setState(() => isValidating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDarkMode ? 0.15 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add_outlined,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Join a Family Group',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey[200] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the invitation code sent by your family owner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDarkMode ? Colors.grey[500] : AppColors.indigoGray,
                  ),
                ),
                const SizedBox(height: 28),

                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: tokenController,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Paste your invitation code here',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    maxLines: 1,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an invitation code';
                      }
                      if (value.trim().length < 10) {
                        return 'Invalid invitation code';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: isValidating ? null : _validateAndAcceptInvitation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      color: isValidating
                          ? AppColors.primary.withValues(alpha: 0.6)
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isValidating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Join Family',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'How to get an invite code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildInfoItem('Ask the family owner to invite you', isDarkMode),
                      _buildInfoItem('They copy the code from their invite list', isDarkMode),
                      _buildInfoItem('Paste the code above and tap Join', isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[500] : AppColors.indigoGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptConfirmationDialog(invitation) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDarkMode ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                'Join this Family?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[200] : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You\'ll be able to share medicine tracking with family members.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDarkMode ? Colors.grey[500] : AppColors.indigoGray,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (user != null) {
                        context.read<FamilyBloc>().add(
                          AcceptInvitationEvent(
                            invitationToken: tokenController.text.trim(),
                            userId: user!.uid,
                            displayName: user!.displayName ?? user!.email ?? '',
                            email: user!.email ?? '',
                          ),
                        );
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Accept & Join',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
