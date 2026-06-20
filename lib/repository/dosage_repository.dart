import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/dosage.dart';

class DosageRepository {
  final FirebaseFirestore _firestore;

  DosageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  //1 GetDosages (Fetches all dosages for a specific medicine once.)
  //when the app needs a snapshot of dosages at a moment in time,
  Future<List<Dosage>> getDosages(String userId, String medId) async {
    final querySnapshot =
        await _firestore.collection('users').doc(userId).collection('medicines').doc(medId).collection('dosages').get();

    return querySnapshot.docs.map((doc) => Dosage.fromFirestore(doc)).toList();
  }

  //2 DosageStream Continuous stream of dosages
  //when you want the UI to react instantly to changes in Firestore without manual refresh.
  Stream<List<Dosage>> dosageStream(String userId, String medId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medId)
        .collection('dosages')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Dosage.fromFirestore(doc)).toList());
  }
  //3 AddDosage
  Future<void> addDosage(String userId, String medId, Map<String, dynamic> dosageData) async {
    // Ensure times field is properly formatted
    if (dosageData['times'] != null && dosageData['times'] is List) {
      dosageData['times'] =
          (dosageData['times'] as List).map((t) {
            final map = Map<String, dynamic>.from(t);
            if (map['takenDate'] != null && map['takenDate'] is! Timestamp) {
              map['takenDate'] = Timestamp.fromDate(DateTime.parse(map['takenDate'].toString()));
            }
            return map;
          }).toList();
    }

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("medicines")
        .doc(medId)
        .collection("dosages")
        .add(dosageData);
  }
  //4 updateDosage
  Future<void> updateDosage(String userId, String medId, String dosageId, Map<String, dynamic> updatedData) async {
    await _firestore
        .collection("users")
        .doc(userId)
        .collection("medicines")
        .doc(medId)
        .collection("dosages")
        .doc(dosageId)
        .update(updatedData);
  }
  //5 deleteDosage
  Future<void> deleteDosage(String userId, String medId, String dosageId) async {
    await _firestore
        .collection("users")
        .doc(userId)
        .collection("medicines")
        .doc(medId)
        .collection("dosages")
        .doc(dosageId)
        .delete();
  }
  //update the takenDate
  Future<void> markTimeAsTaken(String userId, String medId, String dosageId, int timeIndex) async {
    //timeIndex → which time in the times list to mark as taken
    //dosageRef points to the exact Firestore document we want to update.
    final dosageRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medId)
        .collection('dosages')
        .doc(dosageId);

    //A transaction ensures that all reads/writes happen atomically.
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(dosageRef);
      if (!snapshot.exists) throw Exception('Dosage not found');
      //makes a copy of it and then changes the takenDate
      final times = List<Map<String, dynamic>>.from(snapshot['times'].cast<Map<String, dynamic>>());
      times[timeIndex]['takenDate'] = Timestamp.now();

      transaction.update(dosageRef, {'times': times});//only updates the time
    });
  }
}
