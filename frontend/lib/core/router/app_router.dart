import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/donations/presentation/pages/donations_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/maps/presentation/pages/maps_page.dart';
import '../../features/admin/presentation/pages/admin_page.dart';
import '../../l10n/app_localizations.dart';

class AppRouter {
  static GoRouter createRouter(AuthController auth) => GoRouter(
        refreshListenable: auth,
        redirect: (context, state) {
          final status = auth.status;

          // Auth pas encore déterminée → rester sur splash
          if (status == AuthStatus.initial || status == AuthStatus.loading) {
            return state.matchedLocation == '/splash' ? null : '/splash';
          }

          final isAuth = auth.isAuthenticated;
          final onLoginOrRegister = state.matchedLocation == '/login' ||
              state.matchedLocation == '/register';

          // Non authentifié → aller vers login (sauf si déjà sur login/register)
          if (!isAuth) return onLoginOrRegister ? null : '/login';

          // Authentifié sur page d'auth ou splash → aller vers home
          if (onLoginOrRegister || state.matchedLocation == '/splash') {
            return '/home';
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/splash',
            pageBuilder: (_, state) => _slide(state, const SplashPage()),
          ),
          GoRoute(
            path: '/login',
            pageBuilder: (_, state) => _slide(state, const LoginPage()),
          ),
          GoRoute(
            path: '/register',
            pageBuilder: (_, state) => _slide(state, const RegisterPage()),
          ),
          ShellRoute(
            builder: (context, state, child) =>
                ScaffoldWithNavBar(child: child),
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, state) => _fade(state, HomePage()),
              ),
              GoRoute(
                path: '/donations',
                pageBuilder: (_, state) => _fade(state, DonationsPage()),
              ),
              GoRoute(
                path: '/admin',
                pageBuilder: (_, state) => _fade(state, const AdminPage()),
              ),
              GoRoute(
                path: '/maps',
                pageBuilder: (_, state) => _fade(state, const MapsPage()),
              ),
              GoRoute(
                path: '/notifications',
                pageBuilder: (_, state) =>
                    _fade(state, const NotificationsPage()),
              ),
              GoRoute(
                path: '/profile',
                pageBuilder: (_, state) => _fade(state, const ProfilePage()),
              ),
            ],
          ),
        ],
      );

  static CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  static CustomTransitionPage<void> _slide(
          GoRouterState state, Widget child) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut)).animate(animation),
          child: child,
        ),
      );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final isAdmin = auth.user?.role == 'admin';

    final paths = [
      '/home',
      isAdmin ? '/admin' : '/donations',
      '/maps',
      '/notifications',
      '/profile',
    ];
    final location = GoRouterState.of(context).matchedLocation;
    int selectedIndex = paths.indexOf(location);
    if (selectedIndex == -1) selectedIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          if (paths[i] != location) context.go(paths[i]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.home,
          ),
          isAdmin
              ? NavigationDestination(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: const Icon(Icons.admin_panel_settings),
                  label: l10n.admin,
                )
              : NavigationDestination(
                  icon: const Icon(Icons.bloodtype_outlined),
                  selectedIcon: const Icon(Icons.bloodtype),
                  label: l10n.donations,
                ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: l10n.map,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: l10n.alerts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
