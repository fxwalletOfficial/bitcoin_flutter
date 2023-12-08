import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart' show hex;
import 'package:pointycastle/ecc/curves/secp256k1.dart';

class CellDep {
  static const String Code = 'code';
  static const String DepGroup = 'dep_group';

  OutPoint? outPoint;
  String depType;

  CellDep({this.outPoint, this.depType = Code});

  factory CellDep.fromJson(Map<String, dynamic> json) {
    return CellDep(
        outPoint: OutPoint.fromJson(json['out_point']),
        depType: json['dep_type']);
  }
}

class OutPoint {
  String? txHash;
  String? index;

  OutPoint({this.txHash, this.index});

  factory OutPoint.fromJson(Map<String, dynamic> json) {
    return OutPoint(txHash: json['tx_hash'], index: json['index']);
  }
}

class CellInput {
  OutPoint? previousOutput;
  String? since;

  CellInput({this.previousOutput, this.since});

  factory CellInput.fromJson(Map<String, dynamic> json) {
    return CellInput(
        previousOutput: OutPoint.fromJson(json['previous_output']),
        since: json['since']);
  }
}

class CellOutput {
  String? capacity;
  Script? lock;
  Script? type;

  CellOutput({this.capacity, this.lock, this.type});

  factory CellOutput.fromJson(Map<String, dynamic> json) {
    return CellOutput(
        capacity: json['capacity'],
        lock: Script.fromJson(json['lock']),
        type: json['type'] == null ? null : Script.fromJson(json['type']));
  }
}

class Script {
  static const String Data = 'data';
  static const String Type = 'type';

  String? codeHash;
  String? args;
  String hashType;

  Script({this.codeHash, this.args, this.hashType = Data});

  factory Script.fromJson(Map<String, dynamic> json) {
    return Script(
        codeHash: json['code_hash'],
        args: json['args'],
        hashType: json['hash_type']);
  }

  String toJson() {
    return jsonEncode(
        {'code_hash': codeHash, 'args': args, 'hash_type': hashType});
  }

  int calculateByteSize() {
    var byteSize = 1;
    byteSize += codeHash == null ? 0 : hexToList(codeHash!).length;
    if (args == null || args!.isEmpty) {
      return byteSize;
    }
    byteSize += hexToList(args!).length;
    return byteSize;
  }
}

class Witness {
  static final String SIGNATURE_PLACEHOLDER = '0' * 130;

  String? lock;
  String? inputType;
  String? outputType;

  Witness({this.lock, this.inputType, this.outputType});
}

class ScriptGroup {
  List<int> inputIndexes;

  ScriptGroup(this.inputIndexes);
}

abstract class SerializeType<T> {
  Uint8List toBytes();
  T getValue();
  int getLength();
}

abstract class FixedType<T> implements SerializeType<T> {}

abstract class DynType<T> implements SerializeType<T> {}

class Byte1 extends FixedType<Uint8List> {
  Uint8List _value;

  Byte1(this._value);

  factory Byte1.fromHex(String hex) {
    return Byte1(hexToList(hex));
  }

  @override
  int getLength() {
    return 1;
  }

  @override
  Uint8List getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return _value;
  }
}

class Byte32 extends FixedType<Uint8List> {
  Uint8List? _value;

  Byte32(Uint8List value) {
    if (value.length != 32) {
      throw ('Byte32 length error');
    }
    _value = value;
  }

  factory Byte32.fromHex(String hex) {
    var list = hexToList(hex);
    if (list.length > 32) {
      throw ('Byte32 length error');
    } else if (list.length < 32) {
      var bytes = Uint8List(32);
      for (var i = 0; i < list.length; i++) {
        bytes[i] = list[i];
      }
      return Byte32(bytes);
    }
    return Byte32(list);
  }

  @override
  int getLength() {
    return 32;
  }

  @override
  Uint8List getValue() {
    return _value!;
  }

  @override
  Uint8List toBytes() {
    return _value!;
  }
}

class Empty extends FixedType {
  @override
  int getLength() {
    return 0;
  }

  @override
  void getValue() {
    return null;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList(<int>[]);
  }
}

class EmptySerializeType implements SerializeType<dynamic> {
  @override
  int getLength() {
    return 0;
  }

