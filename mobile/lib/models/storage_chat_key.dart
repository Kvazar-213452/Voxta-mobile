import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../utils/crypto/make_key_chat.dart';

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
            isEncrypted INTEGER NOT NULL DEFAULT 0,
            keys TEXT NOT NULL,
            keyAES TEXT
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

  // ==================== RSA KEY MANAGEMENT ====================

  static Future<Map<String, String>> generateAndSaveRSAKeys(
    String chatId, {
    int keySize = 2048,
  }) async {
    try {
      final keyPair = await RSACrypto.generateKeyPair(keySize: keySize);
      
      await saveRSAKeys(
        chatId,
        publicKey: keyPair['public']!,
        privateKey: keyPair['private']!,
      );

      return keyPair;
    } catch (e) {
      print('Failed to generate and save RSA keys: $e');
      rethrow;
    }
  }

  static Future<void> saveRSAKeys(
    String chatId, {
    required String publicKey,
    required String privateKey,
  }) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      Map<String, dynamic> keysData;
      bool isEncrypted = true;
      String? keyAES;

      if (result.isNotEmpty) {
        final existingKeysJson = result.first['keys'] as String;
        keysData = jsonDecode(existingKeysJson);
        isEncrypted = (result.first['isEncrypted'] as int) == 1;
        keyAES = result.first['keyAES'] as String?;

        keysData['pub'] = publicKey;

        List<String> privKeys = List<String>.from(keysData['priv'] ?? []);
        if (!privKeys.contains(privateKey)) {
          privKeys.add(privateKey);
        }
        keysData['priv'] = privKeys;
      } else {
        keysData = {
          'pub': publicKey,
          'priv': [privateKey],
        };
      }

      await db.insert('chat_keys', {
        'chatId': chatId,
        'isEncrypted': isEncrypted ? 1 : 0,
        'keys': jsonEncode(keysData),
        'keyAES': keyAES,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

    } catch (e) {
      print('Failed to save RSA keys: $e');
      rethrow;
    }
  }

  static Future<void> updatePublicKey(String chatId, String publicKey) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      Map<String, dynamic> keysData;
      bool isEncrypted = true;
      String? keyAES;

      if (result.isNotEmpty) {
        final existingKeysJson = result.first['keys'] as String;
        keysData = jsonDecode(existingKeysJson);
        isEncrypted = (result.first['isEncrypted'] as int) == 1;
        keyAES = result.first['keyAES'] as String?;
        keysData['pub'] = publicKey;
      } else {
        keysData = {
          'pub': publicKey,
          'priv': [],
        };
      }

      await db.insert('chat_keys', {
        'chatId': chatId,
        'isEncrypted': isEncrypted ? 1 : 0,
        'keys': jsonEncode(keysData),
        'keyAES': keyAES,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

    } catch (e) {
      print('Failed to update public key: $e');
      rethrow;
    }
  }

  static Future<String?> getPublicKey(String chatId) async {
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
      final keysData = jsonDecode(keysJson);

      final pubKey = keysData['pub'] as String?;
      return (pubKey == null || pubKey.isEmpty) ? null : pubKey;
    } catch (e) {
      print('Failed to get public key: $e');
      return null;
    }
  }

  static Future<String?> getPrivateKey(String chatId) async {
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
      final keysData = jsonDecode(keysJson);
      final privKeys = List<String>.from(keysData['priv'] ?? []);

      if (privKeys.isEmpty) {
        return null;
      }

      return privKeys.last;
    } catch (e) {
      print('Failed to get private key: $e');
      return null;
    }
  }

  static Future<List<String>> getAllPrivateKeys(String chatId) async {
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
      final keysData = jsonDecode(keysJson);

      return List<String>.from(keysData['priv'] ?? []);
    } catch (e) {
      print('Failed to get all private keys: $e');
      return [];
    }
  }

  static Future<void> addPrivateKey(String chatId, String privateKey) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      Map<String, dynamic> keysData;
      bool isEncrypted = true;
      String? keyAES;

      if (result.isNotEmpty) {
        final existingKeysJson = result.first['keys'] as String;
        keysData = jsonDecode(existingKeysJson);
        isEncrypted = (result.first['isEncrypted'] as int) == 1;
        keyAES = result.first['keyAES'] as String?;

        List<String> privKeys = List<String>.from(keysData['priv'] ?? []);
        if (!privKeys.contains(privateKey)) {
          privKeys.add(privateKey);
        }
        keysData['priv'] = privKeys;
      } else {
        keysData = {
          'pub': '',
          'priv': [privateKey],
        };
      }

      await db.insert('chat_keys', {
        'chatId': chatId,
        'isEncrypted': isEncrypted ? 1 : 0,
        'keys': jsonEncode(keysData),
        'keyAES': keyAES,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print('Private key added for chatId: $chatId');
    } catch (e) {
      print('Failed to add private key: $e');
      rethrow;
    }
  }

  static Future<void> removePrivateKey(String chatId, String privateKey) async {
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

      final keysJson = result.first['keys'] as String;
      final keysData = jsonDecode(keysJson);
      
      List<String> privKeys = List<String>.from(keysData['priv'] ?? []);
      privKeys.remove(privateKey);
      keysData['priv'] = privKeys;

      await db.update(
        'chat_keys',
        {'keys': jsonEncode(keysData)},
        where: 'chatId = ?',
        whereArgs: [chatId],
      );

      print('Private key removed for chatId: $chatId');
    } catch (e) {
      print('Failed to remove private key: $e');
      rethrow;
    }
  }

  // ==================== AES KEY MANAGEMENT ====================

  static Future<void> setKeyAES(String chatId, String keyAES) async {
    try {
      final db = await initDatabase();

      final result = await db.query(
        'chat_keys',
        where: 'chatId = ?',
        whereArgs: [chatId],
        limit: 1,
      );

      if (result.isEmpty) {
        await db.insert('chat_keys', {
          'chatId': chatId,
          'isEncrypted': 0,
          'keys': jsonEncode({'pub': '', 'priv': []}),
          'keyAES': keyAES,
        });
      } else {
        await db.update(
          'chat_keys',
          {'keyAES': keyAES},
          where: 'chatId = ?',
          whereArgs: [chatId],
        );
      }

      print('AES key set for chatId: $chatId');
    } catch (e) {
      print('Failed to set AES key: $e');
      rethrow;
    }
  }

  static Future<String?> getKeyAES(String chatId) async {
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

      return result.first['keyAES'] as String?;
    } catch (e) {
      print('Failed to get AES key: $e');
      return null;
    }
  }

  // ==================== LEGACY METHODS ====================

  static Future<void> addKey(String chatId, String key) async {
    await addPrivateKey(chatId, key);
  }

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
        await db.insert('chat_keys', {
          'chatId': chatId,
          'isEncrypted': isEncrypted ? 1 : 0,
          'keys': jsonEncode({'pub': '', 'priv': []}),
          'keyAES': null,
        });
      } else {
        await db.update(
          'chat_keys',
          {'isEncrypted': isEncrypted ? 1 : 0},
          where: 'chatId = ?',
          whereArgs: [chatId],
        );
      }

    } catch (e) {
      print('Failed to set encryption: $e');
      rethrow;
    }
  }

  static Future<String> getKey(String chatId) async {
    try {
      final infoChat = await getChatInfo(chatId);
      final bool isEncrypted = infoChat?["isEncrypted"] == true;

      if (isEncrypted) {
        final privateKey = await getPrivateKey(chatId);
        return privateKey ?? "";
      } else {
        return "";
      }
    } catch (e) {
      print('Failed to get key: $e');
      return "";
    }
  }

  static Future<List<String>> getAllKeys(String chatId) async {
    return await getAllPrivateKeys(chatId);
  }

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

      final keysJson = result.first['keys'] as String;
      final keysData = jsonDecode(keysJson);
      
      keysData['priv'] = [];

      await db.update(
        'chat_keys',
        {'keys': jsonEncode(keysData)},
        where: 'chatId = ?',
        whereArgs: [chatId],
      );

    } catch (e) {
      print('Failed to delete all keys: $e');
      rethrow;
    }
  }

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
      final keysData = jsonDecode(keysJson);
      final isEncrypted = (result.first['isEncrypted'] as int) == 1;
      final keyAES = result.first['keyAES'] as String?;

      return {
        'chatId': chatId,
        'isEncrypted': isEncrypted,
        'publicKey': keysData['pub'],
        'privateKeys': keysData['priv'],
        'keyAES': keyAES,
      };
    } catch (e) {
      print('Failed to get chat info: $e');
      return null;
    }
  }
}