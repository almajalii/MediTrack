class Pharmacy {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final bool? isOpen;
  final String? phoneNumber;
  final double? distance; // in kilometers

  Pharmacy({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.isOpen,
    this.phoneNumber,
    this.distance,
  });

  // Create from Google Places API response
  factory Pharmacy.fromJson(Map<String, dynamic> json, double? distance) {
    final location = json['geometry']['location'];
    final openingHours = json['opening_hours'];
    
    return Pharmacy(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Pharmacy',
      address: json['vicinity'] ?? json['formatted_address'] ?? 'Address not available',
      latitude: location['lat']?.toDouble() ?? 0.0,
      longitude: location['lng']?.toDouble() ?? 0.0,
      rating: json['rating']?.toDouble(),
      isOpen: openingHours != null ? (openingHours['open_now'] ?? false) : false,
      phoneNumber: json['formatted_phone_number'],
      distance: distance,
    );
  }
}