import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'providers/chat_provider.dart';
import 'services/notification_event_listener_example.dart';
import 'services/notification_service.dart';

// Background message handler (top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM message received: ${message.messageId}');
  // Note: We can't easily emit events to the main isolate from a background handler here,
  // but we can still log or handle basic tasks
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler first
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    // Only initialize notification service once
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notifications setup failed (safe to ignore on web): $e');
  }

  runApp(const FindItApp());
}

class FindItApp extends StatelessWidget {
  const FindItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: MaterialApp(
        title: 'Find It',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E5077),
            primary: const Color(0xFF2E5077),
            secondary: const Color(0xFFF2A65A),
            surface: Colors.white,
            error: const Color(0xFFE5484D),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1B3358),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5077),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E5077),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2E5077),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5484D),
                width: 1.5,
              ),
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF1F2937)),
            bodyMedium: TextStyle(color: Color(0xFF1F2937)),
            titleLarge: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        builder: (context, child) {
          return NotificationEventListener(child: child!);
        },
        home: const AuthGate(),
      ),
    );
  }
}
