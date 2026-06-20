import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/family_members_widget.dart';
import '../../../widgets/nerby_pharmacies_widget.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with AutomaticKeepAliveClientMixin, RouteAware {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (user != null) {
      context.read<FamilyBloc>().add(LoadFamilyAccountEvent(user!.uid));
    }
  }

  // Reload medicines (and therefore dosages) every time the tab becomes visible.
  @override
  void didPopNext() {
    _loadData();
  }

  void _loadData() {
    if (user != null) {
      context.read<MedicineBloc>().add(LoadMedicinesEvent(user!.uid));
      context.read<FamilyBloc>().add(LoadFamilyAccountEvent(user!.uid));
    }
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero greeting card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF007FA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getGreeting(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formattedDate(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Section 1: Today's Schedule
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medication, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Dosage Cards
            BlocBuilder<MedicineBloc, MedicineState>(
              builder: (context, medState) {
                if (medState is MedicineLoadingState) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (medState is MedicineErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        medState.errorMessage,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }

                if (medState is MedicineLoadedState) {
                  final medicines = medState.medicines;

                  if (medicines.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No medicines found',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    for (var med in medicines) {
                      context.read<DosageBloc>().add(LoadDosagesEvent(user!.uid, med.id));
                    }
                  });

                  return BlocBuilder<DosageBloc, DosageState>(
                    builder: (context, dosageState) {
                      if (dosageState is DosageLoadingState) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }

                      if (dosageState is DosageErrorState) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              dosageState.errorMessage,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey.shade400 : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }

                      if (dosageState is DosageLoadedState) {
                        final allByMed = dosageState.dosagesByMedicine;
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final dosageWidgets = <Widget>[];

                        for (var med in medicines) {
                          final medDosages = allByMed[med.id] ?? [];
                          final todayDosages = medDosages.where((d) {
                            final start = DateTime(d.startDate.year, d.startDate.month, d.startDate.day);
                            final end = d.endDate != null
                                ? DateTime(d.endDate!.year, d.endDate!.month, d.endDate!.day)
                                : null;
                            return !start.isAfter(today) && (end == null || !end.isBefore(today));
                          }).toList();

                          if (todayDosages.isEmpty) continue;

                          dosageWidgets.add(
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    med.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode ? Colors.white : AppColors.darkBlue,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          for (var dosage in todayDosages) {
                            dosageWidgets.add(_buildDosageCard(med.id, dosage, isDarkMode));
                          }
                        }

                        if (dosageWidgets.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 48,
                                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No dosages scheduled for today',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: dosageWidgets,
                        );
                      }

                      return const SizedBox();
                    },
                  );
                }

                return const SizedBox();
              },
            ),

            const SizedBox(height: 30),

            // Section 2: EXPIRED MEDICINES
            BlocBuilder<MedicineBloc, MedicineState>(
              builder: (context, medState) {
                if (medState is MedicineLoadedState) {
                  final now = DateTime.now();
                  final expiredMedicines = medState.medicines
                      .where((med) => med.dateExpired.isBefore(now))
                      .toList();

                  if (expiredMedicines.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Expired Medicines:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withValues(alpha: 0.1),
                                Colors.orange.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${expiredMedicines.length}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      expiredMedicines.length == 1
                                          ? '1 medicine has expired'
                                          : '${expiredMedicines.length} medicines have expired',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...expiredMedicines.map<Widget>((med) {
                                final daysExpired = now.difference(med.dateExpired).inDays;
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.medication,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              med.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Expired $daysExpired day${daysExpired == 1 ? '' : 's'} ago',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),

            // Section 3: Family Members
            const FamilyMembersWidget(),

            const SizedBox(height: 30),

            // Section 4: Nearby Pharmacies
            const NearbyPharmaciesWidget(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageCard(String medId, Dosage dosage, bool isDarkMode) {
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
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
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dosage header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medication, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dosage.dosage,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDarkMode ? Colors.white : AppColors.darkBlue,
                        ),
                      ),
                      Text(
                        dosage.frequency,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : AppColors.indigoGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List<Widget>.generate(dosage.times.length, (index) {
              final timeData = dosage.times[index];
              final time = timeData['time'];

              DateTime? takenDate;
              final raw = timeData['takenDate'];
              if (raw != null) {
                takenDate = raw is DateTime ? raw : (raw as Timestamp).toDate();
              }

              final isTakenToday = takenDate != null &&
                  takenDate.year == today.year &&
                  takenDate.month == today.month &&
                  takenDate.day == today.day;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isTakenToday
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTakenToday
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : (isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFDDE3EE)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isTakenToday ? Icons.check_circle : Icons.access_time,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.grey.shade200 : AppColors.darkBlue,
                        ),
                      ),
                    ),
                    if (isTakenToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Taken',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () => _markAsTaken(medId, dosage, index),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Take',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _markAsTaken(String medId, Dosage dosage, int timeIndex) async {
    try {
      // Get the medicine to check current quantity
      final medState = context.read<MedicineBloc>().state;
      if (medState is! MedicineLoadedState) return;

      final medicine = medState.medicines.firstWhere((m) => m.id == medId);

      // Check if medicine is in stock
      if (medicine.quantity <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${medicine.name} is out of stock!'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Mark the dosage as taken in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('medicines')
          .doc(medId)
          .collection('dosages')
          .doc(dosage.id)
          .update({
        'times': dosage.times.asMap().entries.map((entry) {
          if (entry.key == timeIndex) {
            return {
              'time': entry.value['time'],
              'takenDate': Timestamp.now(),
            };
          }
          return entry.value;
        }).toList(),
      });

      // Reduce medicine quantity by 1
      final newQuantity = medicine.quantity - 1;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('medicines')
          .doc(medId)
          .update({'quantity': newQuantity});

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicine.name} marked as taken! Quantity: $newQuantity'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reload data to reflect changes
        context.read<MedicineBloc>().add(LoadMedicinesEvent(user!.uid));
        context.read<DosageBloc>().add(LoadDosagesEvent(user!.uid, medId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}