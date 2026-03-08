import 'package:beltech/core/config/supabase_config.dart';
import 'package:beltech/core/routing/app_router.dart';
import 'package:beltech/core/theme/app_theme.dart';
import 'package:beltech/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.publicKey,
    );
  }
  runApp(const ProviderScope(child: PersonalManagementApp()));
}

class PersonalManagementApp extends ConsumerWidget {
  const PersonalManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(currentThemeModeProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'BELTECH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
