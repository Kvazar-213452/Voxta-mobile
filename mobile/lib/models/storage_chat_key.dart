import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ChatKeysDB {
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

  static Future<Database> initDatabase() async {
    _initializeDatabaseFactory();
    
    if (_db != null) return _db!;

    Directory dir;
    
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (e) {
      dir = Directory.current;
    }
    
    String path = join(dir.path, 'chat_keys.db');
    print('Database path: $path');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_keys (
            chatId TEXT PRIMARY KEY,
            key TEXT NOT NULL
          )
        ''');
        print('Chat keys table created');
      },
      onOpen: (db) async {
        print('Chat keys database opened successfully');
      },
    );

    return _db!;
  }

  static Future<void> addKey(String chatId, String key) async {
    try {
      final db = await initDatabase();
      
      await db.insert(
        'chat_keys',
        {'chatId': chatId, 'key': key},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('Key added/updated for chatId: $chatId');
    } catch (e) {
      print('Failed to add key: $e');
      rethrow;
    }
  }

  static Future<void> deleteKey(String chatId) async {
    try {
      final db = await initDatabase();
      
      await db.delete(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
      );
      
      print('Key deleted for chatId: $chatId');
    } catch (e) {
      print('Failed to delete key: $e');
      rethrow;
    }
  }

  static Future<String> getKey(String chatId) async {
    try {
      final db = await initDatabase();
      
      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      if (result.isEmpty) {
        return "";
      }
      
      return result.first['key'] as String;
    } catch (e) {
      print('Failed to get key: $e');
      return "";
    }
  }
}