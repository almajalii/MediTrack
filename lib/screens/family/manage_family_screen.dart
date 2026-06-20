import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/family_invitation.dart';
import 'package:meditrack/model/family_member.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/screens/main/home/navigation_main.dart';

class ManageFamilyScreen extends StatefulWidget {
  const ManageFamilyScreen({super.key});

  @override
  State<ManageFamilyScreen> createState() => _ManageFamilyScreenState();
}

class _ManageFamilyScreenState extends State<ManageFamilyScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      context.read<FamilyBloc>().add(LoadFamilyAccountEvent(user!.uid));
    }
  }

  void _loadPendingInvitations(String familyAccountId) {
    context.read<FamilyBloc>().add(LoadPendingInvitationsEvent(familyAccountId));
  }

  // Navigate back to home screen
  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const NavigationMain()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _navigateToHome),
        title: const Text('Family Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyAccountCreatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Family account created successfully!'), backgroundColor: Colors.green),
            );
          } else if (state is FamilyErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("error"), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is FamilyLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NoFamilyAccountState) {
            return _buildNoFamilyUI(isDarkMode);
          }

          if (state is FamilyAccountLoadedState) {
            _loadPendingInvitations(state.familyAccount.id);
            return _buildFamilyAccountUI(state, isDarkMode);
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildNoFamilyUI(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDarkMode ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_alt_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Family Group Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[200] : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create a group to share medicine tracking with your family members.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5, color: isDarkMode ? Colors.grey[500] : AppColors.indigoGray),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateFamilyDialog(context, isDarkMode),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create Family Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyAccountUI(FamilyAccountLoadedState state, bool isDarkMode) {
    final isOwner = state.members.any((m) => m.userId == user?.uid && m.role == MemberRole.owner);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family Account Card
          Card(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, color: AppColors.primary, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.familyAccount.familyName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                        Text(
                          '${state.members.length} member${state.members.length != 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                      tooltip: 'Delete Family Account',
                      onPressed: () => _confirmDeleteFamilyAccount(context, state.familyAccount.id),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Family Members Section
          Text(
            'Family Members',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[300] : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Member list
          ...state.members.map((member) {
            final isCurrentUser = member.userId == user?.uid;
            return Card(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.displayName.isEmpty ? 'Unknown' : member.displayName,
                      style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.black87),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  member.email,
                  style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            member.role == MemberRole.owner
                                ? Colors.amber.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member.role == MemberRole.owner ? 'Owner' : 'Member',
                        style: TextStyle(
                          fontSize: 11,
                          color: member.role == MemberRole.owner ? Colors.amber[700] : Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.medication, size: 20),
                      color: AppColors.primary,
                      onPressed: () => _showMemberMedicines(context, member, isDarkMode),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          // Invite Member button (owner only)
          if (isOwner) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => _showInviteMemberDialog(context, state.familyAccount.id, isDarkMode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Invite Member',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Pending Invitations (only shown when there are any)
          if (isOwner)
            BlocBuilder<FamilyBloc, FamilyState>(
              builder: (context, familyState) {
                if (familyState is! FamilyAccountLoadedState) return const SizedBox.shrink();
                final invitations = familyState.pendingInvitations;
                if (invitations.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Pending Invitations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...invitations.map(
                      (invitation) => Card(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.mail_outline, color: Colors.orange),
                          title: Text(
                            invitation.invitedEmail,
                            style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.black87),
                          ),
                          subtitle: Text(
                            'Invited ${_formatDate(invitation.createdAt)}',
                            style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                color: AppColors.primary,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: invitation.invitationToken));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invitation code copied!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  context.read<FamilyBloc>().add(
                                    DeleteInvitationEvent(
                                      familyAccountId: state.familyAccount.id,
                                      invitationId: invitation.id,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invitation cancelled'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Show member's medicines (READ-ONLY)
  void _showMemberMedicines(BuildContext context, FamilyMember member, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _MemberMedicinesSheet(member: member, scrollController: scrollController, isDarkMode: isDarkMode);
          },
        );
      },
    );
  }

  void _showCreateFamilyDialog(BuildContext context, bool isDarkMode) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
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
                      'Create Family Group',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey[200] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Give your family group a name',
                      style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[500] : AppColors.indigoGray),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'e.g., The Smiths',
                        prefixIcon: const Icon(Icons.group_outlined, color: AppColors.primary, size: 20),
                        hintStyle: TextStyle(color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
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
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a family name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (formKey.currentState!.validate() && user != null) {
                              context.read<FamilyBloc>().add(
                                CreateFamilyAccountEvent(
                                  userId: user!.uid,
                                  familyName: nameController.text.trim(),
                                  displayName: user!.displayName ?? user!.email ?? '',
                                  primaryContactEmail: user!.email ?? '',
                                  primaryContactPhone: null,
                                ),
                              );
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Text(
                              'Create',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showInviteMemberDialog(BuildContext context, String familyAccountId, bool isDarkMode) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDarkMode ? 0.15 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_outlined, color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Invite a Member',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey[200] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter their email to send an invite code',
                      style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[500] : AppColors.indigoGray),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailController,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'name@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                        hintStyle: TextStyle(color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
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
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              context.read<FamilyBloc>().add(
                                SendInvitationEvent(
                                  familyAccountId: familyAccountId,
                                  invitedBy: user!.uid,
                                  invitedEmail: emailController.text.trim(),
                                  invitationType: InvitationType.email,
                                ),
                              );
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invitation sent successfully!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Text(
                              'Invite',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _confirmDeleteFamilyAccount(BuildContext context, String familyAccountId) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
            title: const Text('Delete Family Account?', style: TextStyle(color: Colors.red)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Are you sure you want to delete this family account?'),
                  SizedBox(height: 12),
                  Text('This will:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('• Remove all family members'),
                  Text('• Cancel all pending invitations'),
                  Text('• Delete the family account permanently'),
                  SizedBox(height: 12),
                  Text(
                    'This action cannot be undone.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (user != null) {
                    context.read<FamilyBloc>().add(
                      DeleteFamilyAccountEvent(familyAccountId: familyAccountId, userId: user!.uid),
                    );
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Family account deleted'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

// Separate widget for the medicines sheet
class _MemberMedicinesSheet extends StatefulWidget {
  final FamilyMember member;
  final ScrollController scrollController;
  final bool isDarkMode;

  const _MemberMedicinesSheet({required this.member, required this.scrollController, required this.isDarkMode});

  @override
  State<_MemberMedicinesSheet> createState() => _MemberMedicinesSheetState();
}

class _MemberMedicinesSheetState extends State<_MemberMedicinesSheet> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Load medicines immediately and only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        context.read<MedicineBloc>().add(LoadMedicinesEvent(widget.member.userId));
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  widget.member.displayName.isNotEmpty ? widget.member.displayName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.member.displayName}\'s Medicines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    Text(
                      'Read-only view',
                      style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 8),

          // Medicine list
          Expanded(
            child: BlocBuilder<MedicineBloc, MedicineState>(
              builder: (context, state) {
                if (state is MedicineLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MedicineLoadedState) {
                  if (state.medicines.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No medicines found',
                            style: TextStyle(color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: widget.scrollController,
                    itemCount: state.medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = state.medicines[index];
                      return Card(
                        color: widget.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading:
                              (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      medicine.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.medication, color: AppColors.primary),
                                        );
                                      },
                                    ),
                                  )
                                  : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.medication, color: AppColors.primary),
                                  ),
                          title: Text(
                            medicine.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (medicine.type.isNotEmpty)
                                Text(
                                  medicine.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                              Text(
                                'Quantity: ${medicine.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return Center(
                  child: Text(
                    'Unable to load medicines',
                    style: TextStyle(color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
