import 'package:sqflite/sqflite.dart';

import '../datasources/database_service.dart';
import '../models/order_package_item.dart';

class OrderPackageRepository {
  OrderPackageRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<OrderPackageItem>> fetchByOrderId(int orderId) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'order_package_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return result.map(OrderPackageItem.fromMap).toList();
  }

  Future<void> upsertItem(OrderPackageItem item) async {
    final db = await _databaseService.database;
    final existing = await db.query(
      'order_package_items',
      where: 'order_id = ? AND package_type_id = ?',
      whereArgs: [item.orderId, item.packageTypeId],
    );
    if (existing.isEmpty) {
      await db.insert('order_package_items', item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final id = existing.first['id'] as int;
      await db.update(
        'order_package_items',
        item.copyWith(id: id).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteItem(int id) async {
    final db = await _databaseService.database;
    await db.delete('order_package_items', where: 'id = ?', whereArgs: [id]);
  }
}

extension on OrderPackageItem {
  OrderPackageItem copyWith({int? id}) {
    return OrderPackageItem(
      id: id ?? this.id,
      orderId: orderId,
      packageTypeId: packageTypeId,
      quantity: quantity,
      unitPriceSnapshot: unitPriceSnapshot,
    );
  }
}
