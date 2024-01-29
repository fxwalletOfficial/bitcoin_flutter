import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:convert/convert.dart' show hex;

import 'package:bitcoin_flutter/bitcoin_flutter.dart';

void main() {
  const String TEST_MNEMONIC =
      'what ordinary shop frame olympic dove economy define extra unable oyster emerge';
  const msg =
      '4122984cda164a97d0e2ad8e7e52aeed95becd36baa454f94f88c767bc203a76';
  const signatureTarget =
      '5hrIALiI7u9YVU1ooOnnQrQTbQyKfG2s/6oIbBiv/eY42A9d/oTf1Tk+RaGbf7WeG3do0bIUJCUnCOzQfH76Dw==';
  group('test sc', () {
    test('address by mnemonic 12', () {
      final publicKey = Sc.mnemonicToPublicKey(TEST_MNEMONIC);

      expect(hex.encode(publicKey),
          '98e216d25ab3984063d19daedd6bb65925753b70bc486e8bdd127544a74614fa');
      final address = Sc.publicKeyToAddress(publicKey);
      expect(address,
          'c299740ac5c6177c280eebe1b77d9009438cbc75dae6f405ecbc262d31cffb4d77061bf783f1');
    });

    test('sign', () {
      final message = Uint8List.fromList(hex.decode(msg));
      final privateKey = Sc.mnemonicToPrivateKey(TEST_MNEMONIC);
      final signature = Sc.signMessage(message, privateKey);
      expect(signature, signatureTarget);
    });

    test('sign messages', () {
      const signatureTargets = [
        '5hrIALiI7u9YVU1ooOnnQrQTbQyKfG2s/6oIbBiv/eY42A9d/oTf1Tk+RaGbf7WeG3do0bIUJCUnCOzQfH76Dw=='
      ];
      final privateKey = Sc.mnemonicToPrivateKey(TEST_MNEMONIC);
      final inputJson = json.decode(new File('./test/coin/sc_transaction.json')
          .readAsStringSync(encoding: utf8));
      final inputData = inputJson['input_data'];
      final List<scInputData> inputs = [];
      for (final data in inputData) {
        inputs.add(scInputData.fromJson(data));
      }
      List<ScSignature> transactionSignatures =
          Sc.signMessages(inputs, privateKey);
      for (var i=0;i<transactionSignatures.length;i++) {
        expect(transactionSignatures[i].signature, signatureTargets[i]);
      }
    });
  });
}