  @override
  void getValue() {
    return null;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList(<int>[]);
  }
}

class Fixed<T extends FixedType> implements SerializeType<List<T>> {
  final List<T> _value;

  Fixed(this._value);

  @override
  int getLength() {
    var length = UInt32.byteSize;
    for (SerializeType type in _value) {
      length += type.getLength();
    }
    return length;
  }

  @override
  List<T> getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    var dest = [...UInt32(_value.length).toBytes()];
    for (var type in _value) {
      dest.addAll(type.toBytes());
    }
    return Uint8List.fromList(dest);
  }
}

class Struct extends FixedType<List<SerializeType>> {
  final List<SerializeType> _value;

  Struct(this._value);

  @override
  int getLength() {
    var length = 0;
    for (var type in _value) {
      length += type.getLength();
    }
    return length;
  }

  @override
  List<SerializeType> getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    var dest = <int>[];
    for (var type in _value) {
      dest.addAll(type.toBytes());
    }
    return Uint8List.fromList(dest);
  }
}

class UInt32 extends FixedType<int> {
  static final int byteSize = 4;

  int _value;

  UInt32(this._value);

  factory UInt32.fromHex(String hex) =>
      UInt32(BigInt.parse(cleanHexPrefix(hex), radix: 16).toInt());

  // generate int value from little endian bytes
  factory UInt32.fromBytes(Uint8List bytes) {
    var result = 0;
    for (var i = 3; i >= 0; i--) {
      result += (bytes[i] & 0xff) << 8 * i;
    }
    return UInt32(result);
  }

  @override
  int getLength() {
    return byteSize;
  }

  @override
  int getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList(
        <int>[_value, _value >> 8, _value >> 16, _value >> 24]);
  }
}

class UInt64 extends FixedType<BigInt> {
  BigInt _value;

  UInt64(this._value);

  factory UInt64.fromInt(int value) {
    return UInt64(BigInt.from(value));
  }

  factory UInt64.fromHex(String hex) {
    try {
      return UInt64(BigInt.parse(cleanHexPrefix(hex), radix: 16));
    } catch (error) {
      return UInt64(BigInt.from(0));
    }
  }

  // generate int value from little endian bytes
  factory UInt64.fromBytes(Uint8List bytes) {
    var result = 0;
    for (var i = 7; i >= 0; i--) {
      result += (bytes[i] & 0xff) << 8 * i;
    }
    return UInt64.fromInt(result);
  }

  @override
  int getLength() {
    return 8;
  }

  @override
  BigInt getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList([]
      ..add(_value.toInt())
      ..add((_value >> 8).toInt())
      ..add((_value >> 16).toInt())
      ..add((_value >> 24).toInt())
      ..add((_value >> 32).toInt())
      ..add((_value >> 40).toInt())
      ..add((_value >> 48).toInt())
      ..add((_value >> 56).toInt()));
  }
}

class Table extends SerializeType<List<SerializeType>> {
  final List<SerializeType> _value;

  Table(this._value);

  @override
  int getLength() {
    var length = (1 + _value.length) * UInt32.byteSize;
    for (var type in _value) {
      length += type.getLength();
    }
    return length;
  }

  @override
  List<SerializeType> getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    var dest = [...UInt32(getLength()).toBytes()];

    var typeOffset = UInt32.byteSize * (1 + _value.length);

    for (var type in _value) {
      dest.addAll(UInt32(typeOffset).toBytes());
      typeOffset += type.getLength();
    }

    for (var type in _value) {
      dest.addAll(type.toBytes());
    }

    return Uint8List.fromList(dest);
  }
}

class Option extends DynType<SerializeType> {
  final SerializeType _value;

  Option(this._value);

  @override
  int getLength() {
    return _value.getLength();
  }

  @override
  SerializeType getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return _value.toBytes();
  }
}

class Dynamic<T extends SerializeType> implements SerializeType<List<T>> {
  final List<T> _value;

  Dynamic(this._value);

  @override
  int getLength() {
    var length = (1 + _value.length) * UInt32.byteSize;
    for (SerializeType type in _value) {
      length += type.getLength();
    }
    return length;
  }

