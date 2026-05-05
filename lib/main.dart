import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/ds_theme.dart';
import 'core/constants/ds_colors.dart';
import 'core/routes/app_routes.dart';
import 'core/services/notification_service.dart';
import 'core/services/firebase_messaging_service.dart';
import 'features/auth/auth_gate.dart';
// ✅ Background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📩 إشعار في الخلفية: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Background handler — لازم قبل أي شي
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ init الإشعارات المحلية
  await NotificationService.init();

  // ✅ init FCM
  await FirebaseMessagingService.init();

  // ✅ Primary Slate status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                    Colors.transparent,
    statusBarIconBrightness:           Brightness.dark,
    systemNavigationBarColor:          DS.primary,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ✅ Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AMSDZApp());
}

class AMSDZApp extends StatelessWidget {
  const AMSDZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMS-DZ Auctions',
      debugShowCheckedModeBanner: false,
      theme:     DSTheme.light,
      darkTheme: DSTheme.light,
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const AuthGate(),
    );
  }
}