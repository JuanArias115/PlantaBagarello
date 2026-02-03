import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static const _dbName = 'planta_bagarello.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _init();
    return _database!;
  }

  Future<Database> _init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE coffee_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        customer_address TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        arrival_date INTEGER NOT NULL,
        lot_kg REAL NOT NULL,
        roast_type TEXT NOT NULL,
        grind_type TEXT NOT NULL,
        observation TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE package_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_package_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        package_type_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price_snapshot REAL NOT NULL,
        FOREIGN KEY(order_id) REFERENCES coffee_orders(id) ON DELETE CASCADE,
        FOREIGN KEY(package_type_id) REFERENCES package_types(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_orders_arrival ON coffee_orders(arrival_date)',
    );
    await db.execute(
      'CREATE INDEX idx_items_order ON order_package_items(order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_items_package_type ON order_package_items(package_type_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await _onCreate(db, newVersion);
    }
  }
}
