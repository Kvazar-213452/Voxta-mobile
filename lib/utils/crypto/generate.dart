import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/random/fortuna_random.dart';

crypto.SecureRandom _getSecureRandom() {
  final secureRandom = FortunaRandom();
  final seedSource = Random.secure();
  final seeds = <int>[];
  for (int i = 0; i < 32; i++) {
    seeds.add(seedSource.nextInt(256));
  }
  secureRandom.seed(crypto.KeyParameter(Uint8List.fromList(seeds)));
  return secureRandom;
}

Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> generateRSAkeyPair({int bitLength = 4096}) async {
  final keyGen = RSAKeyGenerator();
  final secureRandom = _getSecureRandom();
  
  final params = RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64);
  final rngParams = ParametersWithRandom(params, secureRandom);
  keyGen.init(rngParams);
  
  final pair = keyGen.generateKeyPair();
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
    pair.publicKey as RSAPublicKey,
    pair.privateKey as RSAPrivateKey,
  );
}

