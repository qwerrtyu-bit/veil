import 'screens/create_group_screen.dart';
import 'screens/group_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/create_identity_screen.dart';
import 'screens/seed_display_screen.dart';
import 'screens/restore_identity_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/qr_display_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/safety_words_screen.dart';
import 'screens/report_screen.dart';
import 'screens/reports_list_screen.dart';
import 'core/theme.dart';

final themeNotifier = ValueNotifier<bool>(false);

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/create-identity', builder: (_, __) => const CreateIdentityScreen()),
    GoRoute(path: '/seed-display', builder: (_, __) => const SeedDisplayScreen()),
    GoRoute(path: '/restore-identity', builder: (_, __) => const RestoreIdentityScreen()),
    GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
    GoRoute(path: '/chats', builder: (_, __) => const ChatsScreen()),
    GoRoute(path: '/chat/:id', builder: (_, state) => ChatScreen(contactId: state.pathParameters['id'] ?? '0')),
    GoRoute(path: '/scan', builder: (_, __) => const QrScanScreen()),
    GoRoute(path: '/qr-display', builder: (_, __) => const QrDisplayScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
    GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/safety-words', builder: (_, __) => const SafetyWordsScreen()),
    GoRoute(
      path: '/report/:id',
      builder: (_, state) => ReportScreen(
        contactId: state.pathParameters['id'] ?? '0',
        contactName: 'Контакт',
        publicKey: '',
      ),
    ),
    GoRoute(path: '/reports-list', builder: (_, __) => const ReportsListScreen()),
        GoRoute(path: '/create-group', builder: (_, __) => const CreateGroupScreen()),
    GoRoute(path: '/group/:id', builder: (_, state) => GroupChatScreen(groupId: state.pathParameters['id'] ?? '0')),
  ],
);

class VeilApp extends StatefulWidget {
  const VeilApp({super.key});

  @override
  State<VeilApp> createState() => _VeilAppState();
}

class _VeilAppState extends State<VeilApp> {
  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    themeNotifier.value = box.get('darkTheme', defaultValue: false);
    themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
    Hive.box('settings').put('darkTheme', themeNotifier.value);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Veil',
      debugShowCheckedModeBanner: false,
      theme: veilLightTheme,
      darkTheme: veilDarkTheme,
      themeMode: themeNotifier.value ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}