import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/user_feedback.dart';
import 'package:meditrack/style/colors.dart';

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({super.key});

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  bool _isSubmitting = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit feedback'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedback = UserFeedback(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userEmail: user.email ?? '',
        category: _selectedCategory,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        submittedAt: DateTime.now(),
        status: 'pending',
      );

      await _firestore.collection('feedback').add(feedback.toFirestore());

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Thank You!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your feedback has been submitted successfully.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Text(
                  'We appreciate you taking the time to help us improve MediTrack.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Our team will review your feedback shortly.',
                          style: TextStyle(fontSize: 13, color: AppColors.darkBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)])
                : const LinearGradient(
                    colors: [AppColors.darkBlue, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)])
                      : const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF007FA8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.feedback_outlined,
                        color: isDarkMode ? AppColors.primary : Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We value your feedback!',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us improve MediTrack',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Category section
              _buildSectionHeader(Icons.category_outlined, 'Category', isDarkMode),
              const SizedBox(height: 12),
              _buildCard(
                isDarkMode: isDarkMode,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            category.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray),
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = category);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
                      showCheckmark: false,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE)),
                        width: isSelected ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Feedback form section
              _buildSectionHeader(Icons.edit_note_outlined, 'Your Feedback', isDarkMode),
              const SizedBox(height: 12),
              _buildCard(
                isDarkMode: isDarkMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Subject', isDarkMode),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subjectController,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : AppColors.darkBlue,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'Brief description of your feedback',
                        icon: Icons.title_outlined,
                        isDarkMode: isDarkMode,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter a subject';
                        if (value.trim().length < 5) return 'Subject must be at least 5 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Message', isDarkMode),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 6,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : AppColors.darkBlue,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'Share the details of your feedback...',
                        isDarkMode: isDarkMode,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your feedback message';
                        if (value.trim().length < 10) return 'Message must be at least 10 characters';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Submit Feedback',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your feedback is confidential and only used to improve MediTrack.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.darkBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required bool isDarkMode, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5),
        ),
      ),
      child: child,
    );
  }

  Widget _buildFieldLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray,
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint, IconData? icon, required bool isDarkMode}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: AppColors.primary, size: 20),
            )
          : null,
      fillColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
