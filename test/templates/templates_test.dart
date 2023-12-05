import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:bitcoin_flutter/src/templates/scriptHash.dart';
import 'package:bitcoin_flutter/src/templates/pubkey.dart' as pubKey;

main() {
  group('scriptHash', () {
    test('inputCheck', () {
      List data1 = [0, 0, 0];
      var result = inputCheck(data1, true);
      assert(!result);
      final data2 = [0, 0, 0, Uint8List(23)];
      result = inputCheck(data2, true);
      assert(!result);
    });

    test('outputCheck', () {
      List<int> data = List.filled(23, 0);
      data[0] = 0xa9;
      data[1] = 0x14;
      final result = outputCheck(Uint8List.fromList(data));
      assert(!result);
    });
  });

  group('pubkey', () {
    test('outputCheck', () {
      Uint8List data = Uint8List(23);
      final result = pubKey.outputCheck(Uint8List.fromList(data));
      assert(!result);
    });
  });
}
