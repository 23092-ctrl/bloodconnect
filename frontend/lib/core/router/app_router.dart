import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/donations/presentation/pages/donations_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/maps/presentation/pages/maps_page.dart';
import '../storage/local_storage.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = LocalStorage.isAuthenticated;
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';

      if (!isAuth && !isOnAuth) return '/login';
      if (isAuth && state.matchedLocation == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => HomePage()),
          GoRoute(path: '/donations', builder: (_, __) => DonationsPage()),
          GoRoute(path: '/maps', builder: (_, __) => const MapsPage()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  static const _paths = ['/home', '/donations', '/maps', '/notifications', '/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = switch (location) {
      '/home' => 0,
      '/donations' => 1,
      '/maps' => 2,
      '/notifications' => 3,
      '/profile' => 4,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          if (_paths[i] != location) context.go(_paths[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bloodtype_outlined), selectedIcon: Icon(Icons.bloodtype), label: 'Donations'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
