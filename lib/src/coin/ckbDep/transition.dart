import 'data_type.dart';
import 'dart:convert';

import 'dependency.dart';

class CKBTransaction {
  String? version;
  String? hash;
  List<CellDep>? cellDeps;
  List<String>? headerDeps;
  List<CellInput>? inputs;
  List<CellOutput>? outputs;
  List<String>? outputsData;
  List<dynamic>? witnesses;

  CKBTransaction(
      {this.version,
      this.hash,
      this.cellDeps,
      this.headerDeps,
      this.inputs,
      this.outputs,
      this.outputsData,
      this.witnesses});

  factory CKBTransaction.fromJson(Map<String, dynamic> json) {
    return CKBTransaction(
        version: json['version'],
        hash: json['hash'],
        cellDeps: (json['cell_deps'] as List)
            .map((cellDep) => CellDep.fromJson(cellDep))
            .toList(),
        headerDeps: (json['header_deps'] as List)
            .map((headerDep) => headerDep.toString())
            .toList(),
        inputs: (json['inputs'] as List)
            .map((input) => CellInput.fromJson(input))
            .toList(),
        outputs: (json['outputs'] as List)
            .map((output) => CellOutput.fromJson(output))
            .toList(),
        outputsData: (json['outputs_data'] as List)
            .map((outputData) => outputData.toString())
            .toList(),
        witnesses: (json['witnesses'] as List)
            .map((witness) => witness == '0x'
                ? witness
                : Witness(lock: Witness.SIGNATURE_PLACEHOLDER))
            .toList());
  }

  String toJson() {
    return jsonEncode({
      'version': version,
      'hash': hash,
      'cell_deps': cellDeps?.map((cellDep) => cellDep.toJson()).toList(),
      'header_deps': headerDeps,
      'inputs': inputs?.map((input) => input.toJson()).toList(),
      'outputs': outputs?.map((output) => output.toJson()).toList(),
      'outputs_data': outputsData,
      'witnesses':
          witnesses?.map((witness) => witness is String ? witness : null).toList()
    });
  }

  String computeHash() {
    var blake2b = Blake2b();
    blake2b.update(Serializer.serializeRawTransaction(this).toBytes());
    return appendHexPrefix(blake2b.doFinalString());
  }
}
