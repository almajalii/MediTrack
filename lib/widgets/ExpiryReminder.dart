import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpiryReminder {
  static Future<void> showExpiredMedsSheet(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final today = DateTime.now();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .get();

      final dateFormat = DateFormat('dd-MM-yyyy');

      final expiredMeds = snapshot.docs.where((doc) {
        final data = doc.data();

        // Check if dateExpired field exists
        if (!data.containsKey('dateExpired')) {
          return false;
        }

        try {
          // Handle Timestamp from Firestore
          final expiryData = data['dateExpired'];
          DateTime expiryDate;

          if (expiryData is Timestamp) {
            expiryDate = expiryData.toDate();
          } else if (expiryData is String) {
            expiryDate = dateFormat.parseStrict(expiryData);
          } else {
            return false;
          }

          return expiryDate.isBefore(today);
        } catch (e) {
          return false;
        }
      }).toList();

      if (!context.mounted) return;

      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      showModalBottomSheet(
        context: context,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          if (expiredMeds.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Expired Medicines!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[200] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "All your medicines are still valid",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expired Medicines',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
                          ),
                          Text(
                            '${expiredMeds.length} item(s) expired',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: expiredMeds.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final med = expiredMeds[index];
                    final data = med.data();

                    // Format expiry date
                    String expiryStr = 'Unknown';
                    try {
                      final expiryData = data['dateExpired'];
                      if (expiryData is Timestamp) {
                        expiryStr = dateFormat.format(expiryData.toDate());
                      } else if (expiryData is String) {
                        expiryStr = expiryData;
                      }
                    } catch (e) {
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: isDarkMode
                          ? const Color(0xFF2C2C2C)
                          : Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.medication,
                            color: Colors.red[700],
                            size: 24,
                          ),
                        ),
                        title: Text(
                          data['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.grey[200]
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Expired on: $expiryStr',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Quantity: ${data['quantity'] ?? 0}',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.warning,
                          color: Colors.red[400],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom padding
              const SizedBox(height: 16),
            ],
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medicines: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
