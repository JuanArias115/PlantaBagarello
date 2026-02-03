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
    final types = result.map(PackageType.fromMap).toList();
    await _syncGramsFromNameIfMissing(db, types);
    return types;
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

  Future<void> syncGramsFromNames() async {
    final db = await _databaseService.database;
    final result = await db.query('package_types');
    final types = result.map(PackageType.fromMap).toList();
    await _syncGramsFromNameIfMissing(db, types);
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
        name: 'A granel 2.5 lb',
        price: 9000,
        gramsPerPackage: 1250,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      PackageType(
        name: 'A granel 10 lb',
        price: 18000,
        gramsPerPackage: 5000,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      PackageType(
        name: 'Bolsa 250 gr',
        price: 9000,
        gramsPerPackage: 250,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      PackageType(
        name: 'Bolsa 454 gr',
        price: 18000,
        gramsPerPackage: 454,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      PackageType(
        name: 'Bolsa 500 gr',
        price: 18000,
        gramsPerPackage: 500,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final item in defaults) {
      await db.insert('package_types', item.toMap());
    }
  }

  Future<void> _syncGramsFromNameIfMissing(
    Database db,
    List<PackageType> types,
  ) async {
    final now = DateTime.now();
    for (final type in types) {
      if (type.gramsPerPackage > 0 || type.id == null) {
        continue;
      }
      final guessed = _guessGramsFromName(type.name);
      if (guessed == null || guessed <= 0) {
        continue;
      }
      await db.update(
        'package_types',
        {
          'grams_per_package': guessed,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [type.id],
      );
    }
  }

  double? _guessGramsFromName(String name) {
    final match =
        RegExp(r'(\\d+(?:[\\.,]\\d+)?)\\s*(kg|g|lb)?', caseSensitive: false)
            .firstMatch(name);
    if (match == null) {
      return null;
    }
    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      return null;
    }
    final unit = match.group(2)?.toLowerCase();
    if (unit == 'kg') {
      return value * 1000;
    }
    if (unit == 'lb') {
      return value * 500;
    }
    return value;
  }
}