  @override
  List<T> getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    var dest = [...UInt32(getLength()).toBytes()];

    var typeOffset = UInt32.byteSize * (1 + _value.length);

    for (var type in _value) {
      dest.addAll(UInt32(typeOffset).toBytes());
      typeOffset += type.getLength();
    }

    for (var type in _value) {
      dest.addAll(type.toBytes());
    }

    return Uint8List.fromList(dest);
  }
}

class Bytes extends DynType<Uint8List> {
  Uint8List _value;

  Bytes(this._value);

  factory Bytes.fromHex(String hex) => Bytes(hexToList(hex));

  @override
  int getLength() {
    return _value.length + UInt32.byteSize;
  }

  @override
  Uint8List getValue() {
    return _value;
  }

  @override
  Uint8List toBytes() {
    return Uint8List.fromList([...UInt32(_value.length).toBytes(), ..._value]);
  }
}

class EcdaSignature {
  final Uint8List r;
  final Uint8List s;
  final int v;

  EcdaSignature(this.r, this.s, this.v);

  Uint8List getSignature() {
    var dest = Uint8List(65);
    List.copyRange(dest, 0, r);
    List.copyRange(dest, 32, s);
    dest[64] = v;
    return dest;
  }

  String getSignatureString() {
    return listToHex(getSignature());
  }
}

Uint8List hexToList(String hexString) {
  return Uint8List.fromList(hex.decode(cleanHexPrefix(toWholeHex(hexString))));
}

String cleanHexPrefix(String hex) {
  return hex.startsWith('0x') ? hex.substring(2) : hex;
}

String toWholeHex(String hexString) {
  var hex = cleanHexPrefix(hexString);
  var wholeHex = hex.length % 2 == 0 ? hex : '0$hex';
  return appendHexPrefix(wholeHex);
}

String appendHexPrefix(String hex) {
  return hex.startsWith('0x') ? hex : '0x$hex';
}

String listToHex(Uint8List bytes) {
  return appendHexPrefix(listToHexNoPrefix(bytes));
}

String listToHexNoPrefix(Uint8List bytes) {
  return hex.encode(bytes);
}

String toHexString(String value) {
  if (value.startsWith('0x')) return value;
  try {
    return appendHexPrefix(BigInt.parse(value).toRadixString(16));
  } catch (error) {
    throw ('Input value format error, please input integer or hex string');
  }
}

BigInt hexToBigInt(String hex) {
  return BigInt.parse(cleanHexPrefix(hex), radix: 16);
}

List<int> toBytesPadded(BigInt value, int length) {
  List<int> bytes = bigIntToList(value);
  if (bytes.length > length) {
    throw ('Input is too large to put in byte array of size ${length.toString()}');
  }
  var result = List<int>.filled(length, 0);
  var offset = length - bytes.length;
  for (var i = 0; i < length; i++) {
    result[i] = i < offset ? 0 : bytes[i - offset];
  }
  return result;
}

Uint8List bigIntToList(BigInt value) {
  return encodeBigInt(value);
  // return utils.encodeBigInt(value);
}

BigInt listToBigInt(Uint8List bytes) {
  return decodeBigInt(bytes);
  // return utils.decodeBigInt(bytes);
}

BigInt decodeBigInt(List<int> bytes) {
  BigInt result = new BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result += new BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

var _byteMask = new BigInt.from(0xff);
Uint8List encodeBigInt(BigInt number) {
  // Not handling negative numbers. Decide how you want to do that.
  int size = (number.bitLength + 7) >> 3;
  var result = new Uint8List(size);
  for (int i = 0; i < size; i++) {
    result[size - i - 1] = (number & _byteMask).toInt();
    number = number >> 8;
  }
  return result;
}

String publicKeyFromPrivate(String privateKey, {bool compress = true}) {
  var bigPrivateKey = hexToBigInt(privateKey);
  return listToHexNoPrefix((ECCurve_secp256k1().G * bigPrivateKey)!
      .getEncoded(compress)
      .sublist(compress ? 0 : 1));
}

List<int> regionToList(int start, int length) {
  var integers = <int>[];
  for (var i = start; i < (start + length); i++) {
    integers.add(i);
  }
  return integers;
}
