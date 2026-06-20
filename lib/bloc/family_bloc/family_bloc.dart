import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meditrack/model/family_account.dart';
import 'package:meditrack/model/family_member.dart';
import 'package:meditrack/model/family_invitation.dart';
import 'package:meditrack/repository/family_repository.dart';

part 'family_event.dart';
part 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository familyRepository;

  FamilyBloc(this.familyRepository) : super(FamilyInitialState()) {
    // Family Account Events
    on<CreateFamilyAccountEvent>(_onCreateFamilyAccount);
    on<LoadFamilyAccountEvent>(_onLoadFamilyAccount);
    on<UpdateFamilyAccountEvent>(_onUpdateFamilyAccount);
    on<DeleteFamilyAccountEvent>(_onDeleteFamilyAccount);

    // Family Member Events
    on<LoadFamilyMembersEvent>(_onLoadFamilyMembers);
    on<RemoveFamilyMemberEvent>(_onRemoveFamilyMember);

    // Invitation Events
    on<SendInvitationEvent>(_onSendInvitation);
    on<AcceptInvitationEvent>(_onAcceptInvitation);
    on<LoadPendingInvitationsEvent>(_onLoadPendingInvitations);
    on<DeleteInvitationEvent>(_onDeleteInvitation);
    on<ValidateInvitationEvent>(_onValidateInvitation);
  }

  // ==================== FAMILY ACCOUNT HANDLERS ====================

  Future<void> _onCreateFamilyAccount(
      CreateFamilyAccountEvent event,
      Emitter<FamilyState> emit,
      ) async {
    emit(FamilyLoadingState());
    try {
      final familyAccount = await familyRepository.createFamilyAccount(
        userId: event.userId,
        familyName: event.familyName,
        displayName: event.displayName,
        primaryContactEmail: event.primaryContactEmail,
        primaryContactPhone: event.primaryContactPhone,
      );

      emit(FamilyAccountCreatedState(familyAccount));

      // Automatically load the created family account
      add(LoadFamilyAccountEvent(event.userId));
    } catch (e) {
      emit(FamilyErrorState('Failed to create family account: ${e.toString()}'));
    }
  }

  Future<void> _onLoadFamilyAccount(
      LoadFamilyAccountEvent event,
      Emitter<FamilyState> emit,
      ) async {
    emit(FamilyLoadingState());
    try {
      final familyAccount = await familyRepository.getFamilyAccountForUser(event.userId);

      if (familyAccount == null) {
        emit(NoFamilyAccountState());
        return;
      }

      // Load members and pending invitations concurrently
      await emit.forEach(
        familyRepository.getFamilyMembers(familyAccount.id),
        onData: (members) {
          return FamilyAccountLoadedState(
            familyAccount: familyAccount,
            members: members,
          );
        },
        onError: (error, stackTrace) {
          return FamilyErrorState('Failed to load family members: ${error.toString()}');
        },
      );
    } catch (e) {
      emit(FamilyErrorState('Failed to load family account: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateFamilyAccount(
      UpdateFamilyAccountEvent event,
      Emitter<FamilyState> emit,
      ) async {
    try {
      await familyRepository.updateFamilyAccount(
        event.familyAccountId,
        event.familyAccount,
      );

      emit(FamilyAccountUpdatedState('Family account updated successfully'));

      // Reload the family account to reflect changes
      final updatedAccount = await familyRepository.getFamilyAccount(event.familyAccountId);
      if (updatedAccount != null) {
        final currentState = state;
        if (currentState is FamilyAccountLoadedState) {
          emit(currentState.copyWith(familyAccount: updatedAccount));
        }
      }
    } catch (e) {
      emit(FamilyErrorState('Failed to update family account: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteFamilyAccount(
      DeleteFamilyAccountEvent event,
      Emitter<FamilyState> emit,
      ) async {
    emit(FamilyLoadingState());
    try {
      // Verify user is the owner
      final isOwner = await familyRepository.isOwner(event.familyAccountId, event.userId);

      if (!isOwner) {
        emit(FamilyErrorState('Only the family account owner can delete the account'));
        return;
      }

      await familyRepository.deleteFamilyAccount(event.familyAccountId);
      emit(FamilyAccountDeletedState());
    } catch (e) {
      emit(FamilyErrorState('Failed to delete family account: ${e.toString()}'));
    }
  }

  // ==================== FAMILY MEMBER HANDLERS ====================

  Future<void> _onLoadFamilyMembers(
      LoadFamilyMembersEvent event,
      Emitter<FamilyState> emit,
      ) async {
    try {
      await emit.forEach(
        familyRepository.getFamilyMembers(event.familyAccountId),
        onData: (members) {
          final currentState = state;
          if (currentState is FamilyAccountLoadedState) {
            return currentState.copyWith(members: members);
          }
          return FamilyMembersLoadedState(members);
        },
        onError: (error, stackTrace) {
          return FamilyErrorState('Failed to load family members: ${error.toString()}');
        },
      );
    } catch (e) {
      emit(FamilyErrorState('Failed to load family members: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveFamilyMember(
      RemoveFamilyMemberEvent event,
      Emitter<FamilyState> emit,
      ) async {
    try {
      await familyRepository.removeFamilyMember(
        event.familyAccountId,
        event.memberId,
      );

      // Show success message but don't reload - stream will update automatically
      final currentState = state;
      if (currentState is FamilyAccountLoadedState) {
        emit(currentState); // Keep current state, stream will update
      }
    } catch (e) {
      emit(FamilyErrorState('Failed to remove family member: ${e.toString()}'));
    }
  }

  // ==================== INVITATION HANDLERS ====================

  Future<void> _onSendInvitation(
      SendInvitationEvent event,
      Emitter<FamilyState> emit,
      ) async {
    try {
      final invitation = await familyRepository.sendInvitation(
        familyAccountId: event.familyAccountId,
        invitedBy: event.invitedBy,
        invitedEmail: event.invitedEmail,
        invitedPhone: event.invitedPhone,
        invitationType: event.invitationType,
      );

      // Show success message using a temporary state then return to current state
      final currentState = state;
      emit(InvitationSentState(
        invitation: invitation,
        message: 'Invitation sent successfully to ${event.invitedEmail}',
      ));

      // Return to the current loaded state so the stream keeps working
      if (currentState is FamilyAccountLoadedState) {
        await Future.delayed(Duration(milliseconds: 100));
        emit(currentState);
      }
    } catch (e) {
      emit(FamilyErrorState('Failed to send invitation: ${e.toString()}'));
    }
  }

  Future<void> _onAcceptInvitation(
      AcceptInvitationEvent event,
      Emitter<FamilyState> emit,
      ) async {
    emit(FamilyLoadingState());
    try {
      // Get invitation details
      final invitation = await familyRepository.getInvitationByToken(event.invitationToken);

      if (invitation == null) {
        emit(FamilyErrorState('Invalid invitation token'));
        return;
      }

      if (!invitation.isValid) {
        emit(FamilyErrorState('This invitation has expired or already been used'));
        return;
      }

      // Accept the invitation
      await familyRepository.acceptInvitation(
        invitationId: invitation.id,
        familyAccountId: invitation.familyAccountId,
        userId: event.userId,
        displayName: event.displayName,
        email: event.email,
        phoneNumber: event.phoneNumber,
      );

      emit(InvitationAcceptedState(
        familyAccountId: invitation.familyAccountId,
        message: 'Successfully joined the family account',
      ));

      // Load the family account for the new member
      add(LoadFamilyAccountEvent(event.userId));
    } catch (e) {
      emit(FamilyErrorState('Failed to accept invitation: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPendingInvitations(
      LoadPendingInvitationsEvent event,
      Emitter<FamilyState> emit,
      ) async {
    try {
      await emit.forEach(
        familyRepository.getPendingInvitations(event.familyAccountId),
        onData: (invitations) {
          final currentState = state;
          if (currentState is FamilyAccountLoadedState) {
            return currentState.copyWith(pendingInvitations: invitations);
          }
          return PendingInvitationsLoadedState(invitations);
        },
        onError: (error, stackTrace) {
          return FamilyErrorState('Failed to load pending invitations: ${error.toString()}');
        },
      );
    } catch (e) {
      emit(FamilyErrorState('Failed to load pending invitations: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteInvitation(
      DeleteInvitationEvent event,
      Emitter<FamilyState> emit,
      ) async {
    try {
      await familyRepository.deleteInvitation(
        event.familyAccountId,
        event.invitationId,
      );

      // Don't emit a separate deleted state, just let the stream update
      // The stream listener will automatically update the pending invitations
    } catch (e) {
      emit(FamilyErrorState('Failed to delete invitation: ${e.toString()}'));
    }
  }

  Future<void> _onValidateInvitation(
      ValidateInvitationEvent event,
      Emitter<FamilyState> emit,
      ) async {
    emit(FamilyLoadingState());
    try {
      final invitation = await familyRepository.getInvitationByToken(event.invitationToken);

      if (invitation == null) {
        emit(InvitationValidatedState(
          isValid: false,
          errorMessage: 'Invalid invitation link',
        ));
        return;
      }

      if (!invitation.isValid) {
        String errorMessage = 'This invitation is no longer valid';
        if (invitation.isAccepted) {
          errorMessage = 'This invitation has already been used';
        } else if (invitation.isExpired || DateTime.now().isAfter(invitation.expiresAt)) {
          errorMessage = 'This invitation has expired';
        }

        emit(InvitationValidatedState(
          invitation: invitation,
          isValid: false,
          errorMessage: errorMessage,
        ));
        return;
      }

      emit(InvitationValidatedState(
        invitation: invitation,
        isValid: true,
      ));
    } catch (e) {
      emit(FamilyErrorState('Failed to validate invitation. Please check the code and try again.'));
    }
  }
}
