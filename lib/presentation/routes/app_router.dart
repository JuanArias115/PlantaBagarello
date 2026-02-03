import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_shell.dart';
import '../screens/overview/overview_screen.dart';
import '../screens/orders/order_checkout_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/order_form_screen.dart';
import '../screens/orders/order_packages_screen.dart';
import '../screens/orders/orders_list_screen.dart';
import '../screens/settings/package_type_form_screen.dart';
import '../screens/settings/package_types_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/orders',
    routes: [
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/overview',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const OrderFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final orderId = int.parse(state.pathParameters['id']!);
                  return OrderDetailScreen(orderId: orderId);
                },
                routes: [
                  GoRoute(
                    path: 'packages',
                    builder: (context, state) {
                      final orderId = int.parse(state.pathParameters['id']!);
                      return OrderPackagesScreen(orderId: orderId);
                    },
                  ),
                  GoRoute(
                    path: 'checkout',
                    builder: (context, state) {
                      final orderId = int.parse(state.pathParameters['id']!);
                      return OrderCheckoutScreen(orderId: orderId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const PackageTypesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PackageTypeFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return PackageTypeFormScreen(packageTypeId: id);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
