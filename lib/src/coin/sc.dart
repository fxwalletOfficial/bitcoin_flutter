import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:pointycastle/digests/blake2b.dart';
import 'package:convert/convert.dart' show hex;
import 'package:pinenacl/ed25519.dart';

const SC_ADDRESS_LENGTH = 32;
final SC_INDEX = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0]);
const TIME_LOCK_HASH =
    '5187b7a8021bf4f2c004ea3a54cfece1754f11c7624d2363c7f4cf4fddd1441e';
const SIG_HASH =
    'b36010eb285c154a8cd63084acbe7eac0c4d625ab4e1a76e624a8798cb63497b';

class Sc {
  static Uint8List mnemonicToPrivateKey(String mnemonic) {
    final seed = bip39.mnemonicToEntropy(mnemonic);
    final seedByte = Uint8List.fromList(hex.decode(seed));
    final hash = black2bHash(seedByte);
    final blake2b = Blake2bDigest(digestSize: 32);
    blake2b.update(hash, 0, hash.length);
    blake2b.update(SC_INDEX, 0, SC_INDEX.length);
    final array = Uint8List(blake2b.digestSize);
    blake2b.doFinal(array, 0);
    return array.sublist(0, 32);
  }

  static Uint8List mnemonicToPublicKey(String mnemonic) {
    final keyPair = mnemonicToPairKey(mnemonic);
    final publicKey = keyPair.publicKey.toUint8List();
    return publicKey;
  }

  static String publicKeyToAddress(Uint8List publicKey) {
    final Algorithm = 'ed25519';
    final buf = List<int>.filled(65, 0);
    for (var i = 0; i < Algorithm.length; i++) {
      buf[i + 1] = Algorithm.codeUnitAt(i);
    }
    buf[17] = publicKey.length;
    for (var i = 0; i < publicKey.length; i++) {
      buf[i + 25] = publicKey[i];
    }

    final pubkeyHash = black2bHash(Uint8List.fromList(buf.sublist(0, 57)));
    final timeLockHash = hex.decode(TIME_LOCK_HASH);
    final sigHash = hex.decode(SIG_HASH);

    buf[0] = 0x01;
    for (var i = 0; i < timeLockHash.length; i++) {
      buf[i + 1] = timeLockHash[i];
    }
    for (var i = 0; i < pubkeyHash.length; i++) {
      buf[i + 33] = pubkeyHash[i];
    }
    final tlpkHash = black2bHash(Uint8List.fromList(buf));
    for (var i = 0; i < tlpkHash.length; i++) {
      buf[i + 1] = tlpkHash[i];
    }
    for (var i = 0; i < sigHash.length; i++) {
      buf[i + 33] = sigHash[i];
    }

    final unlockHash = black2bHash(Uint8List.fromList(buf));
    final checksum = black2bHash(Uint8List.fromList(unlockHash));
    final address = unlockHash + checksum.sublist(0, 6);
    return hex.encode(address);
  }

  static String mnemonicToSuiAddress(String mnemonic) {
    final publicKey = mnemonicToPublicKey(mnemonic);
    return publicKeyToAddress(publicKey);
  }

  static SigningKey privateKeyToPairKey(Uint8List privateKey) {
    return SigningKey.fromSeed(privateKey);
  }

  static SigningKey mnemonicToPairKey(String mnemonic) {
    final privateKey = mnemonicToPrivateKey(mnemonic);
    return privateKeyToPairKey(privateKey);
  }
}

Uint8List black2bHash(Uint8List hashRaw) {
  final blake2b = Blake2bDigest(digestSize: 32);
  blake2b.update(hashRaw, 0, hashRaw.length);
  final hash = Uint8List(blake2b.digestSize);
  blake2b.doFinal(hash, 0);
  return hash;
}
