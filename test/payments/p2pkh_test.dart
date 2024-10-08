import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hex/hex.dart';
import 'package:test/test.dart';

import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:bitcoin_flutter/src/payments/p2pkh.dart';
import 'package:bitcoin_flutter/src/utils/script.dart' as bscript;

main() {
  final fixtures = json.decode(new File("./test/fixtures/p2pkh.json").readAsStringSync(encoding: utf8));
  group('(valid case)', () {
    (fixtures["valid"] as List<dynamic>).forEach((f) {
      test(f['description'] + ' as expected', () {
        final arguments = _preformPaymentData(f['arguments']);
        final p2pkh = new P2PKH(data: arguments);

        if (arguments.address == null) expect(p2pkh.data.address, f['expected']['address']);
        if (arguments.hash == null) expect(_toString(p2pkh.data.hash), f['expected']['hash']);
        if (arguments.pubkey == null) expect(_toString(p2pkh.data.pubkey), f['expected']['pubkey']);
        if (arguments.input == null) expect(_toString(p2pkh.data.input), f['expected']['input']);
        if (arguments.output == null) expect(_toString(p2pkh.data.output), f['expected']['output']);
        if (arguments.signature == null) expect(_toString(p2pkh.data.signature), f['expected']['signature']);
      });
    });
  });
  group('(invalid case)', () {
    (fixtures["invalid"] as List<dynamic>).forEach((f) {
      test('throws ' + f['exception'] + (f['description'] != null ? ('for ' + f['description']) : ''), () {
        final arguments = _preformPaymentData(f['arguments']);
        try {
          expect(new P2PKH(data: arguments), isArgumentError);
        } catch (err) {
          expect((err as ArgumentError).message, f['exception']);
        }
      });
    });
  });

  group('Supplementary', () {
    final arguments = _preformPaymentData(fixtures['valid'][4]['arguments']);
    final p2pkh = new P2PKH(data: arguments);
    test('Blake2b', () {
      final result = p2pkh.addressInBlake2b;
      expect(result, 'bc1q5zuhkh08ggg3rqxx0z6uq4xtm7k8e43jd9n0ne');
    });

    test('tapRootAddress', () {
      final result = p2pkh.tapRootAddress;
      expect(result, 'bc1pw3yacwv2cun92ke5g4gmyvzjxclucqx8t6tml7m0tfqjecvqtzkssp5tmu');
    });

    test('bech32Address', () {
      final result = p2pkh.bech32Address;
      expect(result, 'bc1z69ej270c3q9qvgt822t6pm3zdksk2x32ttp2v');
    });
  });
}

PaymentData _preformPaymentData(dynamic x) {
  final address = x['address'];
  final hash = x['hash'] != null ? Uint8List.fromList(HEX.decode(x['hash'])) : null;
  final input = x['input'] != null ? bscript.fromASM(x['input']) : null;
  final output = x['output'] != null ? bscript.fromASM(x['output']) : x['outputHex'] != null ? Uint8List.fromList(HEX.decode(x['outputHex'])) : null;
  final pubkey = x['pubkey'] != null ? Uint8List.fromList(HEX.decode(x['pubkey'])) : null;
  final signature = x['signature'] != null ? Uint8List.fromList(HEX.decode(x['signature'])) : null;
  return new PaymentData(address: address, hash: hash, input: input, output: output, pubkey: pubkey, signature: signature);
}

String? _toString(dynamic x) {
  if (x == null) return null;
  if (x is Uint8List) return HEX.encode(x);
  if (x is List<dynamic>) return bscript.toASM(x);

  return '';
}
