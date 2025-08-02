import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'interface/settings.dart';

class SettingsDB {
  static Database? _db;
  static bool _initialized = false;

  static void _initializeDatabaseFactory() {
    if (_initialized) return;
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _initialized = true;
  }

  static Future<Database> get database async {
    _initializeDatabaseFactory();
    
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    Directory dir;
    
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (e) {
      dir = Directory.current;
    }
    
    String path = join(dir.path, 'voxta_settings.db');
    print('Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            darkMode INTEGER DEFAULT 1,
            browserNotifications INTEGER DEFAULT 1,
            doNotDisturb INTEGER DEFAULT 0,
            language TEXT DEFAULT 'uk',
            readReceipts INTEGER DEFAULT 1,
            onlineStatus INTEGER DEFAULT 1
          )
        ''');

        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM settings')
        ) ?? 0;

        if (count == 0) {
          final defaultSettings = Settings(
            darkMode: true,
            browserNotifications: true,
            doNotDisturb: false,
            language: 'uk',
            readReceipts: true,
            onlineStatus: true
          );
          
          await db.insert('settings', defaultSettings.toMap());
          print('Default settings inserted');
        }
      },
      onOpen: (db) async {
        print('Database opened successfully');
      },
    );
  }

  static Future<void> saveSettings(Settings settings) async {
    try {
      final db = await database;
      
      final existing = await db.query('settings', limit: 1);
      
      if (existing.isEmpty) {
        await db.insert('settings', settings.toMap());
        print('Settings inserted');
      } else {
        await db.update(
          'settings', 
          settings.toMap(),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
        print('Settings updated');
      }
    } catch (e) {
      print('Failed to save settings: $e');
      rethrow;
    }
  }

  static Future<Settings?> getSettings() async {
    try {
      final db = await database;
      final result = await db.query('settings', limit: 1);

      if (result.isEmpty) {
        return null;
      }
      
      return Settings.fromMap(result.first);
    } catch (e) {
      print('Failed to get settings: $e');
      return null;
    }
  }

  static Future<void> deleteSettings() async {
    try {
      final db = await database;
      await db.delete('settings');
    } catch (e) {
      print('Failed to delete settings: $e');
      rethrow;
    }
  }

  static Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      print('Database closed');
    }
  }

  static Future<bool> testConnection() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      print('Database connection test: FAILED - $e');
      return false;
    }
  }
}