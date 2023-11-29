import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:pointycastle/digests/blake2b.dart';
import 'package:convert/convert.dart' show hex;

import 'package:bitcoin_flutter/src/bech32/bech32.dart';
import 'package:bitcoin_flutter/src/utils/script.dart';

const CKB_HASH_PERSONALIZATION = 'ckb-default-hash';
const CKB_CODE_HASH =
    '9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8';
const SHORT_ID = 0;
const MAX_LENGTH = 1023;
const PREFIX = 'ckb';
const BIP_PATH = "m/44'/309'/0'/0/0";
/// Generates pubkey seed by mnemonic
Uint8List mnemonicToPubKey(String mnemonic) {
  final seed = bip39.mnemonicToSeed(mnemonic);
  return privateKeyToPubKey(seed);
}

/// Generates pubkey seed by privateKey
Uint8List privateKeyToPubKey(Uint8List privateKey) {
  final keychain = bip32.BIP32.fromSeed(privateKey);
  final keyPair = keychain.derivePath(BIP_PATH);
  return keyPair.publicKey;
}

/// Generate arg
Uint8List pubKeyToArg(Uint8List pubKey) {
  /// [99, 107, 98, 45, 100, 101, 102, 97, 117, 108, 116, 45, 104, 97, 115]
  final personalization =
      Uint8List.fromList(utf8.encode(CKB_HASH_PERSONALIZATION));
  final blake2b =
      Blake2bDigest(digestSize: 32, personalization: personalization);
  blake2b.update(pubKey, 0, pubKey.length);
  final hash = Uint8List(blake2b.digestSize);
  blake2b.doFinal(hash, 0);
  return hash.sublist(0, 20);
}

/// Generates Ckb long address by mnemonic or privateKey
String generateAddress(dynamic arg,
    {String hashType = Script.Type, String addressType = AddressType.LONG}) {
  Uint8List pubKey;
  if (arg.runtimeType == String) {
    pubKey = mnemonicToPubKey(arg);
  } else if (arg.length > 0) {
    pubKey = privateKeyToPubKey(Uint8List.fromList(arg));
  } else {
    throw ArgumentError('Only support mnemonic(String) and privatekey(List)');
  }
  final hash = pubKeyToArg(pubKey);
  switch (addressType) {
    case AddressType.LONG:
      final address = argToLongAddress(hash);
      addressToScript(address);
      return address;
    case AddressType.SHORT:
      final address = argToShortAddress(hash);
      addressToScript(address, type: AddressType.SHORT);
      return address;
    default:
      throw ArgumentError('Unsupported address type');
  }
}

/// Generates Ckb long address from short address
String shortAddressToLongAddress(String shortAddress) {
  final script = addressToScript(shortAddress, type: AddressType.SHORT);
  return argToLongAddress(Uint8List.fromList(hex.decode(script.arg!)));
}

String argToShortAddress(Uint8List hash) {
  List<int> data = [];
  data.add(0x01);
  data.add(SHORT_ID);
  data.addAll(hash);
  final words = convertBits(data, 8, 5);
  return bech32.encode(Bech32(PREFIX, words), maxLength: MAX_LENGTH);
}

String argToLongAddress(Uint8List hash, {String hashType = Script.Type}) {
  List<int> data = [];
  data.add(0x00);
  data.addAll(hex.decode(CKB_CODE_HASH));
  data.add(hashTypeToCode(hashType));
  data.addAll(hash);
  final words = convertBits(data, 8, 5);
  return bech32.encode(Bech32(PREFIX, words),
      maxLength: MAX_LENGTH, encoding: 'bech32m');
}

int hashTypeToCode(String hashType) {
  if (hashType == "data") return 0;
  if (hashType == "type") return 1;
  if (hashType == "data1") return 2;
  throw ArgumentError('Unsupported hash type');
}

String codeToHashType(int code) {
  if (code == 0) return "data";
  if (code == 1) return "type";
  if (code == 2) return "data1";
  throw ArgumentError('Unsupported hash type');
}

Script addressToScript(address, {String type = AddressType.LONG}) {
  switch (type) {
    case AddressType.LONG:
      // 1,32,1,20
      final bechDecode =
          bech32.decode(address, maxLength: MAX_LENGTH, encoding: 'bech32m');
      final data = convertBits(bechDecode.data, 5, 8);
      final codeHash = hex.encode(data.sublist(1, 33));
      if (bechDecode.hrp != PREFIX || codeHash != CKB_CODE_HASH) {
        throw ArgumentError('address error');
      }
      final hashType = codeToHashType(data.sublist(33, 34).first);
      final arg = hex.encode(data.sublist(34, 54));
      return new Script(hashType: hashType, arg: arg, codeHash: codeHash);
    case AddressType.SHORT:
      // 1,1,20
      final bechDecode = bech32.decode(address, maxLength: MAX_LENGTH);
      final data = convertBits(bechDecode.data, 5, 8);
      if (bechDecode.hrp != PREFIX || data[1] != SHORT_ID) {
        throw ArgumentError('address error');
      }
      final arg = hex.encode(data.sublist(2, 22));
      return new Script(
          hashType: Script.Type, arg: arg, codeHash: CKB_CODE_HASH);
    default:
      throw ArgumentError('Unsupported address type');
  }
}

class Script {
  static const String Data = 'data';
  static const String Type = 'type';

  String? codeHash;
  String? arg;
  String? hashType;

  Script({this.codeHash, this.hashType, this.arg});
}

class AddressType{
  static const String LONG = 'long';
  static const String SHORT = 'short';
}

// /// pure Ed25519 signature
// SignedMessage suiSignatureFromSeed(Uint8List message, Uint8List privateKey) {
//   SigningKey signingKey = generateNewPairKeyBySeed(privateKey);
//   return signingKey.sign(message);
// }

// bool suiVerifySignedMessage(Uint8List publicKey, SignedMessage signedMessage) {
//   VerifyKey verifyKey = new VerifyKey(Uint8List.fromList(publicKey));
//   return verifyKey.verify(
//       signature: signedMessage.signature,
//       message: Uint8List.fromList(signedMessage.message));
// }
