import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/dosage_card.dart';
import 'package:meditrack/screens/Dosage/add_dosage.dart';

class DisplayDosage extends StatefulWidget {
  const DisplayDosage({super.key});

  @override
  State<DisplayDosage> createState() => _DisplayDosageState();
}

class _DisplayDosageState extends State<DisplayDosage> {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    //loads the medicines
    context.read<MedicineBloc>().add(LoadMedicinesEvent(userId));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: BlocBuilder<MedicineBloc, MedicineState>(
        builder: (context, medState) {
          if (medState is MedicineLoadingState) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          } else if (medState is MedicineErrorState) {
            return Center(
              child: Text(
                medState.errorMessage,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.black87,
                ),
              ),
            );
          } else if (medState is MedicineLoadedState) {
            final medicines = medState.medicines;

            if (medicines.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 80,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medicines found',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add medicines first to create dosages',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Load dosages once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              //load dosages of each medicine.
              for (var med in medicines) {
                context.read<DosageBloc>().add(LoadDosagesEvent(userId, med.id));
              }
            });

            return BlocBuilder<DosageBloc, DosageState>(
              builder: (context, dosageState) {
                if (dosageState is DosageLoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                } else if (dosageState is DosageErrorState) {
                  return Center(
                    child: Text(
                      dosageState.errorMessage,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.black87,
                      ),
                    ),
                  );
                } else if (dosageState is DosageLoadedState) {
                  final allDosages = dosageState.dosagesByMedicine;

                  // Check if there are any dosages at all
                  final hasAnyDosages = allDosages.values.any((dosages) => dosages.isNotEmpty);

                  if (!hasAnyDosages) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 80,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No dosages found',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a dosage schedule to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final totalDosages = allDosages.values
                      .fold<int>(0, (sum, list) => sum + list.length);

                  return ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: Row(
                          children: [
                            Text(
                              'My Dosages',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : AppColors.darkBlue,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$totalDosages schedule${totalDosages == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ...medicines.map((med) {
                        final medDosages = allDosages[med.id] ?? [];
                        if (medDosages.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
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
                            ...medDosages.map((d) => DosageCard(dosage: d, medId: med.id)),
                          ],
                        );
                      }),
                    ],
                  );
                }

                return const SizedBox();
              },
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dosage_fab',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDosage()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}