import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:pointycastle/export.dart';
import 'encryption_service.dart';

class EncryptionServer {
  late AsymmetricKeyPair keyPair;
  late String publicKeyPem;
  late String privateKeyPem;

  static const int maxRequestSize = 10 * 1024 * 1024;

  void generateKey() {
    keyPair = EncryptionService.generateRSAKeyPair();
    EncryptionService.saveKeyPair(keyPair);
  }

  Map<String, String> encryptionMsg(String publicRsaKey, String message) {
    return EncryptionService.encryptMessage(publicRsaKey, message);
  }

  String decryptionServer(Map<String, String> encryptedData) {
    return EncryptionService.decryptMessage(encryptedData);
  }

  Middleware requestSizeLimit() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.headers['content-length'] != null) {
          final contentLength = int.parse(request.headers['content-length']!);
          if (contentLength > maxRequestSize) {
            return Response.badRequest(
              body: json.encode({
                'error': 'Розмір запиту перевищує допустимий ліміт (${maxRequestSize ~/ (1024 * 1024)}MB)'
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }
        }
        return await innerHandler(request);
      };
    };
  }

  Future<String> safeReadBody(Request request) async {
    final buffer = <int>[];
    int totalBytes = 0;
    
    await for (final chunk in request.read()) {
      totalBytes += chunk.length;
      if (totalBytes > maxRequestSize) {
        throw Exception('Розмір запиту перевищує допустимий ліміт');
      }
      buffer.addAll(chunk);
    }
    
    return utf8.decode(buffer);
  }

  Future<void> startServer() async {
    final app = Router();

    app.get('/public_key_mobile', (Request request) async {
      try {
        final publicKey = File('public_key.pem').readAsStringSync();
        return Response.ok(
          json.encode({'key': publicKey}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.notFound(
          json.encode({'error': 'Публічний ключ не знайдено'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    app.post('/encryption', (Request request) async {
      try {
        final body = await safeReadBody(request);
        final data = json.decode(body);

        final publicKey = data['key'] as String;
        final message = data['data'] as String;

        if (message.length > 1024 * 1024) {
          return Response.badRequest(
            body: json.encode({'error': 'Повідомлення занадто велике'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        final result = encryptionMsg(publicKey, message);

        return Response.ok(
          json.encode({'code': 1, 'message': result}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.badRequest(
          body: json.encode({'error': 'Помилка шифрування: $e'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    app.post('/decrypt', (Request request) async {
      try {
        final body = await safeReadBody(request);
        final data = json.decode(body);

        final encryptedData = {
          'key': data['data']['key'] as String,
          'data': data['data']['data'] as String,
        };

        final result = decryptionServer(encryptedData);

        return Response.ok(
          json.encode({'code': 1, 'message': result}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.badRequest(
          body: json.encode({'error': 'Помилка розшифрування: $e'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    final handler = Pipeline()
        .addMiddleware(requestSizeLimit())
        .addMiddleware((handler) {
          return (request) async {
            final response = await handler(request);
            return response.change(headers: {
              ...response.headers,
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            });
          };
        })
        .addMiddleware(logRequests())
        .addHandler(app);

    await serve(handler, '0.0.0.0', 4002);
    print('Сервер запущено на http://0.0.0.0:4002');
    print('Максимальний розмір запиту: ${maxRequestSize ~/ (1024 * 1024)}MB');
  }
}