import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'interface/settings.dart';

class SettingsDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = join(dir.path, 'voxta_settings.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            darkMode INTEGER DEFAULT 1,
            browserNotifications INTEGER DEFAULT 1,
            doNotDisturb INTEGER DEFAULT 0,
            language TEXT DEFAULT 'uk',
            readReceipts INTEGER DEFAULT 1,
            onlineStatus INTEGER DEFAULT 1,
            cripto TEXT DEFAULT 'm1'
          )
        ''');

        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM settings')
        );

        if (count == 0) {
          final defaultSettings = Settings(
            darkMode: true,
            browserNotifications: true,
            doNotDisturb: false,
            language: 'uk',
            readReceipts: true,
            onlineStatus: true,
            cripto: 'm1',
          );
          await db.insert('settings', defaultSettings.toMap());
        }
      },
    );
  }

  static Future<void> saveSettings(Settings settings) async {
    final db = await database;
    await db.delete('settings');
    await db.insert('settings', settings.toMap());
  }

  static Future<Settings?> getSettings() async {
    try {
      final db = await database;
      final result = await db.query('settings', limit: 1);

      if (result.isEmpty) return null;
      return Settings.fromMap(result.first);
    } catch (e) {
      print('Failed to get settings: $e');
      return null;
    }
  }

  static Future<void> deleteSettings() async {
    final db = await database;
    await db.delete('settings');
  }
}
