import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/role_management_screen.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/create_identity_screen.dart';
import 'screens/search_screen.dart';
import 'screens/seed_display_screen.dart';
import 'screens/restore_identity_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/chat_screen_mobile.dart';
import 'screens/username_shop_screen.dart';
import 'screens/chat_screen_desktop.dart';
import 'screens/username_shop_screen.dart';
import 'screens/chats_screen.dart';
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
import 'screens/channels_screen.dart';
import 'screens/channel_detail_screen.dart';
import 'screens/access_screen.dart';
import 'screens/doc_verify_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'screens/contact_profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/deposit_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/gift_card_request_screen.dart';
import 'screens/activate_gift_card_screen.dart';
import 'screens/gift_card_screen.dart';
import 'screens/gift_card_display_screen.dart';
import 'screens/api_keys_screen.dart';
import 'screens/admin_gift_cards_screen.dart';
import 'screens/wallpaper_screen.dart';
import 'screens/bots_screen.dart';
import 'screens/create_bot_screen.dart';

// 
// DESKTOP
//
import 'screens/desktop/main_desktop_screen.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';

final themeNotifier = ValueNotifier<bool>(false);

// ============================================================
// ФУНКЦИЯ ВЫБОРА ЭКРАНА ЧАТА
// ============================================================
Widget _buildChatScreen(String contactId) {
  if (kIsWeb) {
    return ChatScreenMobile(contactId: contactId);
  } else {
    return ChatScreenDesktop(contactId: contactId);
  }
}

Page _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      );
      
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      );
      
      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', pageBuilder: (_, state) => _buildPage(const SplashScreen(), state)),
    GoRoute(path: '/onboarding', pageBuilder: (_, state) => _buildPage(const OnboardingScreen(), state)),
    GoRoute(path: '/create-identity', pageBuilder: (_, state) => _buildPage(const CreateIdentityScreen(), state)),
    GoRoute(path: '/seed-display', pageBuilder: (_, state) => _buildPage(const SeedDisplayScreen(), state)),
    GoRoute(path: '/restore-identity', pageBuilder: (_, state) => _buildPage(const RestoreIdentityScreen(), state)),
    GoRoute(path: '/lock', pageBuilder: (_, state) => _buildPage(const LockScreen(), state)),
    GoRoute(path: '/bots', pageBuilder: (_, state) => _buildPage(const BotsScreen(), state)),
