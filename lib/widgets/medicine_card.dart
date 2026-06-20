import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/widgets/MyTextField.dart';
import 'package:meditrack/widgets/Time.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/MyDropdownField.dart';

import '../repository/medicine_constants.dart';

class MedicineCard extends StatefulWidget {
  const MedicineCard({super.key, required this.med, required this.myTextField});
  final Medicine med;
  final MyTextField myTextField;

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final qty = widget.med.quantity;

    final Color qtyColor;
    if (qty == 0) {
      qtyColor = AppColors.error;
    } else if (qty <= 5) {
      qtyColor = AppColors.warning;
    } else {
      qtyColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => DisplayMedicineDialog(context, isDarkMode),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: FaIcon(FontAwesomeIcons.capsules, color: AppColors.primary, size: 20)),
                  ),
                  const SizedBox(width: 12),

                  // Name + type/category tags + expiry
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.med.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? Colors.white : AppColors.darkBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _tag(widget.med.type, isDarkMode),
                            const SizedBox(width: 5),
                            Flexible(child: _tag(widget.med.category, isDarkMode)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Exp ${widget.med.dateExpired.day}/${widget.med.dateExpired.month}/${widget.med.dateExpired.year}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quantity badge + actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: qtyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Quantity: $qty',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: qtyColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [EditButton(context, isDarkMode), RemoveButton(context)],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.grey[400] : AppColors.indigoGray,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  IconButton RemoveButton(BuildContext context) {
    return IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context));
  }

  Future<void> _confirmDelete(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Medicine?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1A3A6B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${widget.med.name}"?\nThis action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDarkMode ? Colors.grey[600]! : const Color(0xFFC8D1DC)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<MedicineBloc>().add(
                            RemoveMedicineEvent(widget.med.userId, widget.med.id, widget.med),
                          );
                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  IconButton EditButton(BuildContext context, bool isDarkMode) {
    return IconButton(
      icon: Icon(Icons.edit, color: isDarkMode ? AppColors.primary.withValues(alpha: 0.8) : AppColors.primary),
      onPressed: () {
        TextEditingController nameController = TextEditingController(text: widget.med.name);
        TextEditingController typeController = TextEditingController(text: widget.med.type);
        TextEditingController categoryController = TextEditingController(text: widget.med.category);
        TextEditingController quantityController = TextEditingController(text: widget.med.quantity.toString());
        TextEditingController notesController = TextEditingController(text: widget.med.notes);
        TextEditingController expiryController = TextEditingController(
          text:
              "${widget.med.dateExpired.day.toString().padLeft(2, '0')}-${widget.med.dateExpired.month.toString().padLeft(2, '0')}-${widget.med.dateExpired.year}",
        );

        EditMedicineDialog(
          context,
          nameController,
          typeController,
          categoryController,
          notesController,
          quantityController,
          expiryController,
          isDarkMode,
        );
      },
    );
  }

  Future<dynamic> DisplayMedicineDialog(BuildContext context, bool isDarkMode) {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : AppColors.white,
            title: Text('Medicine Details', style: TextStyle(color: isDarkMode ? Colors.grey[200] : Colors.black87)),
            content: SizedBox(
              width: double.maxFinite, // ADDED: Give the dialog content a max width
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display image if available (from LOCAL storage)
                    if (widget.med.imageUrl != null && widget.med.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          // FIXED: Use SizedBox instead of Container with constraints
                          height: 200,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(widget.med.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Color(0xFF1E1E1E) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Image not found',
                                          style: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    _buildDetailRow('Name', widget.med.name, isDarkMode),
                    SizedBox(height: 8),
                    _buildDetailRow('Type', widget.med.type, isDarkMode),
                    SizedBox(height: 8),
                    _buildDetailRow('Category', widget.med.category, isDarkMode),
                    SizedBox(height: 8),
                    _buildDetailRow('Quantity', widget.med.quantity.toString(), isDarkMode),
                    SizedBox(height: 8),
                    _buildDetailRow('Notes', widget.med.notes, isDarkMode),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      'Expiry Date',
                      '${widget.med.dateExpired.day}-${widget.med.dateExpired.month}-${widget.med.dateExpired.year}',
                      isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('View Alternatives'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAlternativesDialog(context, isDarkMode);
                },
              ),
              TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
    );
  }

  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700], fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value, style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.black87))),
      ],
    );
  }

  void _showAlternativesDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder:
          (_) => BlocBuilder<MedicineBloc, MedicineState>(
            builder: (context, state) {
              List<Medicine> alternatives = [];

              if (state is MedicineLoadedState) {
                // Find medicines with same category, excluding current medicine
                alternatives =
                    state.medicines
                        .where((med) => med.id != widget.med.id && med.category == widget.med.category)
                        .toList();
              }

              return AlertDialog(
                backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : AppColors.white,
                title: Row(
                  children: [
                    Icon(Icons.medical_services, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alternative Medicines',
                        style: TextStyle(color: isDarkMode ? Colors.grey[200] : Colors.black87, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Container(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Category: ${widget.med.category}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Similar medicines in your inventory:',
                        style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700], fontSize: 13),
                      ),
                      SizedBox(height: 12),
                      alternatives.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No alternatives found',
                                    style: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'No other medicines in this category',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : Container(
                            constraints: BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: alternatives.length,
                              itemBuilder: (context, index) {
                                final alt = alternatives[index];
                                return Card(
                                  color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(FontAwesomeIcons.pills, color: AppColors.teal, size: 20),
                                    title: Text(
                                      alt.name,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[200] : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${alt.type} â€¢ Qty: ${alt.quantity}',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            alt.quantity > 0
                                                ? AppColors.success.withValues(alpha: 0.2)
                                                : AppColors.error.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        alt.quantity > 0 ? 'Available' : 'Out of stock',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: alt.quantity > 0 ? AppColors.success : AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    ],
                  ),
                ),
                actions: [TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop())],
              );
            },
          ),
    );
  }

  Future<void> EditMedicineDialog(
    BuildContext parentContext,
    TextEditingController nameController,
    TextEditingController typeController,
    TextEditingController categoryController,
    TextEditingController notesController,
    TextEditingController quantityController,
    TextEditingController expiryController,
    bool isDarkMode,
  ) {
    return showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (_, setSheetState) {
              final bg = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
              final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
              final borderColor = isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5);
              final fieldBorder = isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFC8D1DC);
              final fieldFill = isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF2F4F8);

              Widget sectionCard({required String title, required IconData icon, required List<Widget> children}) =>
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: borderColor),
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

              InputDecoration fieldDeco({required String label, IconData? icon, String? hint}) {
                return InputDecoration(
                  labelText: label,
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  prefixIcon:
                      icon != null
                          ? Icon(icon, color: isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 20)
                          : null,
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                );
              }

              return Container(
                height: MediaQuery.of(sheetContext).size.height * 0.92,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // ── Drag handle ───────────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                    ),

                    // ── Header gradient ───────────────────────────────────────
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
                            child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Medicine',
                                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(widget.med.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Scrollable fields ─────────────────────────────────────
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(top: 14, bottom: 16),
                        children: [
                          // Basic Info
                          sectionCard(
                            title: 'Basic Information',
                            icon: Icons.medication_outlined,
                            children: [
                              TextFormField(
                                controller: nameController,
                                textCapitalization: TextCapitalization.words,
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                decoration: fieldDeco(label: 'Medicine Name', icon: Icons.medication),
                              ),
                              const SizedBox(height: 14),
                              MyDropdownField(
                                label: 'Medicine Type',
                                value: typeController.text,
                                items: medicineTypes,
                                onChanged: (v) => setSheetState(() => typeController.text = v!),
                              ),
                              MyDropdownField(
                                label: 'Medicine Category',
                                value: categoryController.text,
                                items: medicineCategories,
                                onChanged: (v) => setSheetState(() => categoryController.text = v!),
                              ),
                            ],
                          ),

                          // Dosage & Quantity
                          sectionCard(
                            title: 'Dosage & Quantity',
                            icon: Icons.format_list_numbered,
                            children: [
                              TextFormField(
                                controller: notesController,
                                maxLines: 2,
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                decoration: fieldDeco(
                                  label: 'Notes / Dosage',
                                  icon: Icons.notes,
                                  hint: 'e.g. 500mg, twice daily after meals',
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                decoration: fieldDeco(label: 'Quantity', icon: Icons.inventory, hint: 'e.g. 30'),
                              ),
                            ],
                          ),

                          // Expiry
                          sectionCard(
                            title: 'Expiry Date',
                            icon: Icons.calendar_today_outlined,
                            children: [
                              ExpiryDatePicker(
                                controller: expiryController,
                                labelText: 'Select Expiry Date',
                                onDateChanged: (date) {
                                  expiryController.text =
                                      '${date.day.toString().padLeft(2, '0')}-'
                                      '${date.month.toString().padLeft(2, '0')}-'
                                      '${date.year}';
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Action bar ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      decoration: BoxDecoration(
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: isDarkMode ? Colors.grey[600]! : const Color(0xFFC8D1DC)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                final updated = Medicine(
                                  id: widget.med.id,
                                  userId: widget.med.userId,
                                  name: nameController.text.trim(),
                                  type: typeController.text.trim(),
                                  category: categoryController.text.trim(),
                                  notes: notesController.text.trim(),
                                  quantity: int.tryParse(quantityController.text) ?? 0,
                                  dateAdded: widget.med.dateAdded,
                                  dateExpired:
                                      DateTime.tryParse(expiryController.text.split('-').reversed.join('-')) ??
                                      widget.med.dateExpired,
                                  imageUrl: widget.med.imageUrl,
                                );
                                parentContext.read<MedicineBloc>().add(
                                  UpdateMedicineEvent(widget.med.userId, widget.med.id, updated),
                                );
                                Navigator.of(sheetContext).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
