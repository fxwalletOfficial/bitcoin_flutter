import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hex/hex.dart';
import 'package:test/test.dart';

import 'package:bitcoin_flutter/src/utils/script.dart' as bscript;
import 'package:bitcoin_flutter/src/transaction.dart';
import 'package:bitcoin_flutter/src/ecpair.dart';

main() {
  final fixtures = json.decode(new File('test/fixtures/transaction.json')
      .readAsStringSync(encoding: utf8));
  final valids = (fixtures['valid'] as List<dynamic>);

  group('Transaction', () {
    group('fromBuffer/fromHex', () {
      valids.forEach(importExport);
      (fixtures['hashForSignature'] as List<dynamic>).forEach(importExport);
      (fixtures['invalid']['fromBuffer'] as List<dynamic>).forEach((f) {
        test('throws on ${f['exception']}', () {
          try {
            expect(Transaction.fromHex(f['hex']), isArgumentError);
          } catch (err) {
            expect((err as ArgumentError).message, f['exception']);
          }
        });
      });

      test('.version should be interpreted as an int32le', () {
        final txHex = 'ffffffff0000ffffffff';
        final tx = Transaction.fromHex(txHex);
        expect(-1, tx.version);
      });
    });

    group('toBuffer/toHex', () {
      valids.forEach((f) {
        test('exports ${f['description']} (${f['id']})', () {
          Transaction actual = fromRaw(f['raw'], false);
          expect(actual.toHex(), f['hex']);
        });
        if (f['whex'] != null && f['whex'] != '') {
          test('exports ${f['description']} (${f['id']}) as witness', () {
            Transaction actual = fromRaw(f['raw'], true);
            expect(actual.toHex(), f['whex']);
          });
        }
      });
    });

    group('weight/virtualSize', () {
      test('computes virtual size', () {
        valids.forEach((f) {
          final txHex =
              (f['whex'] != null && f['whex'] != '') ? f['whex'] : f['hex'];
          final transaction = Transaction.fromHex(txHex);
          expect(transaction.virtualSize(), f['virtualSize']);
        });
      });
    });

    group('addInput', () {
      var prevTxHash;
      setUp(() {
        prevTxHash = HEX.decode(
            'ffffffff00ffff000000000000000000000000000000000000000000101010ff');
      });
      test('returns an index', () {
        final tx = new Transaction();
        expect(tx.addInput(prevTxHash, 0), 0);
        expect(tx.addInput(prevTxHash, 0), 1);
      });
      test('defaults to empty script, and 0xffffffff SEQUENCE number', () {
        final tx = new Transaction();
        tx.addInput(prevTxHash, 0);
        expect(tx.ins[0].script!.length, 0);
        expect(tx.ins[0].sequence, 0xffffffff);
      });
      (fixtures['invalid']['addInput'] as List<dynamic>).forEach((f) {
        test('throws on ' + f['exception'], () {
          final tx = new Transaction();
          final hash = Uint8List.fromList(HEX.decode(f['hash']));
          try {
            expect(tx.addInput(hash, f['index']), isArgumentError);
          } catch (err) {
            expect((err as ArgumentError).message, f['exception']);
          }
        });
      });
    });

    test('addOutput returns an index', () {
      final tx = new Transaction();
      expect(tx.addOutput(new Uint8List(0), 0), 0);
      expect(tx.addOutput(new Uint8List(0), 0), 1);
    });

    group('getHash/getId', () {
      verify(f) {
        test('should return the id for ${f['id']} (${f['description']})', () {
          final txHex =
              (f['whex'] != null && f['whex'] != '') ? f['whex'] : f['hex'];
          final tx = Transaction.fromHex(txHex);
          expect(HEX.encode(tx.getHash()), f['hash']);
          expect(tx.getId(), f['id']);
        });
      }

      valids.forEach(verify);
    });

    group('isCoinbase', () {
      verify(f) {
        test(
            'should return ${f['coinbase']} for ${f['id']} (${f['description']})',
            () {
          final tx = Transaction.fromHex(f['hex']);
          expect(tx.isCoinbase(), f['coinbase']);
        });
      }

      valids.forEach(verify);
    });

    group('hashForSignature', () {
      (fixtures['hashForSignature'] as List<dynamic>).forEach((f) {
        test(
            'should return ${f['hash']} for ${f['description'] != null ? 'case "' + f['description'] + '"' : f['script']}',
            () {
          final tx = Transaction.fromHex(f['txHex']);
          final script = bscript.fromASM(f['script']);
          expect(
              HEX.encode(tx.hashForSignature(f['inIndex'], script, f['type'])),
              f['hash']);
        });
      });
    });
  });

  group('Supplementary transaction', () {
    final tx = new Transaction();
    final scriptPubKey = new Uint8List(16);
    test('add output at', () {
      final result = tx.addOutputAt(scriptPubKey, 1, 0);
      expect(result, 0);
    });

    test('add addBaseOutput', () {
      final output = new Output(script: scriptPubKey, value: 1);
      output.toString();
      final result = tx.addBaseOutput(output);
      expect(result, 1);
    });

    test('set value', () {
      final intValue = 10;
      tx.setVersion(intValue);
      tx.setLocktime(intValue);
      expect(tx.version, intValue);
      expect(tx.locktime, intValue);
    });

    test('signSchnorr', () {
      final key = Uint8List.fromList(HEX.decode(
          '0000000000000000000000000000000000000000000000000000000000000001'));
      ;
      final tapLeafScript =
          new TapLeafScript(version: 1, script: key, controlBlock: key);
      final hash = HEX.decode(
          'ffffffff00ffff000000000000000000000000000000000000000000101010ff');
      final input = new Input(
          hash: new Uint8List.fromList(hash),
          index: 0,
          value: 0,
          prevOutScript: key,
          tapLeafScript: [tapLeafScript]);
      input.toString();
      tx.ins.add(input);
      final keyPair = ECPair.fromPrivateKey(key);
      tx.signSchnorr(vin: 0, keyPair: keyPair);
      tx.toString();
    });
  });
}

importExport(dynamic f) {
  final id = f['id'] ?? f['hash'];
  final txHex = f['hex'] ?? f['txHex'];
  test('imports ${f['description']} ($id)', () {
    final actual = Transaction.fromHex(txHex);
    expect(actual.toHex(), txHex);
  });
}

Transaction fromRaw(raw, [isWitness]) {
  final tx = new Transaction();
  tx.version = raw['version'];
  tx.locktime = raw['locktime'];

  (raw['ins'] as List<dynamic>).asMap().forEach((i, txIn) {
    final txHash = Uint8List.fromList(HEX.decode(txIn['hash']));
    var scriptSig;

    if (txIn['data'] != null) {
      scriptSig = HEX.decode(txIn['data']);
    } else if (txIn['script'] != null && txIn['script'] != '') {
      scriptSig = bscript.fromASM(txIn['script']);
    }
    tx.addInput(txHash, txIn['index'],
        sequence: txIn['sequence'], scriptSig: scriptSig);

    if (!isWitness) return;

    final witness = (txIn['witness'] as List<dynamic>)
        .map((e) => HEX.decode(e.toString()) as Uint8List)
        .toList();
    tx.setWitness(i, witness);
  });

  (raw['outs'] as List<dynamic>).forEach((txOut) {
    var script;
    if (txOut['data'] != null) {
      script = HEX.decode(txOut['data']);
    } else if (txOut['script'] != null) {
      script = bscript.fromASM(txOut['script']);
    }
    tx.addOutput(script, txOut['value']);
  });

  return tx;
}
