import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meditrack/model/pharmacy.dart';
import 'package:meditrack/services/pharmacy_service.dart';
import 'package:meditrack/style/colors.dart';

class PharmacySearchScreen extends StatefulWidget {
  const PharmacySearchScreen({super.key});

  @override
  State<PharmacySearchScreen> createState() => _PharmacySearchScreenState();
}

class _PharmacySearchScreenState extends State<PharmacySearchScreen> {
  final PharmacyService _pharmacyService = PharmacyService();

  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;
  // ignore: unused_field
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchNearbyPharmacies();
  }

  Future<void> _searchNearbyPharmacies() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      final position = await _pharmacyService.getCurrentLocation();

      if (position == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unable to get your location. Please enable location services.';
          _isLoading = false;
          _isSearching = false;
        });
        return;
      }

      // Search for pharmacies
      final pharmacies = await _pharmacyService.searchNearbyPharmacies(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 5000, // 5km
      );

      if (!mounted) return;
      setState(() {
        _pharmacies = pharmacies;
        _isLoading = false;
        _isSearching = false;
        if (pharmacies.isEmpty) {
          _errorMessage = 'No pharmacies found nearby. Try increasing search radius.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error searching for pharmacies: $e';
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  Future<void> _openInMaps(Pharmacy pharmacy) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${pharmacy.latitude},${pharmacy.longitude}&query_place_id=${pharmacy.placeId}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open Google Maps'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Nearby Pharmacies'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _searchNearbyPharmacies,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget(isDarkMode);
    }

    if (_pharmacies.isEmpty) {
      return _buildEmptyWidget(isDarkMode);
    }

    return _buildPharmacyList(isDarkMode);
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Searching for nearby pharmacies...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _searchNearbyPharmacies,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_pharmacy_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No pharmacies found nearby',
            style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text('Try searching in a different location', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildPharmacyList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = _pharmacies[index];
        return _buildPharmacyCard(pharmacy, isDarkMode);
      },
    );
  }

  Widget _buildPharmacyCard(Pharmacy pharmacy, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    pharmacy.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ),
                if (pharmacy.isOpen != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pharmacy.isOpen! ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pharmacy.isOpen! ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: pharmacy.isOpen! ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pharmacy.address,
                    style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Distance and Rating
            Row(
              children: [
                if (pharmacy.distance != null) ...[
                  Icon(Icons.directions_walk, size: 18, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${pharmacy.distance!.toStringAsFixed(1)} km',
                    style: TextStyle(fontSize: 14, color: Colors.blue[600], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                ],
                if (pharmacy.rating != null) ...[
                  Icon(Icons.star, size: 18, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    pharmacy.rating!.toStringAsFixed(1),
                    style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Action button - only Directions
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openInMaps(pharmacy),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Get Directions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
