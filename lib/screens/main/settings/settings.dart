import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/screens/auth/start_screen.dart';
import 'package:meditrack/screens/main/settings/edit_profile_screen.dart';
import 'package:meditrack/screens/main/settings/user_feedback_screen.dart';
import 'package:meditrack/screens/main/settings/contact_us_screen.dart';
import 'package:meditrack/services/account_manager.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/bloc/theme_bloc/theme_bloc.dart';
import 'package:meditrack/screens/main/settings/chat_support_screen.dart';
import 'account_switcher.dart';
import 'data_export.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AccountManager _accountManager = AccountManager();

  User? user;
  int savedAccountsCount = 0;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadSavedAccountsCount();
  }

  Future<void> _loadSavedAccountsCount() async {
    final accounts = await _accountManager.getSavedAccounts();
    if (mounted) {
      setState(() {
        savedAccountsCount = accounts.length;
      });
    }
  }

  void logout() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : const Color(0xFFDDE3EE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out\nof your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey.shade300 : AppColors.darkBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const StartScreen()),
          (route) => false,
        );
      }
    }
  }

  void openEditProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
  }

  void openDataExport() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DataExportScreen()));
  }

  void openAccountSwitcher() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSwitcherScreen())).then((_) {
      if (mounted) {
        _loadSavedAccountsCount();
      }
    });
  }

  void openFeedback() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserFeedbackScreen()));
  }

  void openContactUs() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: SizedBox(height: 70, width: 70, child: Image.asset('images/1.png')),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient:
                isDarkMode
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile hero card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient:
                    isDarkMode
                        ? const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2A)])
                        : const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF007FA8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: isDarkMode ? AppColors.primary : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account section
            _buildSectionHeader(context, Icons.manage_accounts_outlined, 'Account', isDarkMode),
            const SizedBox(height: 12),
            _buildSettingsGroup(
              isDarkMode: isDarkMode,
              children: [
                _buildTileItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: openEditProfile,
                ),
                _buildDivider(isDarkMode),
                _buildTileItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.people_outline,
                  label: 'Switch Account',
                  subtitle: savedAccountsCount > 1 ? '$savedAccountsCount accounts saved' : 'Manage your accounts',
                  onTap: openAccountSwitcher,
                  trailing: savedAccountsCount > 1
                      ? _buildBadge('$savedAccountsCount')
                      : const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFBDBDBD)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Appearance section
            _buildSectionHeader(context, Icons.palette_outlined, 'Appearance', isDarkMode),
            const SizedBox(height: 12),
            _buildSettingsGroup(
              isDarkMode: isDarkMode,
              children: [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, themeState) {
                    return _buildSwitchItem(
                      isDarkMode: isDarkMode,
                      icon: themeState.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      label: 'Dark Mode',
                      subtitle: themeState.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                      value: themeState.isDarkMode,
                      onChanged: (_) => context.read<ThemeBloc>().add(ToggleThemeEvent()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data section
            _buildSectionHeader(context, Icons.storage_outlined, 'Data & Privacy', isDarkMode),
            const SizedBox(height: 12),
            _buildSettingsGroup(
              isDarkMode: isDarkMode,
              children: [
                _buildTileItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.download_outlined,
                  label: 'Export Data',
                  subtitle: 'Download your data as PDF',
                  onTap: openDataExport,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Support section
            _buildSectionHeader(context, Icons.help_outline, 'Support', isDarkMode),
            const SizedBox(height: 12),
            _buildSettingsGroup(
              isDarkMode: isDarkMode,
              children: [
                _buildTileItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat Support',
                  subtitle: 'Get help from our support team',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatSupportScreen()));
                  },
                ),
                _buildDivider(isDarkMode),
                _buildTileItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.feedback_outlined,
                  label: 'Send Feedback',
                  subtitle: 'Help us improve MediTrack',
                  onTap: openFeedback,
                ),
                _buildDivider(isDarkMode),
                _buildTileItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.contact_support_outlined,
                  label: 'Contact Us',
                  subtitle: 'Reach out via email or social media',
                  onTap: openContactUs,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSettingsGroup(
              isDarkMode: isDarkMode,
              children: [
                _buildTileItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.logout,
                  label: 'Log Out',
                  subtitle: 'Sign out of your account',
                  onTap: logout,
                  iconColor: AppColors.error,
                  labelColor: AppColors.error,
                  trailing: const SizedBox.shrink(),
                ),
              ],
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

  Widget _buildSettingsGroup({required bool isDarkMode, required List<Widget> children}) {
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
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTileItem({
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? labelColor,
  }) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: labelColor ?? (isDarkMode ? Colors.white : AppColors.darkBlue),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      indent: 54,
      endIndent: 0,
      color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5),
    );
  }

  Widget _buildBadge(String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

}
