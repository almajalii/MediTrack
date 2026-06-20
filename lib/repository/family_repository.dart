// Middle layer between Firestore database and BLoC for Family Account Management
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/family_account.dart';
import 'package:meditrack/model/family_member.dart';
import 'package:meditrack/model/family_invitation.dart';
import 'dart:math';

class FamilyRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ==================== FAMILY ACCOUNT OPERATIONS ====================

  // 1. Create a new family account
  Future<FamilyAccount> createFamilyAccount({
    required String userId,
    required String familyName,
    required String displayName,
    required String primaryContactEmail,
    String? primaryContactPhone,
  }) async {
    // Create the family account document
    final familyRef = await firestore.collection('familyAccounts').add({
      'familyName': familyName,
      'ownerId': userId,
      'primaryContactEmail': primaryContactEmail,
      'primaryContactPhone': primaryContactPhone,
      'createdAt': Timestamp.now(),
      'memberIds': [userId], // Owner is automatically a member
    });

    // Add the owner as the first family member
    await firestore
        .collection('familyAccounts')
        .doc(familyRef.id)
        .collection('members')
        .add({
      'familyAccountId': familyRef.id,
      'userId': userId,
      'displayName': displayName,
      'email': primaryContactEmail,
      'phoneNumber': primaryContactPhone,
      'role': MemberRole.owner.name,
      'invitationStatus': InvitationStatus.accepted.name,
      'invitedAt': Timestamp.now(),
      'acceptedAt': Timestamp.now(),
    });

    // Update the user's document to link to this family account
    await firestore.collection('users').doc(userId).update({
      'familyAccountId': familyRef.id,
    });

    // Fetch and return the created family account
    final doc = await familyRef.get();
    return FamilyAccount.fromFirestore(doc);
  }

  // 2. Get family account by ID
  Future<FamilyAccount?> getFamilyAccount(String familyAccountId) async {
    final doc = await firestore.collection('familyAccounts').doc(familyAccountId).get();

    if (!doc.exists) return null;
    return FamilyAccount.fromFirestore(doc);
  }

  // 3. Get family account for a specific user
  Future<FamilyAccount?> getFamilyAccountForUser(String userId) async {
    final userDoc = await firestore.collection('users').doc(userId).get();
    final familyAccountId = userDoc.data()?['familyAccountId'];

    if (familyAccountId == null) return null;
    return getFamilyAccount(familyAccountId);
  }

  // 4. Stream family account for real-time updates
  Stream<FamilyAccount?> streamFamilyAccount(String familyAccountId) {
    return firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .snapshots()
        .map((doc) => doc.exists ? FamilyAccount.fromFirestore(doc) : null);
  }

  // 5. Update family account details
  Future<void> updateFamilyAccount(
      String familyAccountId,
      FamilyAccount familyAccount,
      ) async {
    await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .update(familyAccount.toFirestore());
  }

  // 6. Delete family account
  Future<void> deleteFamilyAccount(String familyAccountId) async {
    // Delete all members
    final membersSnapshot = await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('members')
        .get();

    for (var doc in membersSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all invitations
    final invitationsSnapshot = await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('invitations')
        .get();

    for (var doc in invitationsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Remove family account reference from all member users
    final familyDoc = await firestore.collection('familyAccounts').doc(familyAccountId).get();
    final memberIds = List<String>.from(familyDoc.data()?['memberIds'] ?? []);

    for (String userId in memberIds) {
      await firestore.collection('users').doc(userId).update({
        'familyAccountId': FieldValue.delete(),
      });
    }

    // Delete the family account
    await firestore.collection('familyAccounts').doc(familyAccountId).delete();
  }

  // ==================== FAMILY MEMBER OPERATIONS ====================

  // 7. Get all family members
  Stream<List<FamilyMember>> getFamilyMembers(String familyAccountId) {
    return firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('members')
        .where('invitationStatus', isEqualTo: InvitationStatus.accepted.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FamilyMember.fromFirestore(doc))
        .toList());
  }

  // 8. Get family member by user ID
  Future<FamilyMember?> getFamilyMember(String familyAccountId, String userId) async {
    final snapshot = await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('members')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return FamilyMember.fromFirestore(snapshot.docs.first);
  }

  // 9. Remove a family member
  Future<void> removeFamilyMember(String familyAccountId, String memberId) async {
    // Get member details before deletion
    final memberDoc = await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('members')
        .doc(memberId)
        .get();

    final userId = memberDoc.data()?['userId'];

    // Delete the member document
    await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('members')
        .doc(memberId)
        .delete();

    // Update the family account's member list
    await firestore.collection('familyAccounts').doc(familyAccountId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    // Remove family account reference from user
    if (userId != null) {
      await firestore.collection('users').doc(userId).update({
        'familyAccountId': FieldValue.delete(),
      });
    }
  }

  // ==================== INVITATION OPERATIONS ====================

  // 10. Send invitation to join family account
  Future<FamilyInvitation> sendInvitation({
    required String familyAccountId,
    required String invitedBy,
    required String invitedEmail,
    String? invitedPhone,
    required InvitationType invitationType,
  }) async {
    // Generate unique invitation token
    final token = _generateInvitationToken();

    // Create invitation document
    final invitationRef = await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('invitations')
        .add({
      'familyAccountId': familyAccountId,
      'invitedBy': invitedBy,
      'invitedEmail': invitedEmail,
      'invitedPhone': invitedPhone,
      'invitationType': invitationType.name,
      'invitationToken': token,
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
      'isAccepted': false,
      'isExpired': false,
      'acceptedByUserId': null,
    });

    final doc = await invitationRef.get();
    return FamilyInvitation.fromFirestore(doc);
  }

  // 11. Get invitation by token
  Future<FamilyInvitation?> getInvitationByToken(String token) async {
    final snapshot = await firestore
        .collectionGroup('invitations')
        .where('invitationToken', isEqualTo: token)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return FamilyInvitation.fromFirestore(snapshot.docs.first);
  }

  // 12. Accept invitation
  Future<void> acceptInvitation({
    required String invitationId,
    required String familyAccountId,
    required String userId,
    required String displayName,
    required String email,
    String? phoneNumber,
  }) async {
    // Update invitation status
    await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('invitations')
        .doc(invitationId)
        .update({
      'isAccepted': true,
      'acceptedByUserId': userId,
    });

    // Add user as family member
    await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('members')
        .add({
      'familyAccountId': familyAccountId,
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': MemberRole.member.name,
      'invitationStatus': InvitationStatus.accepted.name,
      'invitedAt': Timestamp.now(),
      'acceptedAt': Timestamp.now(),
    });

    // Update family account member list
    await firestore.collection('familyAccounts').doc(familyAccountId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    // Link user to family account
    await firestore.collection('users').doc(userId).update({
      'familyAccountId': familyAccountId,
    });
  }

  // 13. Get pending invitations for a family account
  Stream<List<FamilyInvitation>> getPendingInvitations(String familyAccountId) {
    return firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('invitations')
        .where('isAccepted', isEqualTo: false)
        .where('isExpired', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FamilyInvitation.fromFirestore(doc))
        .where((inv) => inv.isValid)
        .toList());
  }

  // 14. Cancel/Delete invitation
  Future<void> deleteInvitation(String familyAccountId, String invitationId) async {
    await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('invitations')
        .doc(invitationId)
        .delete();
  }

  // 15. Mark expired invitations
  Future<void> markExpiredInvitations(String familyAccountId) async {
    final snapshot = await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('invitations')
        .where('isAccepted', isEqualTo: false)
        .where('isExpired', isEqualTo: false)
        .get();

    final batch = firestore.batch();
    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final invitation = FamilyInvitation.fromFirestore(doc);
      if (now.isAfter(invitation.expiresAt)) {
        batch.update(doc.reference, {'isExpired': true});
      }
    }

    await batch.commit();
  }

  // ==================== HELPER METHODS ====================

  // Generate a random invitation token
  String _generateInvitationToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Check if user is family account owner
  Future<bool> isOwner(String familyAccountId, String userId) async {
    final familyAccount = await getFamilyAccount(familyAccountId);
    return familyAccount?.ownerId == userId;
  }

  // Get member count
  Future<int> getMemberCount(String familyAccountId) async {
    final snapshot = await firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .collection('members')
        .where('invitationStatus', isEqualTo: InvitationStatus.accepted.name)
        .get();

    return snapshot.docs.length;
  }
}