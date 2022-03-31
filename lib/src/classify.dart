import 'dart:typed_data';

import 'package:bitcoin_flutter/src/templates/pubkey.dart' as pubkey;
import 'package:bitcoin_flutter/src/templates/pubkeyhash.dart' as pubkeyhash;
import 'package:bitcoin_flutter/src/templates/scriptHash.dart' as scripthash;
import 'package:bitcoin_flutter/src/templates/witnesspubkeyhash.dart' as witness_pubkey_hash;
import 'package:bitcoin_flutter/src/utils/script.dart' as bscript;

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
  if (witness_pubkey_hash.outputCheck(script)) return SCRIPT_TYPES['P2WPKH'];
  if (pubkeyhash.outputCheck(script)) return SCRIPT_TYPES['P2PKH'];
  if (scripthash.outputCheck(script)) return SCRIPT_TYPES['P2SH'];
  final chunks = bscript.decompile(script);
  if (chunks == null) throw ArgumentError('Invalid script');
  return SCRIPT_TYPES['NONSTANDARD'];
}

String? classifyInput(Uint8List script, bool allowIncomplete) {
  final chunks = bscript.decompile(script);

  if (chunks == null) throw ArgumentError('Invalid script');
  if (pubkeyhash.inputCheck(chunks)) return SCRIPT_TYPES['P2PKH'];
  if (scripthash.inputCheck(chunks, allowIncomplete)) return SCRIPT_TYPES['P2SH'];
  if (pubkey.inputCheck(chunks)) return SCRIPT_TYPES['P2PK'];

  return SCRIPT_TYPES['NONSTANDARD'];
}

String? classifyWitness(List<Uint8List?>? script) {
  final chunks = bscript.decompile(script);

  if (chunks == null) throw ArgumentError('Invalid script');
  if (witness_pubkey_hash.inputCheck(chunks)) return SCRIPT_TYPES['P2WPKH'];

  return SCRIPT_TYPES['NONSTANDARD'];
}
