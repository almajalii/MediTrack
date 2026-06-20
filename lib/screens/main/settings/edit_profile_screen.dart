import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/services/account_manager.dart';
import 'package:meditrack/style/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AccountManager _accountManager = AccountManager();

  User? user;

  TextEditingController displayNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController allergiesController = TextEditingController();
  TextEditingController medicalConditionsController = TextEditingController();
  TextEditingController emergencyContactController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (user == null) return;
    setState(() => isLoading = true);
    final uid = user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      displayNameController.text = data['displayName'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phonenumber'] ?? '';
      allergiesController.text = data['allergies'] ?? '';
      medicalConditionsController.text = data['medicalConditions'] ?? '';
      emergencyContactController.text = data['emergencyContact'] ?? '';
    }
    setState(() => isLoading = false);
  }

  Future<void> saveUserData() async {
    if (user == null) return;
    setState(() => isSaving = true);
    try {
      final newDisplayName = displayNameController.text.trim();
      await _firestore.collection('users').doc(user!.uid).set({
        'displayName': newDisplayName,
        'email': emailController.text.trim(),
        'phonenumber': phoneController.text.trim(),
        'allergies': allergiesController.text.trim(),
        'medicalConditions': medicalConditionsController.text.trim(),
        'emergencyContact': emergencyContactController.text.trim(),
      }, SetOptions(merge: true));
      await user!.updateDisplayName(newDisplayName);
      await user!.reload();
      setState(() => user = _auth.currentUser);
      await _accountManager.saveCurrentAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile hero card
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
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: isDarkMode ? AppColors.primary : Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Basic Information section
                  _buildSectionHeader(context, Icons.person_outline, 'Basic Information', isDarkMode),
                  const SizedBox(height: 12),
                  _buildFieldCard(
                    isDarkMode: isDarkMode,
                    children: [
                      _buildField('Display Name', displayNameController, Icons.badge_outlined, isDarkMode),
                      _buildField('Email', emailController, Icons.email_outlined, isDarkMode),
                      _buildField('Phone Number', phoneController, Icons.phone_outlined, isDarkMode, isLast: true),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Medical Information section
                  _buildSectionHeader(context, Icons.medical_information_outlined, 'Medical Information', isDarkMode),
                  const SizedBox(height: 12),
                  _buildFieldCard(
                    isDarkMode: isDarkMode,
                    children: [
                      _buildField('Allergies', allergiesController, Icons.healing_outlined, isDarkMode, maxLines: 3),
                      _buildField('Medical Conditions', medicalConditionsController, Icons.local_hospital_outlined, isDarkMode, maxLines: 3, isLast: true),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Emergency Contact section
                  _buildSectionHeader(context, Icons.emergency_outlined, 'Emergency Contact', isDarkMode),
                  const SizedBox(height: 12),
                  _buildFieldCard(
                    isDarkMode: isDarkMode,
                    children: [
                      _buildField('Emergency Contact', emergencyContactController, Icons.contact_phone_outlined, isDarkMode, isLast: true),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title, bool isDarkMode) {
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

  Widget _buildFieldCard({required bool isDarkMode, required List<Widget> children}) {
    return Container(
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
        border: Border.all(color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDarkMode, {
    int maxLines = 1,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white : AppColors.darkBlue,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    displayNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    allergiesController.dispose();
    medicalConditionsController.dispose();
    emergencyContactController.dispose();
    super.dispose();
  }
}
