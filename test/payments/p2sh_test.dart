import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:hex/hex.dart';

import 'package:bitcoin_flutter/src/payments/p2sh.dart';
import 'package:bitcoin_flutter/src/payments/index.dart';
import 'package:bitcoin_flutter/src/utils/script.dart' as bscript;

main() {
  final fixtures = json.decode(
      new File("./test/fixtures/p2sh.json").readAsStringSync(encoding: utf8));

  group('(valid case)', () {
    (fixtures["valid"] as List<dynamic>).forEach((f) {
      test(f['description'] + ' as expected', () {
        final arguments = _preformPaymentData(f['arguments']);
        final p2sh = new P2SH(data: arguments);
        assert(p2sh.data.name == 'p2sh');
      });
    });
  });
}

PaymentData _preformPaymentData(dynamic x) {
  final address = x['address'];
  final hash =
      x['hash'] != null ? Uint8List.fromList(HEX.decode(x['hash'])) : null;
  final input = x['input'] != null ? bscript.fromASM(x['input']) : null;
  final output = x['output'] != null
      ? bscript.fromASM(x['output'])
      : x['outputHex'] != null
          ? Uint8List.fromList(HEX.decode(x['outputHex']))
          : null;
  final pubkey =
      x['pubkey'] != null ? Uint8List.fromList(HEX.decode(x['pubkey'])) : null;
  final signature = x['signature'] != null
      ? Uint8List.fromList(HEX.decode(x['signature']))
      : null;
  final redeem = x['redeem'] != null ? _dataFromRedeem(x['redeem']) : null;
  return new PaymentData(
      address: address,
      hash: hash,
      input: input,
      output: output,
      pubkey: pubkey,
      signature: signature,
      redeem: redeem);
}

PaymentData _dataFromRedeem(dynamic x) {
  final address = x['address'];
  final hash =
      x['hash'] != null ? Uint8List.fromList(HEX.decode(x['hash'])) : null;
  final input = x['input'] != null ? bscript.fromASM(x['input']) : null;
  final output = x['output'] != null
      ? bscript.fromASM(x['output'])
      : x['outputHex'] != null
          ? Uint8List.fromList(HEX.decode(x['outputHex']))
          : null;
  final pubkey =
      x['pubkey'] != null ? Uint8List.fromList(HEX.decode(x['pubkey'])) : null;
  final signature = x['signature'] != null
      ? Uint8List.fromList(HEX.decode(x['signature']))
      : null;
  final redeem = x['redeem'] != null ? new PaymentData() : null;
  return new PaymentData(
      address: address,
      hash: hash,
      input: input,
      output: output,
      pubkey: pubkey,
      signature: signature,
      redeem: redeem);
}