GoRoute(path: '/create-bot', pageBuilder: (_, state) => _buildPage(const CreateBotScreen(), state)),
GoRoute(path: '/username-shop', pageBuilder: (_, state) => _buildPage(const UsernameShopScreen(), state)),
    GoRoute(path: '/chats', pageBuilder: (_, state) => _buildPage(const ChatsScreen(), state)),
    GoRoute(path: '/search', pageBuilder: (_, state) => _buildPage(const SearchScreen(), state)),
    
    // ============================================================
    // DESKTOP
    // ============================================================
    GoRoute(path: '/desktop', pageBuilder: (_, state) => _buildPage(const MainDesktopScreen(), state)),
    
    // Чаты и группы
    GoRoute(
      path: '/chat/:id',
      pageBuilder: (_, state) {
        final contactId = state.pathParameters['id'] ?? '0';
        return _buildPage(_buildChatScreen(contactId), state);
      },
    ),
    GoRoute(
      path: '/group/:id',
      pageBuilder: (_, state) {
        final groupId = state.pathParameters['id'] ?? '0';
        return _buildPage(GroupChatScreen(groupId: groupId), state);
      },
    ),
    
    // Профиль и контакты
    GoRoute(
      path: '/contact-profile/:id',
      pageBuilder: (_, state) {
        final contactId = state.pathParameters['id'] ?? '0';
        final extra = state.extra as Map<String, dynamic>?;
        return _buildPage(
          ContactProfileScreen(
            contactId: contactId,
            contactName: extra?['name'] ?? 'Неизвестный',
            publicKey: extra?['key'] ?? contactId,
          ),
          state,
        );
      },
    ),
    GoRoute(path: '/profile', pageBuilder: (_, state) => _buildPage(const ProfileScreen(), state)),
    GoRoute(path: '/edit-profile', pageBuilder: (_, state) => _buildPage(const EditProfileScreen(), state)),
    GoRoute(path: '/setup-profile', pageBuilder: (_, state) => _buildPage(const SetupProfileScreen(), state)),
    
    // QR
    GoRoute(path: '/qr-display', pageBuilder: (_, state) => _buildPage(const QrDisplayScreen(), state)),
    GoRoute(path: '/scan', pageBuilder: (_, state) => _buildPage(const QrScanScreen(), state)),
    GoRoute(
  path: '/username-shop',
  pageBuilder: (_, state) => _buildPage(const UsernameShopScreen(), state),
),
    
    // Группы
    GoRoute(path: '/create-group', pageBuilder: (_, state) => _buildPage(const CreateGroupScreen(), state)),
    
    // Настройки
    GoRoute(path: '/settings', pageBuilder: (_, state) => _buildPage(const SettingsScreen(), state)),
    GoRoute(path: '/change-password', pageBuilder: (_, state) => _buildPage(const ChangePasswordScreen(), state)),
    GoRoute(path: '/safety-words', pageBuilder: (_, state) => _buildPage(const SafetyWordsScreen(), state)),
    
    // Каналы
    GoRoute(path: '/channels', pageBuilder: (_, state) => _buildPage(const ChannelsScreen(), state)),
    GoRoute(
      path: '/channel/:id',
      pageBuilder: (_, state) => _buildPage(
        ChannelDetailScreen(channel: state.extra as Map<String, dynamic>),
        state,
      ),
    ),
    
    // Плагины
    GoRoute(path: '/plugins', pageBuilder: (_, state) => _buildPage(const PluginsScreen(), state)),
    GoRoute(
      path: '/plugin-detail',
      pageBuilder: (_, state) => _buildPage(
        PluginDetailScreen(plugin: state.extra as Map<String, dynamic>),
        state,
      ),
    ),
    
    // Подписки
    GoRoute(path: '/subscription', pageBuilder: (_, state) => _buildPage(const SubscriptionScreen(), state)),
    
    // Жалобы
    GoRoute(
      path: '/report/:id',
      pageBuilder: (_, state) => _buildPage(
        ReportScreen(
          contactId: state.pathParameters['id'] ?? '0',
          contactName: 'Контакт',
          publicKey: '',
        ),
        state,
      ),
    ),
    GoRoute(path: '/reports-list', pageBuilder: (_, state) => _buildPage(const ReportsListScreen(), state)),
    
    // Другое
    GoRoute(path: '/stories', pageBuilder: (_, state) => _buildPage(const StoriesScreen(), state)),
    GoRoute(path: '/notes', pageBuilder: (_, state) => _buildPage(const NotesScreen(), state)),
    GoRoute(path: '/doc-verify', pageBuilder: (_, state) => _buildPage(const DocVerifyScreen(), state)),
    GoRoute(path: '/access', pageBuilder: (_, state) => _buildPage(const AccessScreen(), state)),
    GoRoute(path: '/roles', pageBuilder: (_, state) => _buildPage(const RoleManagementScreen(), state)),
    GoRoute(path: '/faq', pageBuilder: (_, state) => _buildPage(const FaqScreen(), state)),
    
    // Звонки
    GoRoute(
      path: '/call/:id',
      pageBuilder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _buildPage(
          CallScreen(
            contactId: state.pathParameters['id'] ?? '0',
            contactName: extra['name'] as String,
            isVideo: extra['isVideo'] as bool,
          ),
          state,
        );
      },
    ),
    
    // Кошелёк
    GoRoute(path: '/wallet', pageBuilder: (_, state) => _buildPage(const WalletScreen(), state)),
    GoRoute(path: '/wallet/deposit', pageBuilder: (_, state) => _buildPage(const DepositScreen(), state)),
    GoRoute(path: '/wallet/transfer', pageBuilder: (_, state) => _buildPage(const TransferScreen(), state)),
    GoRoute(path: '/wallet/history', pageBuilder: (_, state) => _buildPage(const TransactionHistoryScreen(), state)),
    
    // Подарочные карты
    GoRoute(path: '/gift-card', pageBuilder: (_, state) => _buildPage(const GiftCardScreen(), state)),
    GoRoute(path: '/gift-card-request', pageBuilder: (_, state) => _buildPage(const GiftCardRequestScreen(), state)),
    GoRoute(path: '/activate-gift-card', pageBuilder: (_, state) => _buildPage(const ActivateGiftCardScreen(), state)),
    GoRoute(path: '/admin/gift-cards', pageBuilder: (_, state) => _buildPage(const AdminGiftCardsScreen(), state)),
    GoRoute(
      path: '/gift-card/:code',
      pageBuilder: (_, state) {
        final code = state.pathParameters['code'] ?? '';
        return _buildPage(GiftCardDisplayScreen(cardCode: code), state);
      },
    ),
    
    // API ключи
    GoRoute(path: '/api-keys', pageBuilder: (_, state) => _buildPage(const ApiKeysScreen(), state)),
    
    // Обои
    GoRoute(
      path: '/wallpaper/:chatId',
      pageBuilder: (_, state) {
        final chatId = state.pathParameters['chatId'] ?? '0';
        final extra = state.extra as Map<String, dynamic>?;
        return _buildPage(
          WallpaperScreen(
            chatId: chatId,
            chatName: extra?['name'] ?? 'Чат',
          ),
          state,
        );
      },
    ),
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
    return Consumer(
      builder: (context, ref, child) {
        final locale = ref.watch(localeProvider);
        return ValueListenableBuilder<bool>(
          valueListenable: themeNotifier,
          builder: (context, isDark, child) {
            return MaterialApp.router(
              title: 'Veil',
              debugShowCheckedModeBanner: false,
              theme: isDark ? veilDarkTheme : veilLightTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              routerConfig: router,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ru'),
                Locale('en'),
              ],
            );
          },
        );
      },
    );
  }
}