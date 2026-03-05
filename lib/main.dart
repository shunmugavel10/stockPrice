import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/navigation/app_router.dart';
import 'core/network/api_cache_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cupertino_theme.dart';
import 'core/utils/platform_adaptive.dart';
import 'features/dashboard/presentation/providers/theme_provider.dart';
import 'features/portfolio/domain/models/stock_holding.dart';
import 'features/portfolio/presentation/providers/portfolio_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(StockHoldingAdapter());

  final portfolioBox = await Hive.openBox<StockHolding>(AppConstants.portfolioBox);
  await Hive.openBox(AppConstants.settingsBox);
  await ApiCacheService.init();

  runApp(
    ProviderScope(
      overrides: [
        portfolioBoxProvider.overrideWithValue(portfolioBox),
      ],
      child: const GreenInvestApp(),
    ),
  );
}

/// adaptive UI for iOS (Cupertino) and Android (Material)
class GreenInvestApp extends ConsumerWidget {
  const GreenInvestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    if (isCupertino) {
      final brightness = themeMode == ThemeMode.dark
          ? Brightness.dark
          : themeMode == ThemeMode.light
              ? Brightness.light
              : MediaQuery.platformBrightnessOf(context);
      final cupertinoTheme = brightness == Brightness.dark
          ? AppCupertinoTheme.dark
          : AppCupertinoTheme.light;

      return CupertinoTheme(
        data: cupertinoTheme,
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: AppRouter.router,
        ),
      );
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
