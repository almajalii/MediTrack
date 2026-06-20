import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/widgets/ExpiryReminder.dart';
import 'package:meditrack/widgets/app_bar.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/widgets/Time.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/services/image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../bloc/image_bloc/image_bloc.dart';
import '../../bloc/image_bloc/image_event.dart';
import '../../bloc/image_bloc/image_state.dart';
import '../../repository/medicine_constants.dart';
import '../../widgets/MyDropDownField.dart';
import '../../services/medicine_barcode_service.dart';

class AddMedicine extends StatefulWidget {
  const AddMedicine({super.key});

  @override
  State<AddMedicine> createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController medName = TextEditingController();
  final TextEditingController medNotes = TextEditingController();
  final TextEditingController medType = TextEditingController();
  final TextEditingController medCategory = TextEditingController();
  final TextEditingController expDate = TextEditingController();
  final TextEditingController quantity = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final myTextField = MyTextField();
  final LocalImageService _imageService = LocalImageService();
  final MedicineBarcodeService _barcodeService = MedicineBarcodeService();

  final User? userCredential = FirebaseAuth.instance.currentUser;

  bool _isUploadingImage = false;
  bool _isSearchingBarcode = false;

  // ── Validators ──────────────────────────────────────────────────────────────

  String? _nameValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Medicine name is required';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 100) return 'Name is too long (max 100 characters)';
    if (!RegExp(r'[a-zA-Z]').hasMatch(v)) return 'Name must contain at least one letter';
    return null;
  }

  String? _requiredDropdownValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please select an option';
    return null;
  }

  String? _quantityValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Quantity is required';
    final n = int.tryParse(v);
    if (n == null) return 'Enter a valid whole number';
    if (n < 1) return 'Quantity must be at least 1';
    if (n > 9999) return 'Quantity is too high (max 9999)';
    return null;
  }

  // Expiry validated manually in submitMedicine since ExpiryDatePicker
  // doesn't expose a validator parameter.
  String? _validateExpiry() {
    final v = expDate.text.trim();
    if (v.isEmpty) return 'Expiry date is required';
    try {
      final parts = v.split('-');
      if (parts.length != 3) return 'Invalid date format';
      final date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      if (date.isBefore(DateTime.now())) return 'This medicine has already expired';
    } catch (_) {
      return 'Invalid date';
    }
    return null;
  }

  // ── Barcode ─────────────────────────────────────────────────────────────────

  Future<void> _searchMedicineByBarcode(String barcode) async {
    setState(() => _isSearchingBarcode = true);
    try {
      final medicineData = await _barcodeService.getMedicineByBarcode(barcode);
      if (medicineData != null) {
        setState(() {
          if (medName.text.isEmpty) medName.text = medicineData['name'] ?? '';
          if (medType.text.isEmpty && (medicineData['type']?.isNotEmpty ?? false)) {
            medType.text = medicineData['type']!;
          }
          if (medCategory.text.isEmpty && (medicineData['category']?.isNotEmpty ?? false)) {
            medCategory.text = medicineData['category']!;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Found: ${medicineData['name']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Barcode not found. Please fill in the details manually.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error searching barcode. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isSearchingBarcode = false);
    }
  }

  Future<void> _scanBarcode() async {
    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BarcodeScannerScreen(
          onBarcodeScanned: (_) {},
        ),
      ),
    );
    if (barcode != null && barcode.isNotEmpty) {
      setState(() => barcodeController.text = barcode);
      await _searchMedicineByBarcode(barcode);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> submitMedicine(File? selectedImage) async {
    if (!formKey.currentState!.validate()) return;

    final expiryError = _validateExpiry();
    if (expiryError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(expiryError),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }

    setState(() => _isUploadingImage = true);

    if (barcodeController.text.isNotEmpty) {
      await _barcodeService.saveUserMedicineBarcode(
        barcode: barcodeController.text,
        name: medName.text.trim(),
        type: medType.text.trim(),
        category: medCategory.text.trim(),
        dosage: medNotes.text.trim(),
      );
    }

    String? imagePath;
    if (selectedImage != null && await selectedImage.exists()) {
      imagePath = await _imageService.saveImageLocally(
        imageFile: selectedImage,
        userId: userCredential?.uid ?? '',
        medicineName: medName.text.trim(),
      );
    }

    setState(() => _isUploadingImage = false);

    final newMedicine = Medicine(
      id: '',
      userId: userCredential?.uid ?? '',
      name: medName.text.trim(),
      type: medType.text.trim(),
      category: medCategory.text.trim(),
      notes: medNotes.text.trim(),
      quantity: int.tryParse(quantity.text.trim()) ?? 0,
      dateAdded: DateTime.now(),
      dateExpired: expDate.text.isNotEmpty
          ? DateTime.tryParse(expDate.text.split('-').reversed.join('-')) ??
              DateTime.now()
          : DateTime.now().add(const Duration(days: 365)),
      imageUrl: imagePath,
    );

    if (mounted) {
      context.read<MedicineBloc>().add(
            AddMedicineEvent(userCredential?.uid ?? '', newMedicine),
          );
      context.read<ImageBloc>().add(const RemoveImageEvent());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Medicine added successfully!'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    final file = await _imageService.showImageSourceDialog(context);
    if (file != null && await file.exists()) {
      if (mounted) context.read<ImageBloc>().add(SetImageEvent(file));
    }
  }

  @override
  void dispose() {
    medName.dispose();
    medNotes.dispose();
    medType.dispose();
    medCategory.dispose();
    expDate.dispose();
    quantity.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  // ── UI helpers ───────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 17),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[300] : AppColors.darkBlue,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required bool isDarkMode,
    IconData? prefixIcon,
    String? hint,
    Widget? suffix,
  }) {
    final borderColor =
        isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFC8D1DC);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
      labelStyle:
          TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              size: 20)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightGray,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: MyAppBar.build(context, () => ExpiryReminder()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF007FA8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(FontAwesomeIcons.pills,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Medicine',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fill in the details below',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Basic Info ───────────────────────────────────────────────
                _sectionCard(
                  title: 'Basic Information',
                  icon: Icons.medication_outlined,
                  isDarkMode: isDarkMode,
                  children: [
                    TextFormField(
                      controller: medName,
                      textCapitalization: TextCapitalization.words,
                      validator: _nameValidator,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                      decoration: _fieldDecoration(
                        label: 'Medicine Name',
                        isDarkMode: isDarkMode,
                        prefixIcon: Icons.medication,
                        hint: 'e.g. Paracetamol 500mg',
                      ),
                    ),
                    const SizedBox(height: 14),
                    MyDropdownField(
                      label: 'Medicine Type',
                      value: medType.text,
                      items: medicineTypes,
                      validator: _requiredDropdownValidator,
                      onChanged: (value) =>
                          setState(() => medType.text = value!),
                    ),
                    MyDropdownField(
                      label: 'Medicine Category',
                      value: medCategory.text,
                      items: medicineCategories,
                      validator: _requiredDropdownValidator,
                      onChanged: (value) =>
                          setState(() => medCategory.text = value!),
                    ),
                  ],
                ),

                // ── Dosage & Quantity ────────────────────────────────────────
                _sectionCard(
                  title: 'Dosage & Quantity',
                  icon: Icons.format_list_numbered,
                  isDarkMode: isDarkMode,
                  children: [
                    TextFormField(
                      controller: medNotes,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                      maxLines: 2,
                      decoration: _fieldDecoration(
                        label: 'Notes / Dosage (optional)',
                        isDarkMode: isDarkMode,
                        prefixIcon: Icons.notes,
                        hint: 'e.g. 500mg, twice daily after meals',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: quantity,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _quantityValidator,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                      decoration: _fieldDecoration(
                        label: 'Quantity',
                        isDarkMode: isDarkMode,
                        prefixIcon: Icons.inventory,
                        hint: 'e.g. 30',
                      ),
                    ),
                  ],
                ),

                // ── Expiry ───────────────────────────────────────────────────
                _sectionCard(
                  title: 'Expiry Date',
                  icon: Icons.calendar_today_outlined,
                  isDarkMode: isDarkMode,
                  children: [
                    ExpiryDatePicker(
                      controller: expDate,
                      labelText: 'Select Expiry Date',
                      onDateChanged: (date) {
                        expDate.text =
                            '${date.day.toString().padLeft(2, '0')}-'
                            '${date.month.toString().padLeft(2, '0')}-'
                            '${date.year}';
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Must be a future date.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),

                // ── Barcode ──────────────────────────────────────────────────
                _sectionCard(
                  title: 'Barcode Scanner (optional)',
                  icon: Icons.qr_code_scanner,
                  isDarkMode: isDarkMode,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: barcodeController,
                            readOnly: true,
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 13),
                            decoration: _fieldDecoration(
                              label: 'Barcode',
                              isDarkMode: isDarkMode,
                              prefixIcon: Icons.qr_code,
                              hint: _isSearchingBarcode
                                  ? 'Searching...'
                                  : 'Scan to auto-fill',
                              suffix: barcodeController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => setState(
                                          () => barcodeController.clear()),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                _isSearchingBarcode ? null : _scanBarcode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSearchingBarcode
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.qr_code_scanner, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan a barcode to auto-fill medicine name, type, and dosage.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),

                // ── Photo ────────────────────────────────────────────────────
                BlocBuilder<ImageBloc, ImageState>(
                  builder: (context, imageState) {
                    File? selectedImage;
                    if (imageState is ImageSelected) {
                      selectedImage = imageState.image;
                    }

                    return _sectionCard(
                      title: 'Medicine Photo (optional)',
                      icon: Icons.photo_camera_outlined,
                      isDarkMode: isDarkMode,
                      children: [
                        if (selectedImage != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                Image.file(
                                  selectedImage,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.65),
                                        ],
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: _pickImage,
                                          icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Colors.white,
                                              size: 15),
                                          label: const Text(
                                            'Change',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        TextButton.icon(
                                          onPressed: () => context
                                              .read<ImageBloc>()
                                              .add(const RemoveImageEvent()),
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Color(0xFFFF6B6B),
                                              size: 15),
                                          label: const Text(
                                            'Remove',
                                            style: TextStyle(
                                                color: Color(0xFFFF6B6B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDarkMode
                                      ? const Color(0xFF3C3C3C)
                                      : AppColors.primary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                color: isDarkMode
                                    ? const Color(0xFF2C2C2C)
                                    : AppColors.primary.withValues(alpha: 0.04),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                    ),
                                    child: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: AppColors.primary,
                                        size: 30),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Add Medicine Photo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : AppColors.darkBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Camera or gallery',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Submit ───────────────────────────────────────────────────
                BlocBuilder<ImageBloc, ImageState>(
                  builder: (context, imageState) {
                    File? selectedImage;
                    if (imageState is ImageSelected) {
                      selectedImage = imageState.image;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: _isUploadingImage || _isSearchingBarcode
                            ? null
                            : () => submitMedicine(selectedImage),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey[400],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isUploadingImage
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Add Medicine',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Barcode Scanner Screen ────────────────────────────────────────────────────

class _BarcodeScannerScreen extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const _BarcodeScannerScreen({required this.onBarcodeScanned});

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) {
    if (!_isScanning) return;
    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    setState(() => _isScanning = false);
    widget.onBarcodeScanned(barcode!.rawValue!);
    Navigator.pop(context, barcode.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black54,
              child: const Text(
                'Point the camera at the medicine barcode',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
