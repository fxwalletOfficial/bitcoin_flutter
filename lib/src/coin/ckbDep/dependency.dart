import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/blake2b.dart';

import 'data_type.dart';
import 'transition.dart';

class Convert {
  static OutPoint parseOutPoint(OutPoint outPoint) {
    return OutPoint(
        txHash: outPoint.txHash, index: toHexString(outPoint.index!));
  }

  static CKBTransaction parseTransaction(CKBTransaction transaction) {
    var cellDeps = transaction.cellDeps!
        .map((cellDep) => CellDep(
            outPoint: parseOutPoint(cellDep.outPoint!),
            depType: cellDep.depType))
        .toList();

    var inputs = transaction.inputs!
        .map((input) => CellInput(
            previousOutput: parseOutPoint(input.previousOutput!),
            since: toHexString(input.since!)))
        .toList();

    var outputs = transaction.outputs!
        .map((output) => CellOutput(
            capacity: toHexString(output.capacity!),
            lock: output.lock,
            type: output.type))
        .toList();

    return CKBTransaction(
        version: toHexString(transaction.version!),
        cellDeps: cellDeps,
        headerDeps: transaction.headerDeps,
        inputs: inputs,
        outputs: outputs,
        outputsData: transaction.outputsData,
        witnesses: transaction.witnesses);
  }
}

class Blake2b {
  String CkbHashPersonalization = 'ckb-default-hash';

  var state;

  Blake2b({int digestSize = 32}) {
    final personalization =
        Uint8List.fromList(utf8.encode(CkbHashPersonalization));
    state =
        Blake2bDigest(digestSize: digestSize, personalization: personalization);
  }

  void update(Uint8List input) {
    state.update(input, 0, input.length);
  }

  Uint8List doFinal() {
    var hash = Uint8List(32);
    state.doFinal(hash, 0);
    return hash;
  }

  String doFinalString() => listToHex(doFinal());
}

class Serializer {
  static Struct serializeOutPoint(OutPoint outPoint) {
    var txHash = Byte32.fromHex(outPoint.txHash!);
    var index = UInt32.fromHex(outPoint.index!);
    return Struct(<FixedType>[txHash, index]);
  }

  static Table serializeScript(Script script) {
    return Table([
      Byte32.fromHex(script.codeHash!),
      Byte1.fromHex(Script.Data == script.hashType ? '00' : '01'),
      script.args != null
          ? Bytes.fromHex(script.args!)
          : Empty() as SerializeType<dynamic>
    ]);
  }

  static Struct serializeCellInput(CellInput cellInput) {
    var sinceUInt64 = UInt64.fromHex(cellInput.since!);
    var outPointStruct = serializeOutPoint(cellInput.previousOutput!);
    return Struct(<SerializeType>[sinceUInt64, outPointStruct]);
  }

  static Table serializeCellOutput(CellOutput cellOutput) {
    return Table([
      UInt64.fromHex(cellOutput.capacity!),
      serializeScript(cellOutput.lock!),
      cellOutput.type != null
          ? serializeScript(cellOutput.type!)
          : Empty() as SerializeType<dynamic>
    ]);
  }

  static Struct serializeCellDep(CellDep cellDep) {
    var outPointStruct = serializeOutPoint(cellDep.outPoint!);
    var depTypeBytes = CellDep.Code == cellDep.depType
        ? Byte1.fromHex('0')
        : Byte1.fromHex('1');
    return Struct([outPointStruct, depTypeBytes]);
  }

  static Fixed<Struct> serializeCellDeps(List<CellDep> cellDeps) {
    return Fixed(cellDeps.map((cellDep) => serializeCellDep(cellDep)).toList());
  }

  static Fixed<Struct> serializeCellInputs(List<CellInput> cellInputs) {
    return Fixed(
        cellInputs.map((cellInput) => serializeCellInput(cellInput)).toList());
  }

  static Dynamic<Table> serializeCellOutputs(List<CellOutput> cellOutputs) {
    return Dynamic(cellOutputs
        .map((cellOutput) => serializeCellOutput(cellOutput))
        .toList());
  }

  static Dynamic<Bytes> serializeBytes(List<String> bytes) {
    return Dynamic(bytes.map((byte) => Bytes.fromHex(byte)).toList());
  }

  static Fixed<Byte32> serializeByte32(List<String> bytes) {
    return Fixed(bytes.map((byte) => Byte32.fromHex(byte)).toList());
  }

  static Table serializeWitnessArgs(Witness witness) {
    var list = <Option>[];
    list.add(Option(witness.lock == null
        ? Empty()
        : Bytes.fromHex(witness.lock!) as SerializeType<dynamic>));
    list.add(Option(witness.inputType == null
        ? Empty()
        : Bytes.fromHex(witness.inputType!) as SerializeType<dynamic>));
    list.add(Option(witness.outputType == null
        ? Empty()
        : Bytes.fromHex(witness.outputType!) as SerializeType<dynamic>));
    return Table(list);
  }

  // static Dynamic<SerializeType> serializeWitnesses(List<dynamic> witnesses) {
  //   var witnessList = [];
  //   for (var witness in witnesses) {
  //     if (witness is Witness) {
  //       witnessList.add(serializeWitnessArgs(witness));
  //     } else {
  //       witnessList.add(Bytes.fromHex(witness));
  //     }
  //   }
  //   witnessList =
  //       witnessList.map((witness) => witness as SerializeType).toList();
  //   return Dynamic<SerializeType>(witnessList as List<SerializeType<dynamic>>);
  // }

  static Table serializeRawTransaction(CKBTransaction transaction) {
    var tx = Convert.parseTransaction(transaction);

    return Table([
      UInt32.fromHex(tx.version!),
      Serializer.serializeCellDeps(tx.cellDeps!),
      Serializer.serializeByte32(tx.headerDeps!),
      Serializer.serializeCellInputs(tx.inputs!),
      Serializer.serializeCellOutputs(tx.outputs!),
      Serializer.serializeBytes(tx.outputsData!)
    ]);
  }

  // static Table serializeTransaction(CKBTransaction transaction) {
  //   return Table([
  //     serializeRawTransaction(transaction),
  //     serializeWitnesses(transaction.witnesses!)
  //   ]);
  // }
}
