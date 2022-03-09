import 'dart:typed_data';

import 'package:bitcoin_flutter/src/templates/pubkey.dart' as pubkey;
import 'package:bitcoin_flutter/src/templates/pubkeyhash.dart' as pubkeyhash;
import 'package:bitcoin_flutter/src/templates/witnesspubkeyhash.dart' as witnessPubKeyHash;
import 'package:bitcoin_flutter/src/utils/script.dart';

const SCRIPT_TYPES = {
  'P2SM': 'multisig',
  'NONSTANDARD': 'nonstandard',
  'NULLDATA': 'nulldata',
  'P2PK': 'pubkey',
  'P2PKH': 'pubkeyhash',
  'P2SH': 'scripthash',
  'P2WPKH': 'witnesspubkeyhash',
  'P2WSH': 'witnessscripthash',
  'WITNESS_COMMITMENT': 'witnesscommitment'
};

String? classifyOutput(Uint8List script) {
  if (witnessPubKeyHash.outputCheck(script)) return SCRIPT_TYPES['P2WPKH'];
  if (pubkeyhash.outputCheck(script)) return SCRIPT_TYPES['P2PKH'];
  final chunks = decompile(script);
  if (chunks == null) throw new ArgumentError('Invalid script');
  return SCRIPT_TYPES['NONSTANDARD'];
}

String? classifyInput(Uint8List script) {
  final chunks = decompile(script);
  if (chunks == null) throw new ArgumentError('Invalid script');
  if (pubkeyhash.inputCheck(chunks)) return SCRIPT_TYPES['P2PKH'];
  if (pubkey.inputCheck(chunks)) return SCRIPT_TYPES['P2PK'];
  return SCRIPT_TYPES['NONSTANDARD'];
}

String? classifyWitness(List<Uint8List> script) {
  final chunks = decompile(script);
  if (chunks == null) throw new ArgumentError('Invalid script');
  if (witnessPubKeyHash.inputCheck(chunks)) return SCRIPT_TYPES['P2WPKH'];
  return SCRIPT_TYPES['NONSTANDARD'];
}
