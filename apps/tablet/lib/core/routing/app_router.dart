import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_session.dart';
import '../config/app_edition.dart';
import '../../features/foundation/foundation_screen.dart';
import '../../features/dispatch/presentation/dispatch_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/labels/presentation/label_preview_screen.dart';
import '../../features/products/presentation/product_preview_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/device_settings_screen.dart';
import '../../features/settings/presentation/printer_settings_screen.dart';
import '../../features/weighing/presentation/weighing_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final token = await ApiSession.token();
      final isHome = state.matchedLocation == '/';
      if ((token == null || token.isEmpty) && !isHome) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const FoundationScreen();
        },
      ),
      GoRoute(
        path: '/weighing',
        builder: (BuildContext context, GoRouterState state) {
          return const WeighingDashboardScreen();
        },
      ),
      GoRoute(
        path: '/products',
        builder: (BuildContext context, GoRouterState state) {
          return const ProductPreviewScreen();
        },
      ),
      if (!AppEdition.webManagedLabels)
        GoRoute(
          path: '/labels',
          builder: (BuildContext context, GoRouterState state) {
            return const LabelPreviewScreen();
          },
        ),
      GoRoute(
        path: '/inventory',
        builder: (BuildContext context, GoRouterState state) {
          return const InventoryScreen();
        },
      ),
      GoRoute(
        path: '/dispatch',
        builder: (BuildContext context, GoRouterState state) {
          return const DispatchScreen();
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (BuildContext context, GoRouterState state) {
          return const ReportsScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const DeviceSettingsScreen();
        },
      ),
      GoRoute(
        path: '/printer-settings',
        builder: (BuildContext context, GoRouterState state) {
          return const PrinterSettingsScreen();
        },
      ),
    ],
  );
});
