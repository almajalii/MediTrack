import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/repository/medicine_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MedicineRepository repository;

  const userId = 'user_1';
  const medId = 'med_1';

  Medicine makeMedicine({
    String id = medId,
    String name = 'Aspirin',
    String type = 'Tablet',
    String category = 'Painkiller',
    String notes = 'After meals',
    int quantity = 10,
  }) =>
      Medicine(
        id: id,
        userId: userId,
        name: name,
        type: type,
        category: category,
        notes: notes,
        quantity: quantity,
        dateAdded: DateTime(2024, 1, 1),
        dateExpired: DateTime(2025, 12, 31),
      );

  Future<void> seedMedicine(Medicine med) => fakeFirestore
      .collection('users')
      .doc(userId)
      .collection('medicines')
      .doc(med.id)
      .set(med.toFirestore());

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = MedicineRepository(firestore: fakeFirestore);
  });

  // ---------------------------------------------------------------------------
  // getMedicines
  // ---------------------------------------------------------------------------
  group('getMedicines', () {
    test('emits an empty list when collection is empty', () async {
      final result = await repository.getMedicines(userId).first;
      expect(result, isEmpty);
    });

    test('emits all medicines for the user', () async {
      await seedMedicine(makeMedicine(id: 'a', name: 'Aspirin'));
      await seedMedicine(makeMedicine(id: 'b', name: 'Ibuprofen'));

      final result = await repository.getMedicines(userId).first;

      expect(result.length, 2);
      expect(result.map((m) => m.name), containsAll(['Aspirin', 'Ibuprofen']));
    });

    test('does not return medicines that belong to a different user', () async {
      await seedMedicine(makeMedicine(id: 'a'));
      await fakeFirestore
          .collection('users')
          .doc('other_user')
          .collection('medicines')
          .doc('b')
          .set(makeMedicine(id: 'b', name: 'Other').toFirestore());

      final result = await repository.getMedicines(userId).first;

      expect(result.length, 1);
      expect(result.first.name, 'Aspirin');
    });
  });

  // ---------------------------------------------------------------------------
  // addMedicine
  // ---------------------------------------------------------------------------
  group('addMedicine', () {
    test('added medicine appears in the getMedicines stream', () async {
      await repository.addMedicine(userId, makeMedicine());

      final result = await repository.getMedicines(userId).first;

      expect(result.length, 1);
      expect(result.first.name, 'Aspirin');
      expect(result.first.quantity, 10);
    });

    test('multiple medicines can be added independently', () async {
      await repository.addMedicine(userId, makeMedicine(id: 'a', name: 'Aspirin'));
      await repository.addMedicine(userId, makeMedicine(id: 'b', name: 'Ibuprofen'));

      final result = await repository.getMedicines(userId).first;

      expect(result.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // updateMedicine
  // ---------------------------------------------------------------------------
  group('updateMedicine', () {
    test('updated name and quantity are reflected in the stream', () async {
      await seedMedicine(makeMedicine());

      await repository.updateMedicine(
        userId,
        medId,
        makeMedicine(name: 'Aspirin Plus', quantity: 20),
      );

      final result = await repository.getMedicines(userId).first;

      expect(result.first.name, 'Aspirin Plus');
      expect(result.first.quantity, 20);
    });

    test('unmodified fields remain unchanged after update', () async {
      await seedMedicine(makeMedicine(category: 'Painkiller'));

      await repository.updateMedicine(
        userId,
        medId,
        makeMedicine(name: 'New Name', category: 'Painkiller'),
      );

      final result = await repository.getMedicines(userId).first;

      expect(result.first.category, 'Painkiller');
    });
  });

  // ---------------------------------------------------------------------------
  // removeMedicine
  // ---------------------------------------------------------------------------
  group('removeMedicine', () {
    test('medicine is no longer in the medicines collection after removal', () async {
      final med = makeMedicine();
      await seedMedicine(med);
      await repository.removeMedicine(userId, medId, med);

      final result = await repository.getMedicines(userId).first;

      expect(result, isEmpty);
    });

    test('removed medicine appears in the history collection', () async {
      final med = makeMedicine();
      await seedMedicine(med);
      await repository.removeMedicine(userId, medId, med);

      final history = await repository.getRemovedMedicines(userId).first;

      expect(history.length, 1);
      expect(history.first.name, 'Aspirin');
    });

    test('removing one medicine does not affect others', () async {
      await seedMedicine(makeMedicine(id: 'keep', name: 'Ibuprofen'));
      final toRemove = makeMedicine(id: 'remove', name: 'Aspirin');
      await seedMedicine(toRemove);

      await repository.removeMedicine(userId, 'remove', toRemove);

      final result = await repository.getMedicines(userId).first;

      expect(result.length, 1);
      expect(result.first.name, 'Ibuprofen');
    });
  });

  // ---------------------------------------------------------------------------
  // getRemovedMedicines
  // ---------------------------------------------------------------------------
  group('getRemovedMedicines', () {
    test('emits an empty list when history is empty', () async {
      final result = await repository.getRemovedMedicines(userId).first;
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteMedicine
  // ---------------------------------------------------------------------------
  group('deleteMedicine', () {
    test('permanently deletes medicine from history', () async {
      final med = makeMedicine();
      await seedMedicine(med);
      await repository.removeMedicine(userId, medId, med);
      await repository.deleteMedicine(userId, medId);

      final history = await repository.getRemovedMedicines(userId).first;

      expect(history, isEmpty);
    });

    test('deleting one history entry does not remove others', () async {
      final medA = makeMedicine(id: 'a', name: 'Aspirin');
      final medB = makeMedicine(id: 'b', name: 'Ibuprofen');
      await seedMedicine(medA);
      await seedMedicine(medB);
      await repository.removeMedicine(userId, 'a', medA);
      await repository.removeMedicine(userId, 'b', medB);

      await repository.deleteMedicine(userId, 'a');

      final history = await repository.getRemovedMedicines(userId).first;

      expect(history.length, 1);
      expect(history.first.name, 'Ibuprofen');
    });
  });

  // ---------------------------------------------------------------------------
  // decrementMedicineQuantity
  // ---------------------------------------------------------------------------
  group('decrementMedicineQuantity', () {
    test('reduces quantity by exactly 1', () async {
      await seedMedicine(makeMedicine(quantity: 5));
      await repository.decrementMedicineQuantity(userId, medId);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .doc(medId)
          .get();

      expect(doc['quantity'], 4);
    });

    test('does not decrement below 0 when quantity is already 0', () async {
      await seedMedicine(makeMedicine(quantity: 0));
      await repository.decrementMedicineQuantity(userId, medId);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .doc(medId)
          .get();

      expect(doc['quantity'], 0);
    });

    test('decrements from 1 to 0', () async {
      await seedMedicine(makeMedicine(quantity: 1));
      await repository.decrementMedicineQuantity(userId, medId);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .doc(medId)
          .get();

      expect(doc['quantity'], 0);
    });
  });

  // ---------------------------------------------------------------------------
  // searchMedicines
  // ---------------------------------------------------------------------------
  group('searchMedicines', () {
    setUp(() async {
      await seedMedicine(makeMedicine(id: 'a', name: 'Aspirin'));
      await seedMedicine(makeMedicine(id: 'b', name: 'Ibuprofen'));
      await seedMedicine(makeMedicine(id: 'c', name: 'Aspirin Plus'));
    });

    test('returns all medicines when query is empty', () async {
      final result = await repository.searchMedicines(userId, '').first;
      expect(result.length, 3);
    });

    test('matches medicines by name substring (case-insensitive)', () async {
      final result = await repository.searchMedicines(userId, 'aspirin').first;
      expect(result.length, 2);
      expect(result.every((m) => m.name.toLowerCase().contains('aspirin')), isTrue);
    });

    test('match is case-insensitive for uppercase query', () async {
      final result = await repository.searchMedicines(userId, 'IBUP').first;
      expect(result.length, 1);
      expect(result.first.name, 'Ibuprofen');
    });

    test('returns empty list when no medicine matches the query', () async {
      final result = await repository.searchMedicines(userId, 'zzz').first;
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getMedicinesByType
  // ---------------------------------------------------------------------------
  group('getMedicinesByType', () {
    setUp(() async {
      await seedMedicine(makeMedicine(id: 'a', name: 'Aspirin', type: 'Tablet'));
      await seedMedicine(makeMedicine(id: 'b', name: 'Cough Syrup', type: 'Syrup'));
    });

    test('returns only medicines matching the requested type', () async {
      final result = await repository.getMedicinesByType(userId, 'Tablet').first;
      expect(result.length, 1);
      expect(result.first.type, 'Tablet');
    });

    test('returns empty list when no medicines have that type', () async {
      final result = await repository.getMedicinesByType(userId, 'Injection').first;
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getMedicinesByCategory
  // ---------------------------------------------------------------------------
  group('getMedicinesByCategory', () {
    setUp(() async {
      await seedMedicine(makeMedicine(id: 'a', name: 'Aspirin', category: 'Painkiller'));
      await seedMedicine(makeMedicine(id: 'b', name: 'Amoxicillin', category: 'Antibiotic'));
    });

    test('returns only medicines in the requested category', () async {
      final result = await repository.getMedicinesByCategory(userId, 'Painkiller').first;
      expect(result.length, 1);
      expect(result.first.category, 'Painkiller');
    });

    test('returns empty list when no medicines belong to that category', () async {
      final result = await repository.getMedicinesByCategory(userId, 'Vitamin').first;
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getMedicinesByTypeAndCategory
  // ---------------------------------------------------------------------------
  group('getMedicinesByTypeAndCategory', () {
    setUp(() async {
      await seedMedicine(makeMedicine(id: 'a', type: 'Tablet', category: 'Painkiller'));
      await seedMedicine(makeMedicine(id: 'b', type: 'Syrup', category: 'Painkiller'));
      await seedMedicine(makeMedicine(id: 'c', type: 'Tablet', category: 'Antibiotic'));
    });

    test('returns medicines that match both type and category', () async {
      final result = await repository
          .getMedicinesByTypeAndCategory(userId, 'Tablet', 'Painkiller')
          .first;

      expect(result.length, 1);
      expect(result.first.type, 'Tablet');
      expect(result.first.category, 'Painkiller');
    });

    test('returns empty when type matches but category does not', () async {
      final result = await repository
          .getMedicinesByTypeAndCategory(userId, 'Tablet', 'Vitamin')
          .first;

      expect(result, isEmpty);
    });

    test('returns empty when category matches but type does not', () async {
      final result = await repository
          .getMedicinesByTypeAndCategory(userId, 'Injection', 'Painkiller')
          .first;

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // filterMedicines
  // ---------------------------------------------------------------------------
  group('filterMedicines', () {
    setUp(() async {
      await seedMedicine(makeMedicine(id: 'a', name: 'Aspirin', type: 'Tablet', category: 'Painkiller'));
      await seedMedicine(makeMedicine(id: 'b', name: 'Amoxicillin', type: 'Capsule', category: 'Antibiotic'));
      await seedMedicine(makeMedicine(id: 'c', name: 'Aspirin Plus', type: 'Tablet', category: 'Painkiller'));
    });

    test('returns all medicines when no filters are applied', () async {
      final result = await repository.filterMedicines(userId: userId).first;
      expect(result.length, 3);
    });

    test('filters by search query only', () async {
      final result = await repository
          .filterMedicines(userId: userId, searchQuery: 'aspirin')
          .first;

      expect(result.length, 2);
      expect(result.every((m) => m.name.toLowerCase().contains('aspirin')), isTrue);
    });

    test('filters by type only', () async {
      final result = await repository
          .filterMedicines(userId: userId, type: 'Tablet')
          .first;

      expect(result.length, 2);
      expect(result.every((m) => m.type == 'Tablet'), isTrue);
    });

    test('filters by category only', () async {
      final result = await repository
          .filterMedicines(userId: userId, category: 'Antibiotic')
          .first;

      expect(result.length, 1);
      expect(result.first.name, 'Amoxicillin');
    });

    test('combines search query and type filter', () async {
      final result = await repository
          .filterMedicines(userId: userId, searchQuery: 'Aspirin', type: 'Tablet')
          .first;

      expect(result.length, 2);
    });

    test('returns empty when no medicine satisfies all filters', () async {
      final result = await repository
          .filterMedicines(userId: userId, searchQuery: 'Aspirin', category: 'Antibiotic')
          .first;

      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getMedicineById
  // ---------------------------------------------------------------------------
  group('getMedicineById', () {
    test('returns the correct medicine when it exists', () async {
      await seedMedicine(makeMedicine());

      final result = await repository.getMedicineById(userId, medId);

      expect(result, isNotNull);
      expect(result!.id, medId);
      expect(result.name, 'Aspirin');
    });

    test('returns null when the medicine does not exist', () async {
      final result = await repository.getMedicineById(userId, 'nonexistent');
      expect(result, isNull);
    });

    test('returns null for a valid userId but wrong medId', () async {
      await seedMedicine(makeMedicine());

      final result = await repository.getMedicineById(userId, 'wrong_id');
      expect(result, isNull);
    });
  });
}
