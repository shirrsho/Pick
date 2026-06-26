import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'services/practice_reminder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PickApp());
  // Re-render the home-screen widget so its "time since practice" stays fresh.
  PracticeReminder.refresh();
}

class PickApp extends StatelessWidget {
  const PickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A3D),
          brightness: Brightness.dark,
        ),
      ),
      home: const LandingScreen(),
    );
  }
}
