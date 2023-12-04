import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:bitcoin_flutter/src/utils/blake2b.dart';
import 'package:bitcoin_flutter/src/utils/check_types.dart';
import 'package:bitcoin_flutter/src/utils/common.dart';
import 'package:bitcoin_flutter/src/utils/push_data.dart';
import 'package:bitcoin_flutter/src/utils/varuint.dart' as varuint;
import 'package:bitcoin_flutter/src/utils/script.dart';

main() {
  group('Blake2b', () {
    test('digest', () {
      Uint8List data = Uint8List(32);
      final result = Blake2b.digest(data, 32, key: data);
      expect(result.length, 32);
    });
  });

  group('check_types', () {
    test('isHash160bit', () {
      Uint8List data = Uint8List(20);
      assert(isHash160bit(data));
    });
  });

  group('common', () {
    test('convertBit', () {
      Uint8List data = Uint8List(20);
      final result = convertBit(data);
      expect(result.length, 33);
    });
  });

  group('push_data', () {
    const offset = 0;
    Uint8List data = Uint8List(32);
    test('8bit', () {
      const number = 0xf1;
      final result = encode(data, number, offset);
      expect(result.size, 2);
      final decodeResult = decode(result.buffer as Uint8List, offset);
      expect(decodeResult!.size, 2);
    });
    test('16bit', () {
      const number = 0xfff1;
      final result = encode(data, number, offset);
      expect(result.size, 3);
      final decodeResult = decode(result.buffer as Uint8List, offset);
      expect(decodeResult!.size, 3);
    });
    test('32bit', () {
      const number = 0xfffff;
      final result = encode(data, number, offset);
      expect(result.size, 5);
      final decodeResult = decode(result.buffer as Uint8List, offset);
      expect(decodeResult!.size, 5);
    });
  });

  group('varuint', () {
    const offset = 0;
    Uint8List data = Uint8List(32);
    test('8bit', () {
      const number = 0xf1;
      final result = varuint.encode(number, data, offset);
      expect(result.length, 32);
      final decodeResult = varuint.decode(result, offset);
      expect(decodeResult, 241);
    });
    test('16bit', () {
      const number = 0xfff1;
      final result = varuint.encode(number, data, offset);
      expect(result.length, 32);
      final decodeResult = varuint.decode(result, offset);
      expect(decodeResult, 65521);
    });
    test('32bit', () {
      const number = 0xfffff;
      final result = varuint.encode(number, data, offset);
      expect(result.length, 32);
      final decodeResult = varuint.decode(result, offset);
      expect(decodeResult, 1048575);
    });

    test('64bit', () {
      const number = 0xffffffff1;
      final result = varuint.encode(number, data, offset);
      expect(result.length, 32);
      final decodeResult = varuint.decode(result, offset);
      expect(decodeResult, 68719476721);
    });

    test('readUInt64LE', () {
      final bytes = ByteData(32);
      final result = varuint.readUInt64LE(bytes, offset);
      expect(result, 0);
    });

    test('writeUInt64LE', () {
      final bytes = ByteData(32);
      final result = varuint.writeUInt64LE(bytes, offset, 0);
      expect(result, 8);
    });
  });

  group('script', () {
    test('OPS', () {
      dynamic result = REVERSE_OPS[0];
      expect(result, 'OP_FALSE');
      result = OP_INT_BASE;
      expect(result, 80);
      assert(isOPInt(0x4f));
    });

    test('base32Decode', () {
      final result = base32Decode('0000000000000000');
      expect(result.length, 16);
    });

    test('toXOnly', () {
      final result = toXOnly(Uint8List(32));
      expect(result.length, 32);
    });

    test('toUint5Array', () {
      final result = toUint5Array(Uint8List(32));
      expect(result.length, 52);
    });

    test('getHashSizeBits', () {
      var result = getHashSizeBits(Uint8List(24));
      expect(result, 1);
      result = getHashSizeBits(Uint8List(28));
      expect(result, 2);
      result = getHashSizeBits(Uint8List(32));
      expect(result, 3);
      result = getHashSizeBits(Uint8List(40));
      expect(result, 4);
      result = getHashSizeBits(Uint8List(48));
      expect(result, 5);
      result = getHashSizeBits(Uint8List(56));
      expect(result, 6);
      result = getHashSizeBits(Uint8List(64));
      expect(result, 7);
      try {
        getHashSizeBits(Uint8List(15));
      } catch (error) {}
    });

    test('toASM', () {
      var result = toASM(Uint8List(1));
      expect(result, 'OP_FALSE');
    });
  });
}
