import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
  } catch (_) {}

  try { await Hive.openBox('contacts'); } catch (_) {}
  try { await Hive.openBox('messages'); } catch (_) {}
  try { await Hive.openBox('settings'); } catch (_) {}
  try { await Hive.openBox('secure'); } catch (_) {}

  runApp(const ProviderScope(child: VeilApp()));
}