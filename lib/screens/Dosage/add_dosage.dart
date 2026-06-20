import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/model/medicine.dart';
import 'package:meditrack/model/family_member.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/repository/medicine_constants.dart';
import 'package:meditrack/widgets/Time.dart';
import 'package:meditrack/widgets/app_bar.dart';

class AddDosage extends StatefulWidget {
  const AddDosage({super.key});

  @override
  State<AddDosage> createState() => _AddDosageState();
}

class _AddDosageState extends State<AddDosage> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController medDosage = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final User? userCredential = FirebaseAuth.instance.currentUser;

  bool hasEndDate = false;
  Medicine? selectedMedicine;
  String? selectedFrequency;
  List<String> selectedTimes = [];

  bool notifyFamily = false;
  List<String> selectedFamilyMemberIds = [];
  List<FamilyMember> availableFamilyMembers = [];

  @override
  void initState() {
    super.initState();
    if (userCredential != null) {
      context.read<FamilyBloc>().add(LoadFamilyAccountEvent(userCredential!.uid));
    }
  }

  void submitDosage() {
    final isPRN = selectedFrequency == 'As Needed (PRN)';
    if (!formKey.currentState!.validate() ||
        selectedMedicine == null ||
        (!isPRN && selectedTimes.isEmpty) ||
        startDateController.text.isEmpty ||
        (hasEndDate && endDateController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and add at least one time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dosageData = {
      'dosage': medDosage.text.trim(),
      'frequency': selectedFrequency ?? '',
      'times': selectedTimes
          .map((t) => {'time': t, 'taken': false, 'takenDate': null})
          .toList(),
      'startDate': Timestamp.fromDate(DateTime.parse(startDateController.text)),
      'endDate': hasEndDate
          ? Timestamp.fromDate(DateTime.parse(endDateController.text))
          : null,
      'addedAt': Timestamp.fromDate(DateTime.now()),
      'medicineId': selectedMedicine!.id,
      'notifyFamilyMembers': notifyFamily,
      'selectedFamilyMemberIds': selectedFamilyMemberIds,
    };

    context.read<DosageBloc>().add(
      AddDosageEvent(
        userCredential?.uid ?? '',
        selectedMedicine!.id,
        dosageData,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notifyFamily && selectedFamilyMemberIds.isNotEmpty
              ? 'Dosage added! Family members will be notified'
              : 'Dosage added successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _addTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final formattedTime = pickedTime.format(context);
      if (!selectedTimes.contains(formattedTime)) {
        setState(() => selectedTimes.add(formattedTime));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This time is already added'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showFamilyMemberSelector(BuildContext context, bool isDarkMode) {
    final visibleMembers = availableFamilyMembers
        .where((m) => m.userId != userCredential?.uid)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
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

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
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
                                '${selectedFamilyMemberIds.length} of ${visibleMembers.length} selected',
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

                  // Member list
                  if (visibleMembers.isEmpty)
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
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleMembers.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 72,
                        color: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFEEF0F5),
                      ),
                      itemBuilder: (_, i) {
                        final member = visibleMembers[i];
                        final isSelected =
                            selectedFamilyMemberIds.contains(member.id);
                        final initials = member.displayName.isNotEmpty
                            ? member.displayName[0].toUpperCase()
                            : 'F';

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedFamilyMemberIds.remove(member.id);
                              } else {
                                selectedFamilyMemberIds.add(member.id);
                              }
                            });
                            setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                // Avatar
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
                                // Name & email
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
                                // Checkmark
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
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

                  // Done button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        selectedFamilyMemberIds.isEmpty
                            ? 'Done'
                            : 'Confirm ${selectedFamilyMemberIds.length} member${selectedFamilyMemberIds.length == 1 ? '' : 's'}',
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
            );
          },
        );
      },
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────────────

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
      appBar: MyAppBar.build(context, () {}),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
                        child: const Icon(FontAwesomeIcons.clockRotateLeft,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Dosage Schedule',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Set up your medication reminder',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Medicine Selection ────────────────────────────────────────
                _sectionCard(
                  title: 'Medicine',
                  icon: Icons.medication_outlined,
                  isDarkMode: isDarkMode,
                  children: [
                    BlocBuilder<MedicineBloc, MedicineState>(
                      builder: (context, state) {
                        if (state is MedicineLoadingState) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        if (state is MedicineLoadedState) {
                          return DropdownButtonFormField<Medicine>(
                            initialValue: selectedMedicine,
                            dropdownColor: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : Colors.white,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            items: state.medicines
                                .map(
                                  (med) => DropdownMenuItem(
                                    value: med,
                                    child: Text(
                                      med.name,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() => selectedMedicine = val);
                              if (val != null) {
                                context.read<DosageBloc>().add(
                                  LoadDosagesEvent(
                                    userCredential?.uid ?? '',
                                    val.id,
                                  ),
                                );
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Please select a medicine' : null,
                            decoration: _fieldDecoration(
                              label: 'Select Medicine',
                              isDarkMode: isDarkMode,
                              prefixIcon: Icons.medication,
                              hint: 'Choose from your medicines',
                            ).copyWith(
                              suffixIcon: Icon(
                                Icons.arrow_drop_down,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            icon: const SizedBox.shrink(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),

                // ── Dosage Details ────────────────────────────────────────────
                _sectionCard(
                  title: 'Dosage Details',
                  icon: Icons.format_list_numbered,
                  isDarkMode: isDarkMode,
                  children: [
                    TextFormField(
                      controller: medDosage,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Dosage is required' : null,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                      decoration: _fieldDecoration(
                        label: 'Dosage',
                        isDarkMode: isDarkMode,
                        prefixIcon: Icons.scale_outlined,
                        hint: 'e.g. 500mg, 2 tablets',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFrequency,
                      dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      items: dosageFrequencies
                          .map((f) => DropdownMenuItem(
                                value: f.label,
                                child: Text(f.label,
                                    style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final freq = dosageFrequencies.firstWhere((f) => f.label == val);
                        setState(() {
                          selectedFrequency = val;
                          selectedTimes = List<String>.from(freq.defaultTimes);
                        });
                      },
                      validator: (v) => v == null ? 'Please select a frequency' : null,
                      decoration: _fieldDecoration(
                        label: 'Frequency',
                        isDarkMode: isDarkMode,
                        prefixIcon: Icons.repeat,
                        hint: 'Select how often to take it',
                      ).copyWith(suffixIcon: const SizedBox.shrink()),
                      icon: Icon(Icons.arrow_drop_down,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),

                // ── Schedule ──────────────────────────────────────────────────
                _sectionCard(
                  title: 'Schedule',
                  icon: Icons.calendar_today_outlined,
                  isDarkMode: isDarkMode,
                  children: [
                    ExpiryDatePicker(
                      controller: startDateController,
                      labelText: 'Start Date',
                      initialDate: DateTime.now(),
                      onDateChanged: (date) {
                        startDateController.text =
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      },
                    ),
                    const SizedBox(height: 14),

                    // End Date Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2C2C2C)
                            : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF3C3C3C)
                              : const Color(0xFFC8D1DC),
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        value: hasEndDate,
                        onChanged: (val) => setState(() {
                          hasEndDate = val;
                          if (!val) endDateController.clear();
                        }),
                        activeThumbColor: AppColors.primary,
                        title: Text(
                          'Has End Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[200] : Colors.black87,
                          ),
                        ),
                        secondary: Icon(
                          Icons.event_available_outlined,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),

                    if (hasEndDate) ...[
                      const SizedBox(height: 14),
                      ExpiryDatePicker(
                        controller: endDateController,
                        labelText: 'End Date',
                        onDateChanged: (date) {
                          endDateController.text =
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        },
                      ),
                    ],
                  ],
                ),

                // ── Reminder Times ────────────────────────────────────────────
                _sectionCard(
                  title: 'Reminder Times',
                  icon: Icons.access_time_outlined,
                  isDarkMode: isDarkMode,
                  children: [
                    if (selectedTimes.isEmpty)
                      Text(
                        'No times added yet. Add at least one reminder time.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedTimes.map((time) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
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
                                  onTap: () =>
                                      setState(() => selectedTimes.remove(time)),
                                  child: const Icon(Icons.close,
                                      size: 14, color: AppColors.primary),
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
                        onPressed: () => _addTime(context),
                        icon: const Icon(Icons.add_alarm_outlined, size: 18),
                        label: const Text('Add Reminder Time'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Family Notifications ──────────────────────────────────────
                BlocBuilder<FamilyBloc, FamilyState>(
                  builder: (context, familyState) {
                    if (familyState is! FamilyAccountLoadedState) {
                      return const SizedBox.shrink();
                    }
                    availableFamilyMembers = familyState.members;

                    return _sectionCard(
                      title: 'Family Notifications',
                      icon: Icons.family_restroom_outlined,
                      isDarkMode: isDarkMode,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF2C2C2C)
                                : AppColors.lightGray,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF3C3C3C)
                                  : const Color(0xFFC8D1DC),
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 2),
                            value: notifyFamily,
                            onChanged: (value) {
                              setState(() => notifyFamily = value);
                              if (!value) selectedFamilyMemberIds.clear();
                            },
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
                            'Selected members will be notified when it\'s time to take this medication.',
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
                              onPressed: () =>
                                  _showFamilyMemberSelector(context, isDarkMode),
                              icon: const Icon(Icons.people_outline, size: 18),
                              label: Text(
                                selectedFamilyMemberIds.isEmpty
                                    ? 'Select Family Members'
                                    : '${selectedFamilyMemberIds.length} member(s) selected',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Submit ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: submitDosage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Add Dosage Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    medDosage.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }
}
