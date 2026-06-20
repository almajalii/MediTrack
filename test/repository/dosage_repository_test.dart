import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/repository/dosage_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DosageRepository repository;

  const userId = 'user_1';
  const medId = 'med_1';
  const dosageId = 'dosage_1';

  Map<String, dynamic> makeDosageData({
    String dosage = '500mg',
    String frequency = 'Daily',
    List<Map<String, dynamic>>? times,
    bool notifyFamily = false,
  }) =>
      {
        'medicineId': medId,
        'dosage': dosage,
        'frequency': frequency,
        'times': times ??
            [
              {'time': '08:00 AM', 'takenDate': null},
              {'time': '08:00 PM', 'takenDate': null},
            ],
        'startDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'addedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'notifyFamilyMembers': notifyFamily,
        'selectedFamilyMemberIds': <String>[],
      };

  CollectionReference dosagesRef() => fakeFirestore
      .collection('users')
      .doc(userId)
      .collection('medicines')
      .doc(medId)
      .collection('dosages');

  Future<void> seedDosage({
    String id = dosageId,
    Map<String, dynamic>? data,
  }) =>
      dosagesRef().doc(id).set(data ?? makeDosageData());

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = DosageRepository(firestore: fakeFirestore);
  });

  // ---------------------------------------------------------------------------
  // getDosages
  // ---------------------------------------------------------------------------
  group('getDosages', () {
    test('returns an empty list when no dosages exist', () async {
      final result = await repository.getDosages(userId, medId);
      expect(result, isEmpty);
    });

    test('returns all dosages for the given medicine', () async {
      await seedDosage(id: 'a', data: makeDosageData(dosage: '100mg'));
      await seedDosage(id: 'b', data: makeDosageData(dosage: '200mg'));

      final result = await repository.getDosages(userId, medId);

      expect(result.length, 2);
      expect(result.map((d) => d.dosage), containsAll(['100mg', '200mg']));
    });

    test('maps Firestore documents to Dosage models correctly', () async {
      await seedDosage();

      final result = await repository.getDosages(userId, medId);

      expect(result.first.dosage, '500mg');
      expect(result.first.frequency, 'Daily');
      expect(result.first.medicineId, medId);
      expect(result.first.times.length, 2);
      expect(result.first.times.first['time'], '08:00 AM');
      expect(result.first.notifyFamilyMembers, isFalse);
    });

    test('does not return dosages from a different medicine', () async {
      await seedDosage();
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .doc('other_med')
          .collection('dosages')
          .doc('x')
          .set(makeDosageData(dosage: '999mg'));

      final result = await repository.getDosages(userId, medId);

      expect(result.length, 1);
      expect(result.first.dosage, '500mg');
    });
  });

  // ---------------------------------------------------------------------------
  // dosageStream
  // ---------------------------------------------------------------------------
  group('dosageStream', () {
    test('emits an empty list when no dosages exist', () async {
      final result = await repository.dosageStream(userId, medId).first;
      expect(result, isEmpty);
    });

    test('emits the current dosages on subscription', () async {
      await seedDosage();

      final result = await repository.dosageStream(userId, medId).first;

      expect(result.length, 1);
      expect(result.first.dosage, '500mg');
    });

    test('emits updated list after a dosage is added', () async {
      await seedDosage(id: 'a');

      final stream = repository.dosageStream(userId, medId);
      await stream.first; // consume initial emission

      await seedDosage(id: 'b', data: makeDosageData(dosage: '250mg'));

      final result = await stream.first;
      expect(result.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // addDosage
  // ---------------------------------------------------------------------------
  group('addDosage', () {
    test('added dosage can be retrieved with getDosages', () async {
      await repository.addDosage(userId, medId, makeDosageData());

      final result = await repository.getDosages(userId, medId);

      expect(result.length, 1);
      expect(result.first.dosage, '500mg');
      expect(result.first.frequency, 'Daily');
    });

    test('converts String takenDate values to Timestamp before storing', () async {
      final data = makeDosageData(times: [
        {
          'time': '08:00 AM',
          'takenDate': DateTime(2024, 6, 1).toIso8601String(),
        },
      ]);

      await repository.addDosage(userId, medId, data);

      final docs = await dosagesRef().get();
      final savedTimes =
          List<Map<String, dynamic>>.from(docs.docs.first['times']);

      expect(savedTimes.first['takenDate'], isA<Timestamp>());
    });

    test('leaves null takenDate values unchanged', () async {
      await repository.addDosage(userId, medId, makeDosageData());

      final docs = await dosagesRef().get();
      final savedTimes =
          List<Map<String, dynamic>>.from(docs.docs.first['times']);

      expect(savedTimes.first['takenDate'], isNull);
    });

    test('stores family notification fields correctly', () async {
      final data = makeDosageData(notifyFamily: true);
      data['selectedFamilyMemberIds'] = ['member_1', 'member_2'];

      await repository.addDosage(userId, medId, data);

      final result = await repository.getDosages(userId, medId);

      expect(result.first.notifyFamilyMembers, isTrue);
      expect(result.first.selectedFamilyMemberIds, ['member_1', 'member_2']);
    });
  });

  // ---------------------------------------------------------------------------
  // updateDosage
  // ---------------------------------------------------------------------------
  group('updateDosage', () {
    test('updated dosage field is reflected in getDosages', () async {
      await seedDosage();

      await repository.updateDosage(
          userId, medId, dosageId, {'dosage': '250mg'});

      final result = await repository.getDosages(userId, medId);

      expect(result.first.dosage, '250mg');
    });

    test('updated frequency is persisted', () async {
      await seedDosage();

      await repository.updateDosage(
          userId, medId, dosageId, {'frequency': 'Twice Daily'});

      final result = await repository.getDosages(userId, medId);

      expect(result.first.frequency, 'Twice Daily');
    });

    test('updating one dosage does not affect others', () async {
      await seedDosage(id: 'a', data: makeDosageData(dosage: '100mg'));
      await seedDosage(id: 'b', data: makeDosageData(dosage: '200mg'));

      await repository.updateDosage(userId, medId, 'a', {'dosage': '999mg'});

      final result = await repository.getDosages(userId, medId);
      final dosageB = result.firstWhere((d) => d.id == 'b');

      expect(dosageB.dosage, '200mg');
    });
  });

  // ---------------------------------------------------------------------------
  // deleteDosage
  // ---------------------------------------------------------------------------
  group('deleteDosage', () {
    test('deleted dosage no longer appears in getDosages', () async {
      await seedDosage();
      await repository.deleteDosage(userId, medId, dosageId);

      final result = await repository.getDosages(userId, medId);

      expect(result, isEmpty);
    });

    test('deleting one dosage does not remove others', () async {
      await seedDosage(id: 'keep', data: makeDosageData(dosage: '100mg'));
      await seedDosage(id: 'remove', data: makeDosageData(dosage: '200mg'));

      await repository.deleteDosage(userId, medId, 'remove');

      final result = await repository.getDosages(userId, medId);

      expect(result.length, 1);
      expect(result.first.id, 'keep');
    });
  });

  // ---------------------------------------------------------------------------
  // markTimeAsTaken
  // ---------------------------------------------------------------------------
  group('markTimeAsTaken', () {
    test('sets takenDate on the specified time index', () async {
      await seedDosage();
      final before = DateTime.now().subtract(const Duration(seconds: 1));

      await repository.markTimeAsTaken(userId, medId, dosageId, 0);

      final doc = await dosagesRef().doc(dosageId).get();
      final times = List<Map<String, dynamic>>.from(doc['times']);
      final takenDate = (times[0]['takenDate'] as Timestamp).toDate();

      expect(takenDate.isAfter(before), isTrue);
    });

    test('only marks the specified index, leaving other times unchanged', () async {
      await seedDosage();
      await repository.markTimeAsTaken(userId, medId, dosageId, 0);

      final doc = await dosagesRef().doc(dosageId).get();
      final times = List<Map<String, dynamic>>.from(doc['times']);

      expect(times[0]['takenDate'], isNotNull);
      expect(times[1]['takenDate'], isNull);
    });

    test('can mark the last time index', () async {
      await seedDosage();
      await repository.markTimeAsTaken(userId, medId, dosageId, 1);

      final doc = await dosagesRef().doc(dosageId).get();
      final times = List<Map<String, dynamic>>.from(doc['times']);

      expect(times[1]['takenDate'], isNotNull);
      expect(times[0]['takenDate'], isNull);
    });

    test('throws when the dosage document does not exist', () async {
      await expectLater(
        repository.markTimeAsTaken(userId, medId, 'nonexistent', 0),
        throwsA(isA<Exception>()),
      );
    });
  });
}
