import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meditrack/screens/auth/start_screen.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/bloc/theme_bloc/theme_bloc.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/repository/medicine_repository.dart';
import 'package:meditrack/repository/dosage_repository.dart';
import 'package:meditrack/repository/family_repository.dart';
import 'package:meditrack/services/family_dosage_notification_service.dart';
import 'bloc/image_bloc/image_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MedicineRepository>(create: (_) => MedicineRepository()),
        RepositoryProvider<DosageRepository>(create: (_) => DosageRepository()),
        RepositoryProvider<FamilyRepository>(create: (_) => FamilyRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
          BlocProvider<MedicineBloc>(create: (context) => MedicineBloc(context.read<MedicineRepository>())),
          BlocProvider<ImageBloc>(create: (context) => ImageBloc()),
          BlocProvider<DosageBloc>(
            create:
                (context) => DosageBloc(
                  dosageRepository: context.read<DosageRepository>(),
                  medicineRepository: context.read<MedicineRepository>(),
                  familyRepository: context.read<FamilyRepository>(), // ADD THIS
                  familyNotificationService: FamilyDosageNotificationService(), // ADD THIS
                ),
          ),
          BlocProvider<FamilyBloc>(create: (context) => FamilyBloc(context.read<FamilyRepository>())),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'MediTrack',
              debugShowCheckedModeBanner: false,
              theme: themeState.themeData,
              home: const StartScreen(),
            );
          },
        ),
      ),
    );
  }
}
