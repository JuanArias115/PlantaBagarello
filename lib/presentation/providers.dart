import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/database_service.dart';
import '../data/models/coffee_order.dart';
import '../data/repositories/coffee_order_repository.dart';
import '../data/repositories/order_package_repository.dart';
import '../data/repositories/package_type_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final coffeeOrderRepositoryProvider = Provider<CoffeeOrderRepository>((ref) {
  return CoffeeOrderRepository(ref.watch(databaseServiceProvider));
});

final packageTypeRepositoryProvider = Provider<PackageTypeRepository>((ref) {
  return PackageTypeRepository(ref.watch(databaseServiceProvider));
});

final orderPackageRepositoryProvider = Provider<OrderPackageRepository>((ref) {
  return OrderPackageRepository(ref.watch(databaseServiceProvider));
});

final orderDetailProvider =
    FutureProvider.family<CoffeeOrder?, int>((ref, orderId) async {
  final repo = ref.watch(coffeeOrderRepositoryProvider);
  return repo.fetchById(orderId);
});

final orderTotalProvider =
    FutureProvider.family<double, int>((ref, orderId) async {
  final repo = ref.watch(coffeeOrderRepositoryProvider);
  return repo.fetchOrderTotal(orderId);
});

final overviewProvider = FutureProvider<OverviewData>((ref) async {
  final repo = ref.watch(coffeeOrderRepositoryProvider);
  final orders = await repo.fetchOrdersWithTotals();
  final now = DateTime.now();
  final monthlyOrders = orders.where((item) {
    final date = item.order.arrivalDate;
    return date.year == now.year && date.month == now.month;
  }).toList();
  final total = monthlyOrders.fold(0.0, (sum, item) => sum + item.total);
  final pendingPackages =
      monthlyOrders.where((item) => item.isPendingPackaging).length;
  return OverviewData(
    totalOrders: monthlyOrders.length,
    totalRevenue: total,
    pendingPackages: pendingPackages,
  );
});

class OverviewData {
  OverviewData({
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingPackages,
  });

  final int totalOrders;
  final double totalRevenue;
  final int pendingPackages;
}
