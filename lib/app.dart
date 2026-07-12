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
import 'screens/chat_screen_desktop.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/qr_display_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/safety_words_screen.dart';
import 'screens/report_screen.dart';
import 'screens/reports_list_screen.dart';
import 'screens/stories_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/plugins_screen.dart';
import 'screens/plugin_detail_screen.dart';
import 'screens/call_screen.dart';
import 'screens/faq_screen.dart';
import 'core/theme.dart';
import 'screens/channels_screen.dart';
import 'screens/channel_detail_screen.dart';
import 'screens/access_screen.dart';

final themeNotifier = ValueNotifier<bool>(false);

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', pageBuilder: (_, state) => _buildPage(const SplashScreen(), state)),
    GoRoute(path: '/onboarding', pageBuilder: (_, state) => _buildPage(const OnboardingScreen(), state)),
    GoRoute(path: '/create-identity', pageBuilder: (_, state) => _buildPage(const CreateIdentityScreen(), state)),
    GoRoute(path: '/seed-display', pageBuilder: (_, state) => _buildPage(const SeedDisplayScreen(), state)),
    GoRoute(path: '/restore-identity', pageBuilder: (_, state) => _buildPage(const RestoreIdentityScreen(), state)),
    GoRoute(path: '/lock', pageBuilder: (_, state) => _buildPage(const LockScreen(), state)),
    GoRoute(path: '/chats', pageBuilder: (_, state) => _buildPage(const ChatsScreen(), state)),
    GoRoute(path: '/chat/:id', pageBuilder: (_, state) => _buildPage(
      ChatScreenDesktop(contactId: state.pathParameters['id'] ?? '0'), state,
    )),
    GoRoute(path: '/scan', pageBuilder: (_, state) => _buildPage(const QrScanScreen(), state)),
    GoRoute(path: '/qr-display', pageBuilder: (_, state) => _buildPage(const QrDisplayScreen(), state)),
    GoRoute(path: '/settings', pageBuilder: (_, state) => _buildPage(const SettingsScreen(), state)),
    GoRoute(path: '/profile', pageBuilder: (_, state) => _buildPage(const ProfileScreen(), state)),
    GoRoute(path: '/change-password', pageBuilder: (_, state) => _buildPage(const ChangePasswordScreen(), state)),
    GoRoute(path: '/edit-profile', pageBuilder: (_, state) => _buildPage(const EditProfileScreen(), state)),
    GoRoute(path: '/safety-words', pageBuilder: (_, state) => _buildPage(const SafetyWordsScreen(), state)),
    GoRoute(path: '/channels', pageBuilder: (_, state) => _buildPage(const ChannelsScreen(), state)),
    GoRoute(path: '/access', pageBuilder: (_, state) => _buildPage(const AccessScreen(), state)),
    GoRoute(path: '/channel/:id', pageBuilder: (_, state) => _buildPage(
      ChannelDetailScreen(channel: state.extra as Map<String, dynamic>), state,
    )),
    GoRoute(path: '/report/:id', pageBuilder: (_, state) => _buildPage(
      ReportScreen(contactId: state.pathParameters['id'] ?? '0', contactName: 'Контакт', publicKey: ''), state,
    )),
    GoRoute(path: '/reports-list', pageBuilder: (_, state) => _buildPage(const ReportsListScreen(), state)),
    GoRoute(path: '/stories', pageBuilder: (_, state) => _buildPage(const StoriesScreen(), state)),
    GoRoute(path: '/notes', pageBuilder: (_, state) => _buildPage(const NotesScreen(), state)),
    GoRoute(path: '/plugins', pageBuilder: (_, state) => _buildPage(const PluginsScreen(), state)),
    GoRoute(path: '/plugin-detail', pageBuilder: (_, state) => _buildPage(
      PluginDetailScreen(plugin: state.extra as Map<String, dynamic>), state,
    )),
    GoRoute(path: '/call/:id', pageBuilder: (_, state) {
      final extra = state.extra as Map<String, dynamic>;
      return _buildPage(CallScreen(
        contactId: state.pathParameters['id'] ?? '0',
        contactName: extra['name'] as String,
        isVideo: extra['isVideo'] as bool,
      ), state);
    }),
    GoRoute(path: '/faq', pageBuilder: (_, state) => _buildPage(const FaqScreen(), state)),
  ],
);

Page _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

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