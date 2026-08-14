import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/subscription_model.dart';

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionTier>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<SubscriptionTier> {
  SubscriptionNotifier() : super(SubscriptionTier.free) {
    _loadSubscription();
  }

  void _loadSubscription() {
    final box = Hive.box('settings');
    final tier = box.get('subscription_tier');
    if (tier != null) {
      state = SubscriptionTier.values.firstWhere(
        (t) => t.toString() == tier,
        orElse: () => SubscriptionTier.free,
      );
    }
  }

  void setTier(SubscriptionTier tier) {
    state = tier;
    final box = Hive.box('settings');
    box.put('subscription_tier', tier.toString());
  }
}