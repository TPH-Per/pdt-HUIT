import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_page.dart';

class AppRouterConfig {
  static GoRouter router() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home Page')),
          ),
        ),
        GoRoute(
          path: '/requests',
          name: 'requests',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Requests Page')),
          ),
        ),
        GoRoute(
          path: '/requests/:id',
          name: 'request-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return Scaffold(
              body: Center(
                child: Text('Request: $id'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/appointments',
          name: 'appointments',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Appointments Page')),
          ),
        ),
        GoRoute(
          path: '/appointments/:id',
          name: 'appointment-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return Scaffold(
              body: Center(
                child: Text('Appointment: $id'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Profile Page')),
          ),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Notifications Page')),
          ),
        ),
      ],
    );
  }

  static String? handleDeepLink(Uri deepLink) {
    if (deepLink.scheme == 'huit-pdt') {
      // For unknown schemes, the authority is the first path segment
      // huit-pdt://requests/123 becomes path=/123, host=requests
      final host = deepLink.host;
      final path = deepLink.path;

      if (host == 'requests' && path.isNotEmpty) {
        return '/requests$path';
      } else if (host == 'appointments' && path.isNotEmpty) {
        return '/appointments$path';
      }
    }
    return null;
  }
}
