import 'dart:typed_data';

import 'package:bitcoin_flutter/src/utils/script.dart';
import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:pointycastle/export.dart';

import 'package:bitcoin_flutter/src/base58.dart';
import 'package:bitcoin_flutter/src/bip32/bip32.dart';
import 'package:bitcoin_flutter/src/models/networks.dart';
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:bitcoin_flutter/src/payments/p2pkh.dart';
import 'package:bitcoin_flutter/src/payments/p2sh.dart';
import 'package:bitcoin_flutter/src/payments/p2wpkh.dart';
import 'package:bitcoin_flutter/src/utils/constants/constants.dart';

final _domainParams = ECCurve_secp256k1();

class Address {
  static bool validateAddress(String address, [NetworkType? nw]) {
    try {
      addressToOutputScript(address, nw);
      return true;
    } catch (err) {
      return false;
    }
  }

  static Uint8List? addressToOutputScript(String address, [NetworkType? nw]) {
    var network = nw ?? bitcoin;
    var decodeBase58;
    var decodeBech32;
    try {
      decodeBase58 = bs58check.decode(address);
    } catch (err) {
      // Base58check decode fail
    }
    if (decodeBase58 != null) {
      if (decodeBase58[0] == network.pubKeyHash) return P2PKH(data: PaymentData(address: address), network: network).data.output;
      if (decodeBase58[0] == network.scriptHash) return P2SH(data: PaymentData(address: address), network: network).data.output;

      throw ArgumentError('Invalid version or Network mismatch');
    } else {
      if (decodeBech32 != null) {
        if (network.bech32 != decodeBech32.hrp) throw ArgumentError('Invalid prefix or Network mismatch');
        if (decodeBech32.version != 0) throw ArgumentError('Invalid address version');

        var p2wpkh = P2WPKH(data: PaymentData(address: address), network: network);
        return p2wpkh.data.output;
      }
    }
    throw ArgumentError('$address has no matching Script');
  }

  static String createExtendedAddress(Uint8List seed, {String? path, List<int>? prefix}) {
    if (path == null) path = "m/44'/195'/0'/0/0";
    if (prefix == null) prefix = xprv;

    final root = ExtendedPrivateKey.master(seed, prefix);
    final r = root.forPath(path);

    final q = _domainParams.G * (r as ExtendedPrivateKey).key;

    final publicParams = ECPublicKey(q, _domainParams);
    final pk = publicParams.Q!.getEncoded(false);

    final input = Uint8List.fromList(pk.skip(1).toList());

    final digest = KeccakDigest(256);
    final result = Uint8List(digest.digestSize);
    digest.update(input, 0, input.length);
    digest.doFinal(result, 0);

    final addr = result.skip(result.length - 20).toList();
    return Base58CheckCodec.bitcoin().encode(Base58CheckPayload(0x41, addr));
  }

  static String bchToLegacy(String addr) {
    final payload = base32Decode(addr.split(':')[1]);
    final hash = convertBits(payload.sublist(0, 34), 5, 8, strictMode: true);
    return bs58check.encode(Uint8List.fromList(hash));
  }
}
