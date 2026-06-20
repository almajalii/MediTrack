import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meditrack/style/colors.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const _emailAddress = 'support@meditrack.com';
  static const _facebookUrl = 'https://facebook.com';
  static const _instagramUrl = 'https://instagram.com';

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _emailAddress,
      query: 'subject=MediTrack Support Request',
    );
    await _launch(context, uri);
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    await _launch(context, Uri.parse(url), external: true);
  }

  Future<void> _launch(BuildContext context, Uri uri, {bool external = false}) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Contact Us', style: TextStyle(color: Colors.white)),
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
                      Icons.support_agent_outlined,
                      color: isDarkMode ? AppColors.primary : Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'We\'re here to help',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how to reach us',
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

            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.connect_without_contact_outlined, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Get in Touch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.darkBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contact options card
            Container(
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
              child: Column(
                children: [
                  _buildContactTile(
                    context: context,
                    isDarkMode: isDarkMode,
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFF4A90D9),
                    title: 'Email Support',
                    subtitle: _emailAddress,
                    onTap: () => _launchEmail(context),
                  ),
                  _buildDivider(isDarkMode),
                  _buildContactTile(
                    context: context,
                    isDarkMode: isDarkMode,
                    icon: Icons.facebook_rounded,
                    iconColor: const Color(0xFF1877F2),
                    title: 'Facebook',
                    subtitle: 'Follow us on Facebook',
                    onTap: () => _launchUrl(context, _facebookUrl),
                  ),
                  _buildDivider(isDarkMode),
                  _buildContactTile(
                    context: context,
                    isDarkMode: isDarkMode,
                    icon: Icons.camera_alt_outlined,
                    iconColor: const Color(0xFFE4405F),
                    title: 'Instagram',
                    subtitle: 'Follow us on Instagram',
                    onTap: () => _launchUrl(context, _instagramUrl),
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Response time note
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
                  Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We typically respond to emails within 24–48 hours on business days.',
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
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(16),
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDarkMode ? Colors.grey.shade600 : const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      indent: 54,
      color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5),
    );
  }
}
