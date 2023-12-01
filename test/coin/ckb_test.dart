import 'package:test/test.dart';
import 'package:convert/convert.dart' show hex;

import 'package:bitcoin_flutter/src/coin/ckb.dart' as ckb;

import 'package:bitcoin_flutter/src/coin/ckbDep/data_type.dart';
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
      const privateKey =
          '0xae236ca02ca5169bc8e1f865e6bc59be636d830f23a6a28cbbb2d1202202552f';
      final txHash1 =
          "0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c";
      final txHash2 =
          "0x093e33bdd262ed70643189021e761d427a11ba7300e6aa177707b01f45665ea8";
      final arg = '0x0a5497950914ed69e696ed483d0854a52205a893';
      final outpoint1 = new OutPoint(txHash: txHash1, index: '0x0');
      final outpoint2 = new OutPoint(txHash: txHash2, index: '0x0');
      final outpoint3 = new OutPoint(txHash: txHash2, index: '0x1');

      final input1 = new CellInput(previousOutput: outpoint2, since: '0x0');
      final input2 = new CellInput(previousOutput: outpoint3, since: '0x0');

      final script = new Script(
          codeHash: ckb.CKB_CODE_HASH, hashType: Script.Type, args: arg);
      final capacity1 = '0x1718c7e00';
      final capacity2 = '0x2caecf9240';
      final output1 =
          new CellOutput(capacity: capacity1, lock: script, type: null);
      final output2 =
          new CellOutput(capacity: capacity2, lock: script, type: null);

      final witness = Witness(lock: Witness.SIGNATURE_PLACEHOLDER);

      final version = '0x0';
      final cellDeps = <CellDep>[
        new CellDep(outPoint: outpoint1, depType: 'depGroup')
      ];
      final headerDeps = <String>[];
      final inputs = <CellInput>[input1, input2];
      final outputs = <CellOutput>[output1, output2];
      final outputsData = <String>['0x', '0x'];
      final witnesses = [witness, '0x'];

      ckbTx.CKBTransaction tx = new ckbTx.CKBTransaction(
          version: version,
          cellDeps: cellDeps,
          headerDeps: headerDeps,
          inputs: inputs,
          outputs: outputs,
          outputsData: outputsData,
          witnesses: witnesses);
      final result = ckb.signTx(tx, privateKey);
      expect(result.witnesses, [
        '0x5500000010000000550000005500000041000000f434e961907533ad999daa7cd6de1aead0232a72be562bd5fa043f64f260fd337d8963799cd802502c178008b99222b265116e137c74359cf678c014361cf1f400',
        '0x'
      ]);
    });
  });
}
