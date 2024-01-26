import 'package:test/test.dart';
import 'package:convert/convert.dart' show hex;

import 'package:bitcoin_flutter/bitcoin_flutter.dart';

void main() {
  const String TEST_MNEMONIC =
      'what ordinary shop frame olympic dove economy define extra unable oyster emerge';
  group('test sc', () {
    test('address by mnemonic 12', () {
      final publicKey = Sc.mnemonicToPublicKey(TEST_MNEMONIC);

      expect(hex.encode(publicKey),
          '98e216d25ab3984063d19daedd6bb65925753b70bc486e8bdd127544a74614fa');
      final address = Sc.publicKeyToAddress(publicKey);
      expect(address,
          'c299740ac5c6177c280eebe1b77d9009438cbc75dae6f405ecbc262d31cffb4d77061bf783f1');
    });
  });
}
