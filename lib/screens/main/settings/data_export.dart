import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/style/colors.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _isExporting = false;
  String _savedFilePath = '';
  String _fileName = '';

  Future<Map<String, dynamic>> _getUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return userDoc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<void> _exportToPDF() async {
    setState(() {
      _isExporting = true;
      _savedFilePath = '';
      _fileName = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please log in to export data');
      }

      // Get user data
      final userData = await _getUserData();

      // Get medicines from BLoC
      final medicineState = context.read<MedicineBloc>().state;
      List<Medicine> medicines = [];
      if (medicineState is MedicineLoadedState) {
        medicines = medicineState.medicines;
      }

      // Create PDF
      final pdf = pw.Document();

      // Add cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(color: PdfColors.blue900, borderRadius: pw.BorderRadius.circular(10)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MediTrack',
                        style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Personal Medical Data Export',
                        style: const pw.TextStyle(fontSize: 16, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // User Information
                pw.Text('User Information', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 10),

                _buildPdfInfoRow('Name', userData['displayName']?.toString() ?? 'N/A'),
                _buildPdfInfoRow('Email', userData['email']?.toString() ?? 'N/A'),
                _buildPdfInfoRow('Phone', userData['phonenumber']?.toString() ?? 'N/A'),
                _buildPdfInfoRow('Allergies', userData['allergies']?.toString() ?? 'None'),
                _buildPdfInfoRow('Medical Conditions', userData['medicalConditions']?.toString() ?? 'None'),
                _buildPdfInfoRow('Emergency Contact', userData['emergencyContact']?.toString() ?? 'N/A'),

                pw.SizedBox(height: 30),

                // Export Info
                pw.Text('Export Information', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                _buildPdfInfoRow('Exported On', DateTime.now().toString().split('.')[0]),
                _buildPdfInfoRow('Total Medicines', medicines.length.toString()),
              ],
            );
          },
        ),
      );

      // Add medicines page if any exist
      if (medicines.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Medicine Inventory', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 15),

                  // Medicines table
                  pw.Table.fromTextArray(
                    headers: ['Name', 'Type', 'Category', 'Qty', 'Expires'],
                    data:
                        medicines
                            .map(
                              (med) => [
                                med.name,
                                med.type,
                                med.category,
                                med.quantity.toString(),
                                '${med.dateExpired.month}/${med.dateExpired.day}/${med.dateExpired.year}',
                              ],
                            )
                            .toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.all(8),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save to app's documents directory (no permissions needed)
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'MediTrack_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      setState(() {
        _savedFilePath = filePath;
        _fileName = fileName;
        _isExporting = false;
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text('Export Complete!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your PDF has been created successfully!'),
                const SizedBox(height: 16),
                Text('File: $_fileName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('The PDF is saved in your app storage.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
    );
  }

  Future<void> _sharePDF() async {
    if (_savedFilePath.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Success!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'PDF Created: $_fileName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your medical data has been exported and saved securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
          ),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 150, child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Export Data'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)])
                : const LinearGradient(
                    colors: [AppColors.darkBlue, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export to PDF',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Download your medical data',
                          style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Export Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportToPDF,
                icon:
                    _isExporting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                        : const Icon(Icons.download, size: 18),
                label: Text(_isExporting ? 'Generating...' : 'Generate PDF', style: const TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            if (_savedFilePath.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PDF Created Successfully',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'File: $_fileName',
                      style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location: App Documents',
                      style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sharePDF,
                        icon: const Icon(Icons.info, size: 16),
                        label: const Text('View Details', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.primary.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your data is exported to a secure PDF file for backup and compliance purposes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade300 : AppColors.darkBlue,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
