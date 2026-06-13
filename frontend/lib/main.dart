import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart' as di;
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'l10n/app_localizations.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  await CacheService.init();
  await SettingsController.init();
  await NotificationService.init();
  await di.initDependencies();
  runApp(const BloodConnectApp());
}

class BloodConnectApp extends StatefulWidget {
  const BloodConnectApp({super.key});

  @override
  State<BloodConnectApp> createState() => _BloodConnectAppState();
}

class _BloodConnectAppState extends State<BloodConnectApp> {
  late final AuthController _auth;
  late final SettingsController _settings;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = sl<AuthController>();
    _settings = sl<SettingsController>();
    _router = AppRouter.createRouter(_auth);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _settings),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp.router(
          title: 'BloodConnect',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
