import 'package:sqflite/sqflite.dart';

import '../datasources/database_service.dart';
import '../models/package_type.dart';

class PackageTypeRepository {
  PackageTypeRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<PackageType>> fetchAll({bool onlyActive = false}) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'package_types',
      where: onlyActive ? 'is_active = 1' : null,
      orderBy: 'name ASC',
    );
    return result.map(PackageType.fromMap).toList();
  }

  Future<PackageType?> fetchById(int id) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'package_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) {
      return null;
    }
    return PackageType.fromMap(result.first);
  }

  Future<void> insert(PackageType packageType) async {
    final db = await _databaseService.database;
    await db.insert('package_types', packageType.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(PackageType packageType) async {
    final db = await _databaseService.database;
    await db.update(
      'package_types',
      packageType.toMap(),
      where: 'id = ?',
      whereArgs: [packageType.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _databaseService.database;
    await db.delete('package_types', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedDefaultsIfEmpty() async {
    final db = await _databaseService.database;
    final result =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM package_types'));
    if (result != null && result > 0) {
      return;
    }
    final now = DateTime.now();
    final defaults = [
      PackageType(
        name: 'Bolsa 200g',
        price: 9000,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      PackageType(
        name: 'Bolsa 500g',
        price: 18000,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      PackageType(
        name: 'Caja regalo',
        price: 32000,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final item in defaults) {
      await db.insert('package_types', item.toMap());
    }
  }
}
