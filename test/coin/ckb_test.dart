import 'package:test/test.dart';
import 'package:convert/convert.dart' show hex;

import 'package:bitcoin_flutter/src/coin/ckb.dart' as ckb;

void main() {
  const String TEST_MNEMONIC =
      'fly lecture gasp juice hover ice business census bless weapon polar upgrade';
  group('test ckb address by mnemonic 12', () {
    late final shortAddress;
    late final longAddress;

    test('long', () {
      longAddress = ckb.generateAddress(TEST_MNEMONIC);
      expect(longAddress,
          'ckb1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsqg22jte2zg5a457d9hdfq7ss499ygz63ycxv2rt3');
    });
    test('short', () {
      shortAddress = ckb.generateAddress(TEST_MNEMONIC, addressType: 'short');
      expect(shortAddress, 'ckb1qyqq54yhj5y3fmtfu6tw6jpapp222gs94zfsns98e7');
    });

    test('short to long', () {
      final address = ckb.shortAddressToLongAddress(shortAddress);
      expect(address, longAddress);
    });
  });
  group('test ckb address transfer', () {
    final pubKey = ckb.mnemonicToPubKey(TEST_MNEMONIC);
    final arg = ckb.pubKeyToArg(pubKey);
    test('long', () {
      final long = ckb.generateAddress(TEST_MNEMONIC);
      final script = ckb.addressToScript(long);
      expect(script.arg, hex.encode(arg));
    });
    ckb.Script script;
    test('short', () {
      final short = ckb.generateAddress(TEST_MNEMONIC, addressType: 'short');
      final script = ckb.addressToScript(short, type: 'short');
      expect(script.arg, hex.encode(arg));
    });
  });
}
