import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/repository/dosage_repository.dart';
import 'package:meditrack/repository/medicine_repository.dart';
import 'package:meditrack/repository/family_repository.dart';
import 'package:meditrack/services/family_dosage_notification_service.dart';

part 'dosage_event.dart';
part 'dosage_state.dart';

class DosageBloc extends Bloc<DosageEvent, DosageState> {
  //dependency injection
  final DosageRepository dosageRepository;
  final MedicineRepository medicineRepository;
  final FamilyRepository familyRepository;
  final FamilyDosageNotificationService familyNotificationService;

  DosageBloc({
    required this.dosageRepository,
    required this.medicineRepository,
    required this.familyRepository,
    required this.familyNotificationService,
  }) : super(DosageLoadingState()) {
    on<LoadDosagesEvent>(_loadDosages);
    on<AddDosageEvent>(_addDosage);
    on<UpdateDosageEvent>(_updateDosage);
    on<DeleteDosageEvent>(_deleteDosage);
    on<MarkDosageTimeTakenEvent>(_onMarkDosageTimeTaken);
  }

  Future<void> _loadDosages(LoadDosagesEvent event, Emitter<DosageState> emit) async {
    try {
      final dosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};

      if (currentState is DosageLoadedState) {
        updated.addAll(currentState.dosagesByMedicine);
      }

      updated[event.medId] = dosages;

      emit(DosageLoadedState(updated));
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }

  Future<void> _addDosage(AddDosageEvent event, Emitter<DosageState> emit) async {
    try {
      // Add dosage to Firestore
      await dosageRepository.addDosage(event.userId, event.medId, event.dosageData);

      // Get updated dosages
      final updatedDosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};

      if (currentState is DosageLoadedState) {
        updated.addAll(currentState.dosagesByMedicine);
      }

      updated[event.medId] = updatedDosages;
      emit(DosageLoadedState(updated));

      // NEW: Send family notifications if enabled
      if (event.dosageData['notifyFamilyMembers'] == true) {
        final familyMemberIds = List<String>.from(event.dosageData['selectedFamilyMemberIds'] ?? []);

        if (familyMemberIds.isNotEmpty) {

          // Get family account
          final familyAccount = await familyRepository.getFamilyAccountForUser(event.userId);

          if (familyAccount != null) {
            // Get medicine name
            final medicine = await medicineRepository.getMedicineById(event.userId, event.medId);
            final medicineName = medicine?.name ?? 'Medicine';

            // Get patient name
            final patientName = await familyNotificationService.getUserDisplayName(event.userId);

            // Send new schedule notification
            await familyNotificationService.notifyFamilyNewDosageSchedule(
              familyAccountId: familyAccount.id,
              familyMemberIds: familyMemberIds,
              medicineName: medicineName,
              dosage: event.dosageData['dosage'] ?? '',
              frequency: event.dosageData['frequency'] ?? '',
              patientName: patientName,
              patientUserId: event.userId,
            );

          }
        }
      }
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }

  Future<void> _updateDosage(UpdateDosageEvent event, Emitter<DosageState> emit) async {
    try {
      await dosageRepository.updateDosage(event.userId, event.medId, event.dosageId, event.updatedData);

      final updatedDosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};
      if (currentState is DosageLoadedState) updated.addAll(currentState.dosagesByMedicine);

      updated[event.medId] = updatedDosages;
      emit(DosageLoadedState(updated));
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }

  Future<void> _deleteDosage(DeleteDosageEvent event, Emitter<DosageState> emit) async {
    try {
      await dosageRepository.deleteDosage(event.userId, event.medId, event.dosageId);

      final updatedDosages = await dosageRepository.getDosages(event.userId, event.medId);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};
      if (currentState is DosageLoadedState) updated.addAll(currentState.dosagesByMedicine);

      updated[event.medId] = updatedDosages;
      emit(DosageLoadedState(updated));
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }

  Future<void> _onMarkDosageTimeTaken(MarkDosageTimeTakenEvent event, Emitter<DosageState> emit) async {
    try {
      // Mark as taken in Firestore
      await dosageRepository.markTimeAsTaken(event.userId, event.medId, event.dosageId, event.timeIndex);

      // Get updated dosages
      final updatedDosages = await dosageRepository.getDosages(event.userId, event.medId);

      // Decrement medicine quantity by the actual dosage amount
      final amount = MedicineRepository.parseDosageAmount(event.dosageString);
      await medicineRepository.decrementMedicineQuantity(event.userId, event.medId, amount: amount);

      final currentState = state;
      Map<String, List<Dosage>> updated = {};
      if (currentState is DosageLoadedState) updated.addAll(currentState.dosagesByMedicine);

      updated[event.medId] = updatedDosages;
      emit(DosageLoadedState(updated));

      // NEW: Send "dosage taken" notification to family
      final dosage = updatedDosages.firstWhere((d) => d.id == event.dosageId);

      if (dosage.notifyFamilyMembers && dosage.selectedFamilyMemberIds.isNotEmpty) {

        final familyAccount = await familyRepository.getFamilyAccountForUser(event.userId);

        if (familyAccount != null) {
          final medicine = await medicineRepository.getMedicineById(event.userId, event.medId);
          final medicineName = medicine?.name ?? 'Medicine';
          final patientName = await familyNotificationService.getUserDisplayName(event.userId);
          final time = dosage.times[event.timeIndex]['time'] ?? '';

          await familyNotificationService.notifyFamilyDosageTaken(
            familyAccountId: familyAccount.id,
            familyMemberIds: dosage.selectedFamilyMemberIds,
            medicineName: medicineName,
            dosage: dosage.dosage,
            time: time,
            patientName: patientName,
            patientUserId: event.userId,
          );

        }
      }
    } catch (e) {
      emit(DosageErrorState(e.toString()));
    }
  }
}
