import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_huit_student/core/routing/app_router.dart';

void main() {
  group('AppRouter Tests', () {
    test('AppRouter deep link handling for requests', () {
      final deepLink = Uri.parse('huit-pdt://requests/123');
      print('Parsed URI - Scheme: ${deepLink.scheme}, Path: ${deepLink.path}');
      final route = AppRouterConfig.handleDeepLink(deepLink);
      print('Route result: $route');

      expect(route, '/requests/123');
    });

    test('AppRouter deep link handling for appointments', () {
      final deepLink = Uri.parse('huit-pdt://appointments/456');
      final route = AppRouterConfig.handleDeepLink(deepLink);

      expect(route, '/appointments/456');
    });

    test('AppRouter deep link returns null for unknown routes', () {
      final deepLink = Uri.parse('huit-pdt://unknown/789');
      final route = AppRouterConfig.handleDeepLink(deepLink);

      expect(route, isNull);
    });

    test('AppRouter router is not null', () {
      final router = AppRouterConfig.router();
      expect(router, isNotNull);
    });
  });
}

