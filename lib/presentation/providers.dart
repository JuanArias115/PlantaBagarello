import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/database_service.dart';
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
