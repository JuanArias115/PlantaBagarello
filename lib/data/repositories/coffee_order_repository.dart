import 'package:sqflite/sqflite.dart';

import '../datasources/database_service.dart';
import '../models/coffee_order.dart';

class OrderListItem {
  OrderListItem({
    required this.order,
    required this.total,
    required this.hasPackages,
    required this.packedGrams,
  });

  final CoffeeOrder order;
  final double total;
  final bool hasPackages;
  final double packedGrams;

  bool get isPackingComplete {
    final requiredGrams = order.lotKg * 1000;
    if (requiredGrams <= 0) {
      return true;
    }
    return packedGrams >= requiredGrams;
  }

  bool get isPendingPackaging => !isPackingComplete;
}

class CoffeeOrderRepository {
  CoffeeOrderRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<int> insert(CoffeeOrder order) async {
    final db = await _databaseService.database;
    return db.insert('coffee_orders', order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<OrderListItem>> fetchOrdersWithTotals() async {
    final db = await _databaseService.database;
    final results = await db.rawQuery('''
      SELECT o.*, IFNULL(SUM(i.quantity * i.unit_price_snapshot), 0) AS total,
      COUNT(i.id) AS item_count,
      IFNULL(SUM(i.quantity * IFNULL(p.grams_per_package, 0)), 0) AS packed_grams
      FROM coffee_orders o
      LEFT JOIN order_package_items i ON i.order_id = o.id
      LEFT JOIN package_types p ON p.id = i.package_type_id
      GROUP BY o.id
      ORDER BY o.arrival_date ASC
    ''');

    return results
        .map((row) => OrderListItem(
              order: CoffeeOrder.fromMap(row),
              total: (row['total'] as num).toDouble(),
              hasPackages: (row['item_count'] as int) > 0,
              packedGrams: (row['packed_grams'] as num?)?.toDouble() ?? 0,
            ))
        .toList();
  }

  Future<CoffeeOrder?> fetchById(int id) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'coffee_orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) {
      return null;
    }
    return CoffeeOrder.fromMap(results.first);
  }

  Future<void> update(CoffeeOrder order) async {
    final db = await _databaseService.database;
    await db.update(
      'coffee_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _databaseService.database;
    await db.delete('coffee_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> fetchOrderTotal(int orderId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('''
      SELECT IFNULL(SUM(quantity * unit_price_snapshot), 0) AS total
      FROM order_package_items
      WHERE order_id = ?
    ''', [orderId]);
    return (result.first['total'] as num).toDouble();
  }
}
