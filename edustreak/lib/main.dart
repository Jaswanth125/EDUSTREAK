import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:edustreak/services/auth_service.dart';
import 'package:edustreak/services/notification_service.dart';
import 'package:edustreak/services/fcm_service.dart';
import 'package:edustreak/providers/user_provider.dart';
import 'package:edustreak/screens/auth/login_screen.dart';
import 'package:edustreak/screens/portal_router.dart';
import 'package:edustreak/utils/theme.dart';
import 'package:edustreak/providers/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/services/school_service.dart';
import 'package:edustreak/services/curriculum_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safely load .env file if available
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Note: .env file not loaded (using fallback or defaults): $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence for automatic sync on mobile/desktop
  if (!kIsWeb) {
    try {
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: true);
    } catch (e) {
      // Safe to ignore
    }
  }

  // Provision default state institutions & curriculum templates if empty
  SchoolService().seedInitialSchoolsIfEmpty().catchError((e) {
    debugPrint('Note: School seeding background error: $e');
  });
  CurriculumService().seedCurriculumTemplatesIfEmpty().catchError((e) {
    debugPrint('Note: Curriculum template seeding background error: $e');
  });

  await NotificationService().init();
  
  // Initialize FCM for push notifications
  final fcmService = FCMService();
  await fcmService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'EduStreak',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final fbUser = authSnapshot.data;
        if (fbUser == null) {
          return const LoginScreen();
        }

        return Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.currentUser;
            if (user != null && user.id == fbUser.uid) {
              return _getDashboard(user.role);
            }

            return FutureBuilder<UserModel?>(
              future: userProvider.loadUser(fbUser.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting && userProvider.currentUser == null) {
                  return const Scaffold(
                    backgroundColor: AppTheme.darkBackground,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryColor),
                          SizedBox(height: 16),
                          Text(
                            'Loading EduStreak...',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final loadedUser = userProvider.currentUser ?? userSnapshot.data;
                if (loadedUser == null) {
                  return const LoginScreen();
                }

                return _getDashboard(loadedUser.role);
              },
            );
          },
        );
      },
    );
  }

  Widget _getDashboard(String role) {
    return EduStreakPortalRouter(initialRole: role);
  }
}

