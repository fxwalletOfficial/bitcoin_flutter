import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:test/test.dart';

import 'package:bitcoin_flutter/bitcoin_flutter.dart';

void main() {
  group('bitcoin-dart (HDWallet)', () {
    final seed = bip39.mnemonicToSeed('praise you muffin lion enable neck grocery crumble super myself license ghost');
    HDWallet hdWallet = new HDWallet.fromSeed(seed);
    test('valid seed', () {
      expect(hdWallet.seed, 'f4f0cda65a9068e308fad4c96e8fe22213dd535fe7a7e91ca70c162a38a49aaacfe0dde5fafbbdf63cf783c2619db7174bc25cbfff574fb7037b1b9cec3d09b6');
    });
    test('valid address', () {
      expect(hdWallet.address, '12eUJoaWBENQ3tNZE52ZQaHqr3v4tTX4os');
      expect(hdWallet.bchAddress, 'bitcoincash:qqfqunapm906na48tq079cn8w9gzp0p00uz2rpc243');
    });
    test('valid public key', () {
      expect(hdWallet.base58, 'xpub661MyMwAqRbcGhVeaVfEBA25e3cP9DsJQZoE8iep5fZSxy3TnPBNBgWnMZx56oreNc48ZoTkQfatNJ9VWnQ7ZcLZcVStpaXLTeG8bGrzX3n');
    });
    test('valid private key', () {
      expect(hdWallet.base58Priv, 'xprv9s21ZrQH143K4DRBUU8Dp25M61mtjm9T3LsdLLFCXL2U6AiKEqs7dtCJWGFcDJ9DtHpdwwmoqLgzPrW7unpwUyL49FZvut9xUzpNB6wbEnz');
    });
    test('sign/verify message', () {
      final msg = '00000000';
      final signature = 'd3c8c685d503f75e6ebdcf0831757453e2e4c5e5589e8f559131d3dbb346cb033f905253681c260f18f5293d77e82ddc72c5edf98cfeaf4f2d417ee8dff792d5';

      expect(HEX.encode(hdWallet.sign(msg)!), signature);
      expect(hdWallet.verify(message: msg, signature: Uint8List.fromList(HEX.decode(signature))), true);
    });
  });
}
