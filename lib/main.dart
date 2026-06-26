import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('contacts');
  await Hive.openBox('messages');
  await Hive.openBox('settings');
  await Hive.openBox('secure');

  runApp(
    const ProviderScope(
      child: VeilApp(),
    ),
  );
}