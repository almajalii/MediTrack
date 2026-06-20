import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Represents a saved account
class SavedAccount {
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime lastUsed;

  SavedAccount({
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'lastUsed': lastUsed.toIso8601String(),
  };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
    email: json['email'],
    displayName: json['displayName'],
    photoUrl: json['photoUrl'],
    lastUsed: DateTime.parse(json['lastUsed']),
  );
}

/// Manages multiple user accounts and allows switching between them
/// Stores account credentials securely for quick switching
class AccountManager {
  static final AccountManager _instance = AccountManager._internal();
  factory AccountManager() => _instance;
  AccountManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _accountsKey = 'saved_accounts';
  static const String _currentAccountKey = 'current_account_email';

  /// Get all saved accounts
  Future<List<SavedAccount>> getSavedAccounts() async {
    final accountsJson = await _storage.read(key: _accountsKey);
    if (accountsJson == null) return [];

    final List<dynamic> accountsList = jsonDecode(accountsJson);
    return accountsList
        .map((json) => SavedAccount.fromJson(json))
        .toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed)); // Most recent first
  }

  /// Save current account to the list
  Future<void> saveCurrentAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final accounts = await getSavedAccounts();

    // Remove existing entry if present
    accounts.removeWhere((account) => account.email == user.email);

    // Add current account
    accounts.add(SavedAccount(
      email: user.email ?? '',
      displayName: user.displayName ?? 'User',
      photoUrl: user.photoURL,
      lastUsed: DateTime.now(),
    ));

    // Save back to storage
    final accountsJson = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _accountsKey, value: accountsJson);
    await _storage.write(key: _currentAccountKey, value: user.email);

    // Save credentials for this account (for quick switching)
    await _saveAccountCredentials(user.email ?? '');
  }

  /// Save account credentials securely
  Future<void> _saveAccountCredentials(String email) async {
    // Note: In production, you might want to use refresh tokens instead
    // For simplicity, we're storing email and relying on Firebase session
    await _storage.write(key: 'account_${email}_email', value: email);
  }

  /// Get credentials for an account
  Future<Map<String, String>?> getAccountCredentials(String email) async {
    final storedEmail = await _storage.read(key: 'account_${email}_email');
    final storedPassword = await _storage.read(key: 'account_${email}_password');

    if (storedEmail == null) return null;

    return {
      'email': storedEmail,
      'password': storedPassword ?? '',
    };
  }

  /// Store password for quick switching (optional - for demo purposes)
  Future<void> saveAccountPassword(String email, String password) async {
    await _storage.write(key: 'account_${email}_password', value: password);
  }

  /// Switch to a different account
  Future<bool> switchAccount(String email, String password) async {
    try {
      // Sign out current user
      await _auth.signOut();

      // Sign in with new account
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last used time
      await saveCurrentAccount();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove an account from saved accounts
  Future<void> removeAccount(String email) async {
    final accounts = await getSavedAccounts();
    accounts.removeWhere((account) => account.email == email);

    final accountsJson = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _accountsKey, value: accountsJson);

    // Remove stored credentials
    await _storage.delete(key: 'account_${email}_email');
    await _storage.delete(key: 'account_${email}_password');
  }

  /// Get current account email
  Future<String?> getCurrentAccountEmail() async {
    return await _storage.read(key: _currentAccountKey);
  }

  /// Check if an account is the current one
  Future<bool> isCurrentAccount(String email) async {
    final currentEmail = await getCurrentAccountEmail();
    return currentEmail == email;
  }
}
