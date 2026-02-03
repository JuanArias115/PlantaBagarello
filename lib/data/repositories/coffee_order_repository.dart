import 'package:sqflite/sqflite.dart';

import '../datasources/database_service.dart';
import '../models/coffee_order.dart';

class OrderListItem {
  OrderListItem({
    required this.order,
    required this.total,
    required this.hasPackages,
  });

  final CoffeeOrder order;
  final double total;
  final bool hasPackages;
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
      COUNT(i.id) AS item_count
      FROM coffee_orders o
      LEFT JOIN order_package_items i ON i.order_id = o.id
      GROUP BY o.id
      ORDER BY o.arrival_date ASC
    ''');

    return results
        .map((row) => OrderListItem(
              order: CoffeeOrder.fromMap(row),
              total: (row['total'] as num).toDouble(),
              hasPackages: (row['item_count'] as int) > 0,
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
