import 'package:flutter/material.dart';
import 'package:meditrack/services/account_manager.dart';
import 'package:meditrack/screens/auth/login_screen.dart';
import 'package:meditrack/screens/main/home/navigation_main.dart';
import 'package:meditrack/style/colors.dart';

class AccountSwitcherScreen extends StatefulWidget {
  const AccountSwitcherScreen({super.key});

  @override
  State<AccountSwitcherScreen> createState() => _AccountSwitcherScreenState();
}

class _AccountSwitcherScreenState extends State<AccountSwitcherScreen> {
  final AccountManager _accountManager = AccountManager();
  List<SavedAccount> _accounts = [];
  bool _isLoading = true;
  String? _currentAccountEmail;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);

    final accounts = await _accountManager.getSavedAccounts();
    final currentEmail = await _accountManager.getCurrentAccountEmail();

    setState(() {
      _accounts = accounts;
      _currentAccountEmail = currentEmail;
      _isLoading = false;
    });
  }

  Future<void> _switchToAccount(SavedAccount account) async {
    // Check if credentials are saved
    final credentials = await _accountManager.getAccountCredentials(account.email);

    if (credentials != null && credentials['password']!.isNotEmpty) {
      // Quick switch with saved password
      _showQuickSwitchDialog(account, credentials['password']!);
    } else {
      // Need to enter password
      _showPasswordDialog(account);
    }
  }

  void _showQuickSwitchDialog(SavedAccount account, String password) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
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
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : const Color(0xFFDDE3EE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  account.displayName[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Switch to ${account.displayName}?',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              account.email,
              style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE)),
                    ),
                    child: Text('Cancel',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey.shade300 : AppColors.darkBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _performSwitch(account.email, password);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Switch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(SavedAccount account) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool rememberPassword = false;
        bool obscure = true;

        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade700 : const Color(0xFFDDE3EE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            account.displayName[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Sign in as ${account.displayName}',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.darkBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        account.email,
                        style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscure,
                      style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : AppColors.darkBlue),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray, size: 20),
                          onPressed: () => setSheetState(() => obscure = !obscure),
                        ),
                        fillColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error, width: 2)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setSheetState(() => rememberPassword = !rememberPassword),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22, height: 22,
                              child: Checkbox(
                                value: rememberPassword,
                                onChanged: (v) => setSheetState(() => rememberPassword = v ?? false),
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                side: BorderSide(color: isDarkMode ? Colors.grey.shade600 : const Color(0xFFDDE3EE)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Remember for quick switching',
                              style: TextStyle(fontSize: 13,
                                color: isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE)),
                            ),
                            child: Text('Cancel',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.grey.shade300 : AppColors.darkBlue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(sheetContext);
                                if (rememberPassword) {
                                  await _accountManager.saveAccountPassword(account.email, passwordController.text);
                                }
                                await _performSwitch(account.email, passwordController.text);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
      },
    );
  }

  Future<void> _performSwitch(String email, String password) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
              const SizedBox(height: 16),
              Text(
                'Switching account…',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.grey.shade300 : AppColors.darkBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final success = await _accountManager.switchAccount(email, password);

    // Hide loading
    Navigator.pop(context);

    if (success) {
      // Navigate to main screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NavigationMain()),
            (route) => false,
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to switch account. Please check your password.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewAccount() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _removeAccount(SavedAccount account) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showModalBottomSheet<bool>(
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
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : const Color(0xFFDDE3EE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_remove_outlined, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Remove Account',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remove ${account.displayName} from saved accounts? You can add it back by signing in again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, height: 1.5,
                color: isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray,
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
                      side: BorderSide(color: isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE)),
                    ),
                    child: Text('Cancel',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey.shade300 : AppColors.darkBlue),
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
                    child: const Text('Remove', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _accountManager.removeAccount(account.email);
      _loadAccounts(); // Reload list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${account.displayName} removed'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Switch Account'),
        centerTitle: true,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? _buildEmptyState(isDarkMode)
          : _buildAccountList(isDarkMode),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewAccount,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Account', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No saved accounts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add an account',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        final isCurrentAccount = account.email == _currentAccountEmail;

        return GestureDetector(
          onTap: isCurrentAccount ? null : () => _switchToAccount(account),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                color: isCurrentAccount
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : (isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5)),
                width: isCurrentAccount ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        account.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                account.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isDarkMode ? Colors.white : AppColors.darkBlue,
                                ),
                              ),
                            ),
                            if (isCurrentAccount)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Current',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          account.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade500 : AppColors.indigoGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last used: ${_formatDate(account.lastUsed)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCurrentAccount)
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade400,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'switch',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz),
                              SizedBox(width: 8),
                              Text('Switch to this account'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'switch') {
                          _switchToAccount(account);
                        } else if (value == 'remove') {
                          _removeAccount(account);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}