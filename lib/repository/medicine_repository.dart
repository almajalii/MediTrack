//middle layer between your Firestore database and your BLoC
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/medicine.dart';

class MedicineRepository {
  final FirebaseFirestore firestore;

  MedicineRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  //1 getMedicines
  Stream<List<Medicine>> getMedicines(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //2 addMedicines
  Future<void> addMedicine(String userId, Medicine medicine) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .add(medicine.toFirestore());
  }

  //3 updateMedicines
  Future<void> updateMedicine(
      String userId,
      String medId,
      Medicine medicine,
      ) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medId)
        .update(medicine.toFirestore());
  }

  //4 Remove medicine (move to recycle bin)
  Future<void> removeMedicine(
      String userId,
      String medId,
      Medicine medicine,
      ) async {
    final medRef = firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medId);

    // 1. Move to recycle bin (top-level history collection)
    await firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(medId)
        .set(medicine.toFirestore());

    // 2. Delete from main list
    await medRef.delete();
  }

  //5 Get removed medicines from recycle bin
  Stream<List<Medicine>> getRemovedMedicines(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //6 Permanently delete from recycle bin
  Future<void> deleteMedicine(String userId, String medId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(medId)
        .delete();
  }

  //7 decrement quantity by the dosage amount
  Future<void> decrementMedicineQuantity(String userId, String medId, {int amount = 1}) async {
    final docRef = firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .doc(medId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final currentQty = (snapshot['quantity'] ?? 0) as int;

      if (currentQty > 0) {
        final newQty = (currentQty - amount).clamp(0, currentQty);
        transaction.update(docRef, {'quantity': newQty});
      }
    });
  }

  // Parses the numeric unit count from a dosage string.
  // "2 tablets" → 2, "500mg" → 1 (strength unit, not a count), "1 capsule" → 1
  static int parseDosageAmount(String dosage) {
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*(.*)').firstMatch(dosage.trim());
    if (match == null) return 1;

    final number = double.tryParse(match.group(1) ?? '') ?? 1.0;
    final unit = (match.group(2) ?? '').toLowerCase().trim();

    // Strength units → quantity means 1 physical unit (pill/capsule/etc.)
    const strengthUnits = ['mg', 'mcg', 'g', 'ml', 'l', 'iu', 'μg', 'mmol'];
    for (final su in strengthUnits) {
      if (unit.startsWith(su)) return 1;
    }

    return number.round().clamp(1, 20);
  }

  //8 Search medicines by name
  Stream<List<Medicine>> searchMedicines(String userId, String query) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .snapshots()
        .map((snapshot) {
      final allMeds =
      snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
      if (query.isEmpty) return allMeds;
      return allMeds
          .where(
            (med) => med.name.toLowerCase().contains(query.toLowerCase()),
      )
          .toList();
    });
  }

  //9 Filter medicines by type
  Stream<List<Medicine>> getMedicinesByType(String userId, String type) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .where('type', isEqualTo: type)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //10 Filter medicines by category
  Stream<List<Medicine>> getMedicinesByCategory(String userId, String category) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //11 Filter medicines by type AND category
  Stream<List<Medicine>> getMedicinesByTypeAndCategory(
      String userId, String type, String category) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .where('type', isEqualTo: type)
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList(),
    );
  }

  //12 Advanced filter - combines search, type, and category
  Stream<List<Medicine>> filterMedicines({
    required String userId,
    String? searchQuery,
    String? type,
    String? category,
  }) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('medicines')
        .snapshots()
        .map((snapshot) {
      var medicines =
      snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        medicines = medicines
            .where((med) =>
            med.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }

      // Apply type filter
      if (type != null && type.isNotEmpty) {
        medicines = medicines.where((med) => med.type == type).toList();
      }

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        medicines =
            medicines.where((med) => med.category == category).toList();
      }

      return medicines;
    });
  }

  // NEW: 13 Get a single medicine by ID (for family notifications)
  Future<Medicine?> getMedicineById(String userId, String medId) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .doc(medId)
          .get();

      if (!doc.exists) return null;

      return Medicine.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }
}
