import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:hex/hex.dart';

import 'package:bitcoin_flutter/src/payments/p2pk.dart';
import 'package:bitcoin_flutter/src/payments/index.dart';
import 'package:bitcoin_flutter/src/utils/script.dart' as bscript;

main() {
  final fixtures = json.decode(
      new File("./test/fixtures/p2pk.json").readAsStringSync(encoding: utf8));

  group('(valid case)', () {
    (fixtures["valid"] as List<dynamic>).forEach((f) {
      test(f['description'] + ' as expected', () {
        final arguments = _preformPaymentData(f['arguments']);
        arguments.toString();
        new P2PK(data: arguments);
        final name = 'name';
        final address = 'address';
        final unit8list = new Uint8List(8);
        final redeem = new PaymentData();
        arguments['name'] = name;
        arguments['address'] = address;
        arguments['hash'] = unit8list;
        arguments['output'] = unit8list;
        arguments['pubkey'] = unit8list;
        arguments['input'] = unit8list;
        arguments['signature'] = unit8list;
        arguments['witness'] = [unit8list];
        arguments['redeem'] = redeem;
        expect(arguments['name'], name);
        expect(arguments['address'], address);
        expect(arguments['hash'], unit8list);
        expect(arguments['output'], unit8list);
        expect(arguments['pubkey'], unit8list);
        expect(arguments['input'], unit8list);
        expect(arguments['signature'], unit8list);
        expect(arguments['witness'].length, 1);
        expect(arguments['redeem'], redeem);
      });
    });
  });

  group('(invalid case)', () {
    (fixtures["invalid"] as List<dynamic>).forEach((f) {
      test(f['description'] + ' as expected', () {
        try {
          final arguments = _preformPaymentData(f['arguments']);
          new P2PK(data: arguments);
        } catch (err) {
          expect(err.toString(), 'Invalid argument(s): Output is invalid');
        }
      });

      test('invalid index', () {
        final arg = new PaymentData();
        try {
          arg['error'] = 'error';
        } catch (err) {
          expect(err.toString(), 'Invalid argument(s): Invalid PaymentData key');
        }
        try {
          print(arg['error']);
        } catch (err) {
          expect(err.toString(), 'Invalid argument(s): Invalid PaymentData key');
        }
      });
    });
  });
}

PaymentData _preformPaymentData(dynamic x) {
  final input = x['input'] != null ? bscript.fromASM(x['input']) : null;
  final output = x['output'] != null
      ? bscript.fromASM(x['output'])
      : x['outputHex'] != null
          ? Uint8List.fromList(HEX.decode(x['outputHex']))
          : null;
  return new PaymentData(input: input, output: output);
}
