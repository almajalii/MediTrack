import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../model/pharmacy.dart';

class PharmacyService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  Future<List<Pharmacy>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    final query =
        '[out:json];node["amenity"="pharmacy"](around:$radius,$latitude,$longitude);out body;';

    const headers = {'Accept': '*/*', 'User-Agent': 'MediTrackApp/1.0'};

    http.Response response;
    try {
      final uri = Uri.parse(_overpassUrl).replace(queryParameters: {'data': query});
      response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    } catch (primaryError) {
      try {
        final mirrorUri = Uri.parse('https://overpass.kumi.systems/api/interpreter')
            .replace(queryParameters: {'data': query});
        response = await http.get(mirrorUri, headers: headers).timeout(const Duration(seconds: 20));
      } catch (mirrorError) {
        throw Exception(
          'Overpass API unreachable. Primary: $primaryError. Mirror: $mirrorError',
        );
      }
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Overpass API error ${response.statusCode}: '
        '${response.body.substring(0, response.body.length.clamp(0, 300))}',
      );
    }

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Invalid JSON response from Overpass API');
    }

    final elements = (data['elements'] as List?) ?? [];

    return elements
        .map((e) {
          final pharmLat = (e['lat'] as num?)?.toDouble();
          final pharmLng = (e['lon'] as num?)?.toDouble();
          if (pharmLat == null || pharmLng == null) return null;
          final distance = calculateDistance(latitude, longitude, pharmLat, pharmLng);
          final tags = (e['tags'] as Map<String, dynamic>?) ?? {};
          final openingHours = tags['opening_hours'] as String?;

          return Pharmacy(
            placeId: e['id'].toString(),
            name: tags['name'] as String? ?? 'Pharmacy',
            address: tags['addr:street'] != null
                ? '${tags['addr:street']} ${tags['addr:housenumber'] ?? ''}'.trim()
                : 'Address not available',
            latitude: pharmLat,
            longitude: pharmLng,
            isOpen: openingHours == null ? null : openingHours == '24/7',
            phoneNumber: tags['phone'] as String?,
            distance: distance,
          );
        })
        .whereType<Pharmacy>()
        .toList()
      ..sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    return null; // Not needed with Overpass
  }
}
