import 'dependency.dart';
import 'data_type.dart';

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

  String computeHash() {
    var blake2b = Blake2b();
    blake2b.update(Serializer.serializeRawTransaction(this).toBytes());
    return appendHexPrefix(blake2b.doFinalString());
  }
}
