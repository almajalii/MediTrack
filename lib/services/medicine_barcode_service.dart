import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicineBarcodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search for medicine by barcode
  /// Returns medicine data if found, null otherwise
  Future<Map<String, dynamic>?> getMedicineByBarcode(String barcode) async {
    try {
      final firebaseResult = await _searchFirebase(barcode);
      if (firebaseResult != null) return firebaseResult;

      final apiResult = await _searchOpenFoodFacts(barcode);
      if (apiResult != null) {
        await _saveBarcodeToFirebase(barcode, apiResult);
        return apiResult;
      }

      return null;
    } catch (e) {
      debugPrint('MedicineBarcodeService: unexpected error for barcode $barcode: $e');
      return null;
    }
  }

  /// Search Firebase for barcode
  Future<Map<String, dynamic>?> _searchFirebase(String barcode) async {
    try {

      final querySnapshot = await _firestore
          .collection('medicine_barcodes')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();


        return {
          'name': data['name'] ?? '',
          'type': data['type'] ?? '',
          'category': data['category'] ?? '',
          'dosage': data['dosage'] ?? '',
          'manufacturer': data['manufacturer'] ?? '',
          'source': 'firebase',
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search Open Food Facts API
  Future<Map<String, dynamic>?> _searchOpenFoodFacts(String barcode) async {
    try {

      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];

          // Check if it's actually a medicine/health product
          final categories = product['categories']?.toString().toLowerCase() ?? '';
          final isMedicine = categories.contains('health') ||
              categories.contains('medicine') ||
              categories.contains('pharmaceutical') ||
              categories.contains('supplement') ||
              categories.contains('vitamin');

          if (isMedicine || product['product_name'] != null) {

            return {
              'name': product['product_name'] ?? product['generic_name'] ?? 'Unknown',
              'type': _guessType(product),
              'category': _guessCategory(categories),
              'dosage': product['quantity'] ?? '',
              'manufacturer': product['brands'] ?? '',
              'source': 'openfoodfacts',
            };
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save barcode data to Firebase for future use
  Future<void> _saveBarcodeToFirebase(String barcode, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('medicine_barcodes').add({
        'barcode': barcode,
        'name': data['name'],
        'type': data['type'],
        'category': data['category'],
        'dosage': data['dosage'],
        'manufacturer': data['manufacturer'],
        'addedAt': FieldValue.serverTimestamp(),
        'source': data['source'],
      });
    } catch (e) {
      debugPrint('MedicineBarcodeService: failed to cache barcode $barcode in Firebase: $e');
    }
  }

  /// Save user-entered medicine data with barcode
  Future<void> saveUserMedicineBarcode({
    required String barcode,
    required String name,
    required String type,
    required String category,
    String? dosage,
  }) async {
    try {

      // Check if barcode already exists
      final existing = await _firestore
          .collection('medicine_barcodes')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('medicine_barcodes').add({
          'barcode': barcode,
          'name': name,
          'type': type,
          'category': category,
          'dosage': dosage ?? '',
          'manufacturer': '',
          'addedAt': FieldValue.serverTimestamp(),
          'source': 'user',
        });

      }
    } catch (e) {
      debugPrint('MedicineBarcodeService: failed to save user barcode $barcode: $e');
    }
  }

  /// Guess medicine type from product data
  String _guessType(Map<String, dynamic> product) {
    final name = product['product_name']?.toString().toLowerCase() ?? '';
    final categories = product['categories']?.toString().toLowerCase() ?? '';

    if (name.contains('tablet') || categories.contains('tablet')) return 'Tablet';
    if (name.contains('capsule') || categories.contains('capsule')) return 'Capsule';
    if (name.contains('syrup') || categories.contains('syrup')) return 'Syrup';
    if (name.contains('injection') || categories.contains('injection')) return 'Injection';
    if (name.contains('cream') || categories.contains('cream')) return 'Cream';
    if (name.contains('drops') || categories.contains('drops')) return 'Drops';
    if (name.contains('spray') || categories.contains('spray')) return 'Spray';
    if (name.contains('inhaler') || categories.contains('inhaler')) return 'Inhaler';

    return 'Other';
  }

  /// Guess medicine category from product data
  String _guessCategory(String categories) {
    if (categories.contains('pain') || categories.contains('analgesic')) return 'Painkiller';
    if (categories.contains('antibiotic')) return 'Antibiotic';
    if (categories.contains('vitamin') || categories.contains('supplement')) return 'Vitamin / Supplement';
    if (categories.contains('allergy') || categories.contains('antihistamine')) return 'Allergy';
    if (categories.contains('cold') || categories.contains('flu')) return 'Cough & Cold';
    if (categories.contains('stomach') || categories.contains('antacid')) return 'Antacid / Stomach';
    if (categories.contains('heart') || categories.contains('cardiovascular')) return 'Heart';
    if (categories.contains('diabetes')) return 'Diabetes';
    if (categories.contains('pressure') || categories.contains('hypertension')) return 'Blood Pressure';

    return 'Other';
  }

  /// Get barcode usage statistics
  Future<Map<String, int>> getBarcodeStats() async {
    try {
      final snapshot = await _firestore.collection('medicine_barcodes').get();

      final stats = {
        'total': snapshot.docs.length,
        'user_added': 0,
        'api_added': 0,
      };

      for (var doc in snapshot.docs) {
        final source = doc.data()['source'] ?? 'unknown';
        if (source == 'user') {
          stats['user_added'] = (stats['user_added'] ?? 0) + 1;
        } else {
          stats['api_added'] = (stats['api_added'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      return {'total': 0, 'user_added': 0, 'api_added': 0};
    }
  }
}
