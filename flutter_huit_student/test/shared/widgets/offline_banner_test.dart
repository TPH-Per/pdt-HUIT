import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_huit_student/shared/cubits/connectivity_cubit.dart';
import 'package:flutter_huit_student/shared/widgets/offline_banner.dart';

void main() {
  group('OfflineBanner Widget Tests', () {
    testWidgets('OfflineBanner shows when offline',
        (WidgetTester tester) async {
      final cubit = ConnectivityCubit();
      cubit.emit(const ConnectivityOffline());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ConnectivityCubit>.value(
            value: cubit,
            child: const Scaffold(
              body: OfflineBanner(),
            ),
          ),
        ),
      );

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Không có kết nối internet'), findsOneWidget);
    });

    testWidgets('OfflineBanner hidden when online',
        (WidgetTester tester) async {
      final cubit = ConnectivityCubit();
      cubit.emit(const ConnectivityOnline());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ConnectivityCubit>.value(
            value: cubit,
            child: const Scaffold(
              body: OfflineBanner(),
            ),
          ),
        ),
      );

      expect(find.byType(OfflineBanner), findsOneWidget);
    });

    testWidgets('OfflineBanner updates when connectivity changes',
        (WidgetTester tester) async {
      final cubit = ConnectivityCubit();
      cubit.emit(const ConnectivityOnline());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ConnectivityCubit>.value(
            value: cubit,
            child: const Scaffold(
              body: OfflineBanner(),
            ),
          ),
        ),
      );

      cubit.emit(const ConnectivityOffline());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      cubit.emit(const ConnectivityOnline());
      await tester.pumpAndSettle();
    });
  });
}
