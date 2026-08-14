enum SubscriptionTier {
  free,
  plus,
  dev,
  pro,
}

class SubscriptionPlan {
  final SubscriptionTier tier;
  final String nameKey;
  final String descriptionKey;
  final int price;
  final List<String> features;
  final int maxReactionsPerMessage;
  final bool hasApiAccess;
  final bool canCreatePlugins;

  const SubscriptionPlan({
    required this.tier,
    required this.nameKey,
    required this.descriptionKey,
    required this.price,
    required this.features,
    required this.maxReactionsPerMessage,
    this.hasApiAccess = false,
    this.canCreatePlugins = false,
  });

  bool get isFree => tier == SubscriptionTier.free;

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      tier: SubscriptionTier.free,
      nameKey: 'free',
      descriptionKey: 'freeDesc',
      price: 0,
      maxReactionsPerMessage: 1,
      features: [
        'Безлимитные личные чаты',
        'Группы без ограничений',
        'Бесплатные плагины',
        'Аудиозвонки',
        'Видеозвонки',
        'HD видео',
        'Приватные каналы',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.plus,
      nameKey: 'plus',
      descriptionKey: 'plusDesc',
      price: 199,
      maxReactionsPerMessage: 3,
      features: [
        'Всё из Free',
        'Все плагины',
        'Экспорт чатов',
        'Приоритетная поддержка',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.dev,
      nameKey: 'dev',
      descriptionKey: 'devDesc',
      price: 399,
      maxReactionsPerMessage: 5,
      hasApiAccess: true,
      canCreatePlugins: true,
      features: [
        'Всё из Plus',
        '🔑 Доступ к API',
        '📦 Создание плагинов',
        '🤖 Создание ботов',
        '📚 Документация API',
        '🔗 Webhooks',
        '💬 Приоритетная поддержка',
        '🚀 Расширенные лимиты',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.pro,
      nameKey: 'pro',
      descriptionKey: 'proDesc',
      price: 999,
      maxReactionsPerMessage: 10,
      hasApiAccess: true,
      canCreatePlugins: true,
      features: [
        'Всё из Dev',
        '⭐ Эксклюзивные плагины',
        '👤 Персональный менеджер',
        '🏢 Корпоративные возможности',
      ],
    ),
  ];

  static SubscriptionPlan getPlan(SubscriptionTier tier) {
    return plans.firstWhere((p) => p.tier == tier);
  }
}