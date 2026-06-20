import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/app_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user notifications stream (FIXED: no composite index needed)
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
              .toList();
          
          // Sort in memory instead of using orderBy to avoid composite index
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Limit to 50 most recent
          return notifications.take(50).toList();
        });
  }

  // Get unread count (FIXED: simplified query)
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    final notification = AppNotification(
      id: '', // Firestore will generate
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      data: data,
    );

    await _firestore.collection('notifications').add(notification.toFirestore());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();

    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    final batch = _firestore.batch();

    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ==================== AUTOMATIC NOTIFICATIONS ====================

  // Send medicine expiry notifications (call this daily via a scheduled task)
  Future<void> checkAndNotifyExpiringMedicines(String userId) async {
    try {
      // Get all medicines for this user
      final medicines = await _firestore
          .collection('medicines')
          .where('userId', isEqualTo: userId)
          .get();

      final now = DateTime.now();

      for (var medicineDoc in medicines.docs) {
        final data = medicineDoc.data();
        final expiredDate = (data['dateExpired'] as Timestamp?)?.toDate();
        final medicineName = data['name'] ?? 'Unknown';

        if (expiredDate != null) {
          final daysUntilExpiry = expiredDate.difference(now).inDays;

          // Notify if medicine expires in 7 days or less
          if (daysUntilExpiry <= 7 && daysUntilExpiry >= 0) {
            await createNotification(
              userId: userId,
              title: 'âš ï¸ Medicine Expiring Soon',
              message: '$medicineName will expire in $daysUntilExpiry day${daysUntilExpiry == 1 ? '' : 's'}.',
              type: NotificationType.medicineExpiry,
              data: {'medicineId': medicineDoc.id, 'medicineName': medicineName},
            );
          }
          // Notify if medicine is already expired
          else if (daysUntilExpiry < 0) {
            await createNotification(
              userId: userId,
              title: 'ðŸš« Medicine Expired',
              message: '$medicineName has expired. Please dispose of it safely.',
              type: NotificationType.medicineExpiry,
              data: {'medicineId': medicineDoc.id, 'medicineName': medicineName},
            );
          }
        }
      }
    } catch (e) {
    }
  }

  // Send dosage reminder notification
  Future<void> sendDosageReminder({
    required String userId,
    required String medicineName,
    required String dosage,
    required String time,
  }) async {
    await createNotification(
      userId: userId,
      title: 'ðŸ’Š Time to Take Your Medicine',
      message: 'Don\'t forget to take $dosage of $medicineName at $time',
      type: NotificationType.dosageReminder,
      data: {
        'medicineName': medicineName,
        'dosage': dosage,
        'time': time,
      },
    );
  }

  // Send family member joined notification
  Future<void> notifyFamilyMemberJoined({
    required String userId,
    required String memberName,
    required String familyName,
  }) async {
    await createNotification(
      userId: userId,
      title: 'ðŸ‘¨â€ðŸ‘©â€ðŸ‘§â€ðŸ‘¦ New Family Member',
      message: '$memberName has joined $familyName family account.',
      type: NotificationType.familyUpdate,
    );
  }

  // Send family invitation notification
  Future<void> notifyFamilyInvitation({
    required String userId,
    required String inviterName,
    required String familyName,
  }) async {
    await createNotification(
      userId: userId,
      title: 'ðŸ“¨ Family Invitation',
      message: '$inviterName invited you to join $familyName family account.',
      type: NotificationType.familyUpdate,
    );
  }

  // Send low stock notification
  Future<void> notifyLowStock({
    required String userId,
    required String medicineName,
    required int quantity,
  }) async {
    await createNotification(
      userId: userId,
      title: 'ðŸ“¦ Low Medicine Stock',
      message: 'Only $quantity unit${quantity == 1 ? '' : 's'} of $medicineName remaining.',
      type: NotificationType.general,
      data: {'medicineName': medicineName, 'quantity': quantity},
    );
  }

  // Create sample notifications for testing
  Future<void> createSampleNotifications(String userId) async {
    // Medicine expiry notification
    await createNotification(
      userId: userId,
      title: 'âš ï¸ Medicine Expiring Soon',
      message: 'Your Aspirin will expire in 3 days. Please check your medicine cabinet.',
      type: NotificationType.medicineExpiry,
      data: {'medicineId': 'sample_medicine_id'},
    );

    // Dosage reminder
    await createNotification(
      userId: userId,
      title: 'ðŸ’Š Time to Take Your Medicine',
      message: 'Don\'t forget to take your evening dose of Paracetamol (500mg).',
      type: NotificationType.dosageReminder,
      data: {'dosageId': 'sample_dosage_id'},
    );

    // Family update
    await createNotification(
      userId: userId,
      title: 'ðŸ‘¨â€ðŸ‘©â€ðŸ‘§â€ðŸ‘¦ Family Account Update',
      message: 'Sarah has joined your family account.',
      type: NotificationType.familyUpdate,
    );

    // Low stock warning
    await createNotification(
      userId: userId,
      title: 'ðŸ“¦ Low Medicine Stock',
      message: 'Only 2 units of Ibuprofen remaining. Time to restock!',
      type: NotificationType.general,
    );

    // App update
    await createNotification(
      userId: userId,
      title: 'ðŸ”” New Feature Available',
      message: 'Check out the new Pharmacy Search feature to find nearby pharmacies!',
      type: NotificationType.appUpdate,
    );
  }
}
