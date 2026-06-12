import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  await di.initDependencies();
  runApp(const BloodConnectApp());
}

class BloodConnectApp extends StatelessWidget {
  const BloodConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, curr) => curr is AuthUnauthenticated,
        listener: (_, __) {
          // Delay navigation until after any ongoing dialog/route animation finishes
          Future.delayed(const Duration(milliseconds: 300), () {
            AppRouter.router.go('/login');
          });
        },
        child: MaterialApp.router(
          title: 'BloodConnect',
          theme: AppTheme.light,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
