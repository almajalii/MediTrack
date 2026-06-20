part of 'family_bloc.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

// ==================== FAMILY ACCOUNT EVENTS ====================

// Create a new family account
class CreateFamilyAccountEvent extends FamilyEvent {
  final String userId;
  final String familyName;
  final String displayName;
  final String primaryContactEmail;
  final String? primaryContactPhone;

  const CreateFamilyAccountEvent({
    required this.userId,
    required this.familyName,
    required this.displayName,
    required this.primaryContactEmail,
    this.primaryContactPhone,
  });

  @override
  List<Object?> get props => [userId, familyName, displayName, primaryContactEmail, primaryContactPhone];
}

// Load family account for a user
class LoadFamilyAccountEvent extends FamilyEvent {
  final String userId;

  const LoadFamilyAccountEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Update family account details
class UpdateFamilyAccountEvent extends FamilyEvent {
  final String familyAccountId;
  final FamilyAccount familyAccount;

  const UpdateFamilyAccountEvent({
    required this.familyAccountId,
    required this.familyAccount,
  });

  @override
  List<Object?> get props => [familyAccountId, familyAccount];
}

// Delete family account
class DeleteFamilyAccountEvent extends FamilyEvent {
  final String familyAccountId;
  final String userId;

  const DeleteFamilyAccountEvent({
    required this.familyAccountId,
    required this.userId,
  });

  @override
  List<Object?> get props => [familyAccountId, userId];
}

// ==================== FAMILY MEMBER EVENTS ====================

// Load all family members
class LoadFamilyMembersEvent extends FamilyEvent {
  final String familyAccountId;

  const LoadFamilyMembersEvent(this.familyAccountId);

  @override
  List<Object?> get props => [familyAccountId];
}

// Remove a family member
class RemoveFamilyMemberEvent extends FamilyEvent {
  final String familyAccountId;
  final String memberId;

  const RemoveFamilyMemberEvent({
    required this.familyAccountId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [familyAccountId, memberId];
}

// ==================== INVITATION EVENTS ====================

// Send invitation to join family
class SendInvitationEvent extends FamilyEvent {
  final String familyAccountId;
  final String invitedBy;
  final String invitedEmail;
  final String? invitedPhone;
  final InvitationType invitationType;

  const SendInvitationEvent({
    required this.familyAccountId,
    required this.invitedBy,
    required this.invitedEmail,
    this.invitedPhone,
    required this.invitationType,
  });

  @override
  List<Object?> get props => [
    familyAccountId,
    invitedBy,
    invitedEmail,
    invitedPhone,
    invitationType,
  ];
}

// Accept invitation
class AcceptInvitationEvent extends FamilyEvent {
  final String invitationToken;
  final String userId;
  final String displayName;
  final String email;
  final String? phoneNumber;

  const AcceptInvitationEvent({
    required this.invitationToken,
    required this.userId,
    required this.displayName,
    required this.email,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [invitationToken, userId, displayName, email, phoneNumber];
}

// Load pending invitations
class LoadPendingInvitationsEvent extends FamilyEvent {
  final String familyAccountId;

  const LoadPendingInvitationsEvent(this.familyAccountId);

  @override
  List<Object?> get props => [familyAccountId];
}

// Delete/Cancel invitation
class DeleteInvitationEvent extends FamilyEvent {
  final String familyAccountId;
  final String invitationId;

  const DeleteInvitationEvent({
    required this.familyAccountId,
    required this.invitationId,
  });

  @override
  List<Object?> get props => [familyAccountId, invitationId];
}

// Validate invitation token
class ValidateInvitationEvent extends FamilyEvent {
  final String invitationToken;

  const ValidateInvitationEvent(this.invitationToken);

  @override
  List<Object?> get props => [invitationToken];
}