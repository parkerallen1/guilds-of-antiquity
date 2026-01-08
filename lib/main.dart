import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/hive_service.dart';
import 'ui/screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'ui/widgets/game_feedback_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return MaterialApp(
      title: 'Guilds of Antiquity',
      theme: theme,
      home: const GameFeedbackWrapper(child: HomeScreen()),
    );
  }
}
