import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/model/family_member.dart';
import 'package:meditrack/repository/medicine_constants.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/widgets/Time.dart';

class DosageCard extends StatelessWidget {
  final Dosage dosage;
  final String medId;

  const DosageCard({super.key, required this.dosage, required this.medId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shadowColor: isDarkMode ? Colors.black45 : AppColors.lightGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medication,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dosage.dosage,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey[200] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dosage.frequency,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 20,
                      color: isDarkMode
                          ? AppColors.primary.withValues(alpha: 0.8)
                          : AppColors.primary),
                  tooltip: 'Edit dosage',
                  onPressed: () => _showEditDosageSheet(context, isDarkMode),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[400],
                  onPressed: () => _showDeleteDialog(context, isDarkMode),
                  tooltip: 'Delete dosage',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date range
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14,
                    color:
                        isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${dosage.startDate.toString().split(' ').first} – '
                  '${dosage.endDate?.toString().split(' ').first ?? 'Ongoing'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Times chips
            if (dosage.times.isNotEmpty) ...[
              Text(
                'Times',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[400] : AppColors.indigoGray,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: dosage.times.asMap().entries.map((entry) {
                  final index = entry.key;
                  final t = entry.value;
                  final time = t['time'] ?? '';
                  final taken = t['taken'] ?? false;
                  return _buildTimeChip(context, time, taken, index, isDarkMode);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context, String time, bool taken,
      int index, bool isDarkMode) {
    return InkWell(
      onTap: taken ? null : () => _markAsTaken(context, index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: taken
              ? (isDarkMode
                  ? Colors.green[900]?.withValues(alpha: 0.3)
                  : Colors.green[50])
              : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: taken
                ? (isDarkMode ? Colors.green[700]! : Colors.green[300]!)
                : (isDarkMode
                    ? const Color(0xFF3C3C3C)
                    : const Color(0xFFDDE3EE)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              taken ? Icons.check_circle : Icons.schedule,
              size: 14,
              color: taken
                  ? (isDarkMode ? Colors.green[400] : Colors.green[700])
                  : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: taken ? FontWeight.w600 : FontWeight.normal,
                color: taken
                    ? (isDarkMode ? Colors.green[300] : Colors.green[800])
                    : (isDarkMode ? Colors.grey[300] : Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAsTaken(BuildContext context, int timeIndex) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    context.read<DosageBloc>().add(
          MarkDosageTimeTakenEvent(userId, medId, dosage.id, timeIndex, dosage.dosage),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as taken'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ── Edit Sheet ──────────────────────────────────────────────────────────────

  void _showEditDosageSheet(BuildContext parentContext, bool isDarkMode) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Initialise controllers with current values
    final dosageCtrl = TextEditingController(text: dosage.dosage);
    String? selectedFrequency = dosageFrequencies
        .where((f) => f.label == dosage.frequency)
        .map((f) => f.label)
        .firstOrNull;
    final startCtrl = TextEditingController(
      text:
          '${dosage.startDate.year}-${dosage.startDate.month.toString().padLeft(2, '0')}-${dosage.startDate.day.toString().padLeft(2, '0')}',
    );
    final endCtrl = TextEditingController(
      text: dosage.endDate != null
          ? '${dosage.endDate!.year}-${dosage.endDate!.month.toString().padLeft(2, '0')}-${dosage.endDate!.day.toString().padLeft(2, '0')}'
          : '',
    );

    bool hasEndDate = dosage.endDate != null;
    List<String> editTimes =
        dosage.times.map((t) => t['time'] as String).toList();
    bool notifyFamily = dosage.notifyFamilyMembers;
    List<String> selectedMemberIds =
        List<String>.from(dosage.selectedFamilyMemberIds);
    List<FamilyMember> familyMembers = [];

    final bg =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5);
    final fieldBorder =
        isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFC8D1DC);
    final fieldFill =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF2F4F8);

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) {
          // ── helpers ──────────────────────────────────────────────────────
          Widget sectionCard({
            required String title,
            required IconData icon,
            required List<Widget> children,
          }) =>
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor,
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
                  border: Border.all(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(icon, color: AppColors.primary, size: 17),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : AppColors.darkBlue,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      ...children,
                    ],
                  ),
                ),
              );

          InputDecoration fieldDeco({
            required String label,
            IconData? icon,
            String? hint,
          }) =>
              InputDecoration(
                labelText: label,
                hintText: hint,
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                labelStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                prefixIcon: icon != null
                    ? Icon(icon,
                        color:
                            isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20)
                    : null,
                filled: true,
                fillColor: fieldFill,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              );

          Future<void> addTime() async {
            final localizations = MaterialLocalizations.of(sheetContext);
            final picked = await showTimePicker(
              context: sheetContext,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              final formatted = localizations.formatTimeOfDay(picked);
              if (!editTimes.contains(formatted)) {
                setSheetState(() => editTimes.add(formatted));
              }
            }
          }

          void showMemberSelector() {
            final visible = familyMembers
                .where((m) => m.userId != userId)
                .toList();

            showModalBottomSheet(
              context: sheetContext,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (ctx) => StatefulBuilder(
                builder: (_, setMemberState) => Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF3C3C3C)
                              : const Color(0xFFDDE1E9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.family_restroom,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notify Family Members',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : AppColors.darkBlue,
                                    ),
                                  ),
                                  Text(
                                    '${selectedMemberIds.length} of ${visible.length} selected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFEEF0F5),
                      ),
                      if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 40,
                                  color: isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No other family members',
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 72,
                            color: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFEEF0F5),
                          ),
                          itemBuilder: (_, i) {
                            final member = visible[i];
                            final isSelected =
                                selectedMemberIds.contains(member.id);
                            final initials =
                                member.displayName.isNotEmpty
                                    ? member.displayName[0].toUpperCase()
                                    : 'F';
                            return InkWell(
                              onTap: () {
                                setMemberState(() {
                                  if (isSelected) {
                                    selectedMemberIds.remove(member.id);
                                  } else {
                                    selectedMemberIds.add(member.id);
                                  }
                                });
                                setSheetState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.primary
                                                .withValues(alpha: 0.1),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.displayName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : AppColors.darkBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            member.email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDarkMode
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDarkMode
                                                  ? const Color(0xFF3C3C3C)
                                                  : const Color(0xFFC8D1DC)),
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 14)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            selectedMemberIds.isEmpty
                                ? 'Done'
                                : 'Confirm ${selectedMemberIds.length} member${selectedMemberIds.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ── Sheet body ──────────────────────────────────────────────────
          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.92,
            decoration: BoxDecoration(
              color: bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Gradient header
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
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
                        child: const Icon(Icons.edit_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Dosage',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dosage.dosage,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable fields
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 14, bottom: 16),
                    children: [
                      // Dosage Details
                      sectionCard(
                        title: 'Dosage Details',
                        icon: Icons.format_list_numbered,
                        children: [
                          TextField(
                            controller: dosageCtrl,
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black),
                            decoration: fieldDeco(
                              label: 'Dosage',
                              icon: Icons.scale_outlined,
                              hint: 'e.g. 500mg, 2 tablets',
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: selectedFrequency,
                            dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black),
                            items: dosageFrequencies
                                .map((f) => DropdownMenuItem(
                                      value: f.label,
                                      child: Text(f.label,
                                          style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              final freq = dosageFrequencies
                                  .firstWhere((f) => f.label == val);
                              setSheetState(() {
                                selectedFrequency = val;
                                editTimes = List<String>.from(freq.defaultTimes);
                              });
                            },
                            decoration: fieldDeco(
                              label: 'Frequency',
                              icon: Icons.repeat,
                              hint: 'Select how often to take it',
                            ),
                            icon: Icon(Icons.arrow_drop_down,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ],
                      ),

                      // Schedule
                      sectionCard(
                        title: 'Schedule',
                        icon: Icons.calendar_today_outlined,
                        children: [
                          ExpiryDatePicker(
                            controller: startCtrl,
                            labelText: 'Start Date',
                            initialDate: DateTime.now(),
                            onDateChanged: (date) {
                              startCtrl.text =
                                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            },
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: fieldFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: fieldBorder),
                            ),
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 2),
                              value: hasEndDate,
                              onChanged: (val) => setSheetState(() {
                                hasEndDate = val;
                                if (!val) endCtrl.clear();
                              }),
                              activeThumbColor: AppColors.primary,
                              title: Text(
                                'Has End Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[200]
                                      : Colors.black87,
                                ),
                              ),
                              secondary: Icon(
                                Icons.event_available_outlined,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ),
                          if (hasEndDate) ...[
                            const SizedBox(height: 14),
                            ExpiryDatePicker(
                              controller: endCtrl,
                              labelText: 'End Date',
                              onDateChanged: (date) {
                                endCtrl.text =
                                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              },
                            ),
                          ],
                        ],
                      ),

                      // Reminder Times
                      sectionCard(
                        title: 'Reminder Times',
                        icon: Icons.access_time_outlined,
                        children: [
                          if (editTimes.isEmpty)
                            Text(
                              'No times added. Add at least one.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: editTimes.map((time) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.primary, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.schedule,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => setSheetState(
                                            () => editTimes.remove(time)),
                                        child: const Icon(Icons.close,
                                            size: 14,
                                            color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: addTime,
                              icon: const Icon(Icons.add_alarm_outlined,
                                  size: 18),
                              label: const Text('Add Reminder Time'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Family Notifications
                      BlocBuilder<FamilyBloc, FamilyState>(
                        builder: (context, familyState) {
                          if (familyState is! FamilyAccountLoadedState) {
                            return const SizedBox.shrink();
                          }
                          familyMembers = familyState.members;
                          return sectionCard(
                            title: 'Family Notifications',
                            icon: Icons.family_restroom_outlined,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: fieldFill,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: fieldBorder),
                                ),
                                child: SwitchListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 2),
                                  value: notifyFamily,
                                  onChanged: (val) => setSheetState(() {
                                    notifyFamily = val;
                                    if (!val) selectedMemberIds.clear();
                                  }),
                                  activeThumbColor: AppColors.primary,
                                  title: Text(
                                    'Notify Family Members',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[200]
                                          : Colors.black87,
                                    ),
                                  ),
                                  secondary: Icon(
                                    Icons.notifications_active_outlined,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                              ),
                              if (notifyFamily) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Selected members will be notified at each reminder time.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: showMemberSelector,
                                    icon: const Icon(Icons.people_outline,
                                        size: 18),
                                    label: Text(
                                      selectedMemberIds.isEmpty
                                          ? 'Select Family Members'
                                          : '${selectedMemberIds.length} member(s) selected',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                          color: AppColors.primary),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Action bar
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: isDarkMode
                                    ? Colors.grey[600]!
                                    : const Color(0xFFC8D1DC)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
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
                            final isPRN = selectedFrequency == 'As Needed (PRN)';
                            if (dosageCtrl.text.trim().isEmpty ||
                                selectedFrequency == null ||
                                startCtrl.text.isEmpty ||
                                (!isPRN && editTimes.isEmpty)) {
                              ScaffoldMessenger.of(parentContext)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'Please fill all required fields'),
                                backgroundColor: Colors.red,
                              ));
                              return;
                            }

                            final updatedData = {
                              'dosage': dosageCtrl.text.trim(),
                              'frequency': selectedFrequency ?? '',
                              'times': editTimes
                                  .map((t) => {
                                        'time': t,
                                        'taken': false,
                                        'takenDate': null,
                                      })
                                  .toList(),
                              'startDate': Timestamp.fromDate(
                                  DateTime.parse(startCtrl.text)),
                              'endDate': hasEndDate &&
                                      endCtrl.text.isNotEmpty
                                  ? Timestamp.fromDate(
                                      DateTime.parse(endCtrl.text))
                                  : null,
                              'notifyFamilyMembers': notifyFamily,
                              'selectedFamilyMemberIds': selectedMemberIds,
                            };

                            parentContext.read<DosageBloc>().add(
                                  UpdateDosageEvent(
                                      userId, medId, dosage.id, updatedData),
                                );

                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(parentContext)
                                .showSnackBar(const SnackBar(
                              content: Text('Dosage updated successfully'),
                              backgroundColor: Colors.green,
                            ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

  // ── Delete Dialog ───────────────────────────────────────────────────────────

  void _showDeleteDialog(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Dosage?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF1A3A6B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete this dosage schedule?\nThis action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[600]!
                              : const Color(0xFFC8D1DC)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final uid =
                          FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        context.read<DosageBloc>().add(
                              DeleteDosageEvent(uid, medId, dosage.id),
                            );
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
}
