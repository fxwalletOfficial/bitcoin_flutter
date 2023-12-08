import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:convert/convert.dart' show hex;

import 'package:bitcoin_flutter/src/coin/ckb.dart' as ckb;
import 'package:bitcoin_flutter/src/coin/ckbDep/transition.dart' as ckbTx;

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
      expect(script.args, hex.encode(arg));
    });
    test('short', () {
      final short = ckb.generateAddress(TEST_MNEMONIC, addressType: 'short');
      final script = ckb.addressToScript(short, type: 'short');
      expect(script.args, hex.encode(arg));
    });
  });

  group('sign', () {
    test('test', () {
      final transactionJson = json.decode(
          new File('./test/coin/ckb_transaction.json')
              .readAsStringSync(encoding: utf8));

      const privateKey =
          '0xae236ca02ca5169bc8e1f865e6bc59be636d830f23a6a28cbbb2d1202202552f';
      ckbTx.CKBTransaction tx = ckbTx.CKBTransaction.fromJson(transactionJson);
      tx.toJson();
      final result = ckb.signTx(tx, privateKey);
      expect(result.witnesses, [
        '0x5500000010000000550000005500000041000000f434e961907533ad999daa7cd6de1aead0232a72be562bd5fa043f64f260fd337d8963799cd802502c178008b99222b265116e137c74359cf678c014361cf1f400',
        '0x'
      ]);
    });
  });

  group('supplementary test ', () {
    const privateKey =
        'ae236ca02ca5169bc8e1f865e6bc59be636d830f23a6a28cbbb2d1202202552f';
    test('private key to address', () {
      final address = ckb.generateAddress(hex.decode(privateKey));
      expect(address,
          'ckb1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsq0unch4maers5jzeag4d0vln2zmd3sc9ss7r6xu0');
    });

    test('error', () {
      try {
        ckb.generateAddress(hex.decode(privateKey), addressType: 'error');
      } catch (error) {
        expect(
            error.toString(), 'Invalid argument(s): Unsupported address type');
      }

      try {
        ckb.hashTypeToCode('data1');
        ckb.hashTypeToCode('hashType');
      } catch (error) {
        expect(
            error.toString(), 'Invalid argument(s): Unsupported hash type');
      }

      try {
        ckb.codeToHashType(2);
        ckb.codeToHashType(3);
      } catch (error) {
        expect(
            error.toString(), 'Invalid argument(s): Unsupported hash type');
      }
    });
  });
}
