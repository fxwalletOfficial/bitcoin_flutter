import 'package:bitcoin_flutter/src/utils/script.dart';

bool inputCheck(List<dynamic> chunks) {
  return chunks.length == 1 && isCanonicalScriptSignature(chunks[0]);
}
