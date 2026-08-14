import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      icon: Icons.lock_outline_rounded,
      title: 'Твоя приватность под контролем',
      description:
          'Никаких номеров телефона или email. Только криптографические ключи. Твоя личность — это математика, которую никто не сможет подделать.',
      color: Color(0xFF6C5CE7),
      gradientColors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
    ),
    const OnboardingPage(
      icon: Icons.qr_code_scanner,
      title: 'Встречайся лично',
      description:
          'Добавляй контакты только через QR-код при личной встрече. Никаких удалённых добавлений. Ты всегда знаешь, с кем говоришь.',
      color: Color(0xFF10B981),
      gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    const OnboardingPage(
      icon: Icons.auto_awesome,
      title: 'Магия сквозного шифрования',
      description:
          'Сообщения превращаются в шифр прямо на твоих глазах. Только собеседник может их прочитать. Даже разработчик не имеет доступа.',
      color: Color(0xFFF59E0B),
      gradientColors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
    ),
    const OnboardingPage(
      icon: Icons.bolt,
      title: 'Мгновенная синхронизация',
      description:
          'P2P-сеть без центральных серверов. Твои сообщения доставляются напрямую через распределённую сеть. Быстро, надёжно, анонимно.',
      color: Color(0xFFEC4899),
      gradientColors: [Color(0xFFEC4899), Color(0xFFF472B6)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Кнопка пропуска
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => context.go('/create-identity'),
                  child: Text(
                    'Пропустить',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Индикатор страниц
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF6C5CE7)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Страницы
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildPage(_pages[index]),
                    );
                  },
                ),
              ),
              // Кнопки навигации
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    // Точки-индикаторы
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => GestureDetector(
                            onTap: () => _goToPage(index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? const Color(0xFF6C5CE7)
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Кнопка "Далее"
                    GestureDetector(
                      onTap: _currentPage < _pages.length - 1
                          ? () => _goToPage(_currentPage + 1)
                          : () => context.go('/create-identity'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentPage < _pages.length - 1 ? 'Далее' : 'Начать',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage < _pages.length - 1
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка с анимацией
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: 0.7 + scale * 0.3,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: page.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: page.color.withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          // Заголовок
          Text(
            page.title,
            style: const TextStyle(
              color: Color(0xFFF4F4F5),
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Описание
          Text(
            page.description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Color> gradientColors;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.gradientColors,
  });
}