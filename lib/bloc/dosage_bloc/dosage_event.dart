part of 'dosage_bloc.dart';

abstract class DosageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}
//load, add, update, taken, delete
//1
class LoadDosagesEvent extends DosageEvent {
  final String userId;
  final String medId;

  LoadDosagesEvent(this.userId, this.medId);

  @override
  List<Object> get props => [userId, medId];
}
//2
class AddDosageEvent extends DosageEvent {
  final String userId;
  final String medId;
  final Map<String, dynamic> dosageData;

  AddDosageEvent(this.userId, this.medId, this.dosageData);

  @override
  List<Object> get props => [userId, medId, dosageData];
}
//3
class UpdateDosageEvent extends DosageEvent {
  final String userId;
  final String medId;
  final String dosageId;
  final Map<String, dynamic> updatedData;

  UpdateDosageEvent(this.userId, this.medId, this.dosageId, this.updatedData);

  @override
  List<Object> get props => [userId, medId, dosageId, updatedData];
}

//4
class DeleteDosageEvent extends DosageEvent {
  final String userId;
  final String medId;
  final String dosageId;

  DeleteDosageEvent(this.userId, this.medId, this.dosageId);

  @override
  List<Object> get props => [userId, medId, dosageId];
}

//5
class MarkDosageTimeTakenEvent extends DosageEvent {
  final String userId;
  final String medId;
  final String dosageId;
  final int timeIndex;//which time in the list
  final String dosageString; // e.g. "2 tablets", "500mg"

  MarkDosageTimeTakenEvent(this.userId, this.medId, this.dosageId, this.timeIndex, this.dosageString);

  @override
  List<Object> get props => [userId, medId, dosageId, timeIndex, dosageString];
}
