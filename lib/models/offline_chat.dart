import 'dart:io';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'interface/offlne_msg.dart';

class ChatDB {
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
    
    String path = join(dir.path, 'chat_database.db');
    print('Database path: $path');

    final dbExists = await File(path).exists();

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createChatTables(db);
      },
      onOpen: (db) async {
        print('Database opened successfully');
      },
    );

    if (!dbExists) {
      print('chat_database.db created');
      await _createChatTables(db);
    } else {
      print('Database already exists - good');
    }

    return db;
  }

  static Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chats (
        id TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_participants (
        chatId TEXT,
        userId TEXT,
        PRIMARY KEY (chatId, userId),
        FOREIGN KEY (chatId) REFERENCES chats(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        chatId TEXT,
        sender TEXT,
        content TEXT,
        time TEXT,
        FOREIGN KEY (chatId) REFERENCES chats(id)
      )
    ''');

    print('Chat tables created');
  }

  static void initDatabaseChats() {
    database.then((db) {
      print('Chat database initialized');
    }).catchError((error) {
      print('Failed to initialize chat database: $error');
    });
  }

  static Database getDatabase() {
    if (_db == null) {
      throw Exception('Database not initialized. Call initDatabaseChats() first');
    }
    return _db!;
  }

  static Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      print('Chat database closed');
    }
  }

  static Future<bool> testConnection() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      print('Chat database connection test: FAILED - $e');
      return false;
    }
  }

  // ! ========= utils =========

  static Future<void> createChatTables() async {
    final db = await database;
    await _createChatTables(db);
  }

  static Future<void> createChat(String id) async {
    try {
      final db = await database;
      
      await db.execute('''
        INSERT OR IGNORE INTO chats (id)
        VALUES (?)
      ''', [id]);
      
      print('Chat created with id: $id');
    } catch (e) {
      print('Failed to create chat: $e');
      rethrow;
    }
  }

  static String generateUniqueId([int length = 12]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    String result = '';
    
    for (int i = 0; i < length; i++) {
      result += chars[random.nextInt(chars.length)];
    }
    
    return result;
  }

  static Future<Message> addMessage(String chatId, MsgToDb message) async {
    try {
      final db = await database;
      final id = generateUniqueId();

      await db.execute('''
        INSERT INTO messages (id, chatId, sender, content, time)
        VALUES (?, ?, ?, ?, ?)
      ''', [id, chatId, message.sender, message.content, message.time]);

      return Message(
        id: id,
        sender: message.sender,
        content: message.content,
        time: message.time,
      );
    } catch (e) {
      print('Failed to add message: $e');
      rethrow;
    }
  }

  static Future<List<Message>> getMessagesByChatId(String chatId) async {
    try {
      final db = await database;
      
      final results = await db.query(
        'messages',
        columns: ['id', 'sender', 'content', 'time'],
        where: 'chatId = ?',
        whereArgs: [chatId],
        orderBy: 'time ASC',
      );

      return results.map((row) => Message.fromMap(row)).toList();
    } catch (e) {
      print('Failed to get messages: $e');
      return [];
    }
  }

  static Future<List<String>> getAllChatIds() async {
    try {
      final db = await database;
      
      final results = await db.query('chats', columns: ['id']);
      
      return results.map((row) => row['id'] as String).toList();
    } catch (e) {
      print('Failed to get chat IDs: $e');
      return [];
    }
  }
}
