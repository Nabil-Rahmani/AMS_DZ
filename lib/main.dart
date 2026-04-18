import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/ds_theme.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AMSDZApp());
}

class AMSDZApp extends StatelessWidget {
  const AMSDZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMS-DZ',
      debugShowCheckedModeBanner: false,
      theme: DSTheme.light,
      darkTheme: DSTheme.light,
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const AuthGate(),
    );
  }
}