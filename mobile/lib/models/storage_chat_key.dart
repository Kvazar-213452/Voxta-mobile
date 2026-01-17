import 'dart:io';
import 'dart:convert';
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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS chat_keys (
            chatId TEXT PRIMARY KEY,
            isEncrypted INTEGER NOT NULL DEFAULT 0,
            keys TEXT NOT NULL,
            scheduledUpdate INTEGER
          )
        ''');
        print('Chat keys table created');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Міграція з версії 1 до 2
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_keys_new (
              chatId TEXT PRIMARY KEY,
              isEncrypted INTEGER NOT NULL DEFAULT 0,
              keys TEXT NOT NULL
            )
          ''');

          final oldData = await db.query('chat_keys');
          for (var row in oldData) {
            final chatId = row['chatId'] as String;
            final oldKey = row['key'] as String;
            final keysList = jsonEncode([oldKey]);

            await db.insert('chat_keys_new', {
              'chatId': chatId,
              'isEncrypted': 1,
              'keys': keysList,
            });
          }

          await db.execute('DROP TABLE chat_keys');
          await db.execute('ALTER TABLE chat_keys_new RENAME TO chat_keys');

          print('Database migrated to version 2');
        }
        
        if (oldVersion < 3) {
          // Міграція з версії 2 до 3 - додаємо поле scheduledUpdate
          await db.execute('''
            ALTER TABLE chat_keys ADD COLUMN scheduledUpdate INTEGER
          ''');
          print('Database migrated to version 3');
        }
      },
      onOpen: (db) async {
        print('Chat keys database opened successfully');
      },
    );

    return _db!;
  }

  // Додає новий ключ до масиву ключів чату
  static Future<void> addKey(String chatId, String key) async {
    try {
      final db = await initDatabase();

      // Отримуємо існуючі дані
      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      List<String> keys = [];
      bool isEncrypted = true;
      int? scheduledUpdate;

      if (result.isNotEmpty) {
        // Якщо запис існує, додаємо новий ключ до масиву
        final existingKeys = result.first['keys'] as String;
        keys = List<String>.from(jsonDecode(existingKeys));
        isEncrypted = (result.first['isEncrypted'] as int) == 1;
        scheduledUpdate = result.first['scheduledUpdate'] as int?;

        if (!keys.contains(key)) {
          keys.add(key);
        }
      } else {
        // Якщо запис новий, створюємо масив з одним ключем
        keys = [key];
      }

      await db.insert('chat_keys', {
        'chatId': chatId,
        'isEncrypted': isEncrypted ? 1 : 0,
        'keys': jsonEncode(keys),
        'scheduledUpdate': scheduledUpdate,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print('Key added for chatId: $chatId. Total keys: ${keys.length}');
    } catch (e) {
      print('Failed to add key: $e');
      rethrow;
    }
  }

  // Змінює статус шифрування чату (true/false)
  static Future<void> setEncryption(String chatId, bool isEncrypted) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      if (result.isEmpty) {
        // Якщо чату немає, створюємо з порожнім масивом ключів
        await db.insert('chat_keys', {
          'chatId': chatId,
          'isEncrypted': isEncrypted ? 1 : 0,
          'keys': jsonEncode([]),
          'scheduledUpdate': null,
        });
      } else {
        // Оновлюємо статус шифрування
        await db.update(
          'chat_keys',
          {'isEncrypted': isEncrypted ? 1 : 0},
          where: 'chatId = ?',
          whereArgs: [chatId],
        );
      }

      print('Encryption status updated for chatId: $chatId to $isEncrypted');
    } catch (e) {
      print('Failed to set encryption: $e');
      rethrow;
    }
  }

  // Встановлює час наступного оновлення
  static Future<void> setScheduledUpdate(String chatId, DateTime? dateTime) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      final timestamp = dateTime?.millisecondsSinceEpoch;

      if (result.isEmpty) {
        // Якщо чату немає, створюємо новий запис
        await db.insert('chat_keys', {
          'chatId': chatId,
          'isEncrypted': 0,
          'keys': jsonEncode([]),
          'scheduledUpdate': timestamp,
        });
      } else {
        // Оновлюємо час наступного оновлення
        await db.update(
          'chat_keys',
          {'scheduledUpdate': timestamp},
          where: 'chatId = ?',
          whereArgs: [chatId],
        );
      }

      print('Scheduled update set for chatId: $chatId to ${dateTime?.toIso8601String() ?? "null"}');
    } catch (e) {
      print('Failed to set scheduled update: $e');
      rethrow;
    }
  }

  // Отримує час наступного оновлення
  static Future<DateTime?> getScheduledUpdate(String chatId) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      final timestamp = result.first['scheduledUpdate'] as int?;
      
      if (timestamp == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Failed to get scheduled update: $e');
      return null;
    }
  }

  // Видаляє всі дані чату (ключі та статус)
  static Future<void> deleteKey(String chatId) async {
    try {
      final db = await initDatabase();

      await db.delete('chat_keys', where: 'chatId = ?', whereArgs: [chatId]);

      print('All data deleted for chatId: $chatId');
    } catch (e) {
      print('Failed to delete key: $e');
      rethrow;
    }
  }

  static Future<String> getKey(String chatId) async {
    try {
      final infoChat = await getChatInfo(chatId);
      final bool isEncrypted = infoChat?["isEncrypted"] == true;

      if (isEncrypted) {
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

        final keysJson = result.first['keys'] as String;
        final keys = List<String>.from(jsonDecode(keysJson));

        if (keys.isEmpty) {
          return "";
        }

        return keys.last;
      } else {
        return "";
      }
    } catch (e) {
      print('Failed to get key: $e');
      return "";
    }
  }

  // Повертає всі ключі чату
  static Future<List<String>> getAllKeys(String chatId) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      if (result.isEmpty) {
        return [];
      }

      final keysJson = result.first['keys'] as String;
      return List<String>.from(jsonDecode(keysJson));
    } catch (e) {
      print('Failed to get all keys: $e');
      return [];
    }
  }

  // Видаляє всі ключі чату (залишає запис з порожнім масивом)
  static Future<void> deleteAllKeys(String chatId) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      if (result.isEmpty) {
        print('No keys found for chatId: $chatId');
        return;
      }

      final isEncrypted = (result.first['isEncrypted'] as int) == 1;

      await db.update(
        'chat_keys',
        {'keys': jsonEncode([])},
        where: 'chatId = ?',
        whereArgs: [chatId],
      );

      print(
        'All keys deleted for chatId: $chatId. Encryption status: $isEncrypted',
      );
    } catch (e) {
      print('Failed to delete all keys: $e');
      rethrow;
    }
  }

  // Перевіряє, чи шифрується чат
  static Future<bool> isEncrypted(String chatId) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      if (result.isEmpty) {
        return false;
      }

      return (result.first['isEncrypted'] as int) == 1;
    } catch (e) {
      print('Failed to check encryption status: $e');
      return false;
    }
  }

  // Отримує повну інформацію про чат
  static Future<Map<String, dynamic>?> getChatInfo(String chatId) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      if (result.isEmpty) {
        return null;
      }

      final keysJson = result.first['keys'] as String;
      final keys = List<String>.from(jsonDecode(keysJson));
      final isEncrypted = (result.first['isEncrypted'] as int) == 1;
      final timestamp = result.first['scheduledUpdate'] as int?;
      final scheduledUpdate = timestamp != null 
          ? DateTime.fromMillisecondsSinceEpoch(timestamp) 
          : null;

      return {
        'chatId': chatId,
        'isEncrypted': isEncrypted,
        'keys': keys,
        'scheduledUpdate': scheduledUpdate,
      };
    } catch (e) {
      print('Failed to get chat info: $e');
      return null;
    }
  }
}