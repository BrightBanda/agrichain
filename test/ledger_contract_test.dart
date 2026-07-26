import 'dart:convert';

import 'package:agri/src/data/models/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payloads captured from the running ledger endpoints, so the models are
/// tested against what the simulated chain actually emits.
void main() {
  group('LedgerBlock.fromJson', () {
    test('parses a real genesis block', () {
      final json =
          jsonDecode('''
{"index":0,"created_at":"2026-07-26T07:48:58.348356","event_type":"GENESIS",
"entity_type":"NONE","entity_id":null,
"payload_hash":"c8524db1599006611ae375447ab36c693ab8876fe08f7d84c76c2b46d6351916",
"payload_summary":{"note":"AgriChain simulated ledger genesis block"},
"previous_hash":"0000000000000000000000000000000000000000000000000000000000000000",
"nonce":773,"difficulty":3,
"block_hash":"0000b343bb0bb7e3a148b7cd7125ce22cef7ceb823b5bb19d009a553af788dc9"}
''')
              as Map<String, dynamic>;

      final block = LedgerBlock.fromJson(json);

      expect(block.index, 0);
      expect(block.isGenesis, isTrue);
      expect(block.eventType, LedgerEventType.genesis);
      expect(block.entityType, LedgerEntityType.none);
      expect(block.nonce, 773);
      expect(block.difficulty, 3);
      // Proof of work: the hash must satisfy the stated difficulty.
      expect(block.blockHash.startsWith('0' * block.difficulty), isTrue);
      expect(block.previousHash, '0' * 64);
      expect(block.payloadSummary['note'], contains('genesis'));
      // Genesis anchors no record, so there is nothing to re-verify.
      expect(block.isRecordVerifiable, isFalse);
    });

    test('a block anchoring a harvest is re-verifiable', () {
      final block = LedgerBlock.fromJson({
        'index': 2,
        'created_at': '2026-07-26T07:50:00.000000',
        'event_type': 'HARVEST_RECORDED',
        'entity_type': 'HARVEST',
        'entity_id': '11111111-2222-3333-4444-555555555555',
        'payload_hash': 'a' * 64,
        'payload_summary': {'crop': 'Maize', 'quantity': '120'},
        'previous_hash': 'b' * 64,
        'nonce': 4242,
        'difficulty': 3,
        'block_hash': '000c${'d' * 60}',
      });

      expect(block.eventType, LedgerEventType.harvestRecorded);
      expect(block.entityType, LedgerEntityType.harvest);
      expect(block.isRecordVerifiable, isTrue);
      expect(block.isGenesis, isFalse);
    });

    test('an unrecognised event type does not break the explorer', () {
      final block = LedgerBlock.fromJson({
        'index': 9,
        'event_type': 'SOMETHING_NEW',
        'entity_type': 'WHATEVER',
        'payload_hash': '',
        'payload_summary': null,
        'previous_hash': '',
        'nonce': 0,
        'difficulty': 0,
        'block_hash': '',
      });

      expect(block.eventType, LedgerEventType.unknown);
      expect(block.entityType, LedgerEntityType.none);
      expect(block.payloadSummary, isEmpty);
    });
  });

  test('ChainStats parses the live stats response', () {
    final stats = ChainStats.fromJson(
      jsonDecode('''
{"block_count":9,"tip_hash":"0000b343bb0bb7e3a148b7cd7125ce22cef7ceb823b5bb19d009a553af788dc9",
"difficulty":3,"events":{"GENESIS":1,"FARMER_REGISTERED":1,"SCORE_UPDATED":2},
"is_simulation":true,"note":"Simulated single-node ledger."}
''') as Map<String, dynamic>,
    );

    expect(stats.blockCount, 9);
    expect(stats.difficulty, 3);
    expect(stats.isSimulation, isTrue);
    expect(stats.events['SCORE_UPDATED'], 2);
  });

  group('ChainIntegrity', () {
    test('parses a healthy chain', () {
      final integrity = ChainIntegrity.fromJson({
        'valid': true,
        'block_count': 9,
        'tip_hash': '0000abc',
        'problems': [],
        'checked_at': '2026-07-26T07:58:33.201936',
      });

      expect(integrity.valid, isTrue);
      expect(integrity.problems, isEmpty);
      expect(integrity.checkedAt?.minute, 58);
    });

    test('parses a tampered chain, including the cascade to the next block', () {
      final integrity = ChainIntegrity.fromJson({
        'valid': false,
        'block_count': 9,
        'tip_hash': '0000abc',
        'problems': [
          {
            'index': 1,
            'issue': 'HASH_MISMATCH',
            'detail': 'The block no longer hashes to its recorded hash.',
            'expected': 'x' * 64,
            'found': 'y' * 64,
          },
          {
            'index': 2,
            'issue': 'BROKEN_LINK',
            'detail': 'This block does not point at the previous block.',
            'expected': 'x' * 64,
            'found': 'z' * 64,
          },
        ],
      });

      expect(integrity.valid, isFalse);
      expect(integrity.problems, hasLength(2));
      expect(integrity.problems.first.index, 1);
      // Altering one block must invalidate the one after it.
      expect(integrity.problems.last.issue, 'BROKEN_LINK');
      expect(integrity.problems.first.title, 'Hash mismatch');
    });

    test('an empty issue string does not throw when titled', () {
      final problem = ChainProblem.fromJson({'index': 3, 'issue': '', 'detail': ''});
      expect(problem.title, 'Unknown issue');
    });
  });

  group('RecordVerification', () {
    test('parses an untampered record', () {
      final result = RecordVerification.fromJson({
        'entity_type': 'PRODUCT',
        'entity_id': '11111111-2222-3333-4444-555555555555',
        'anchored': true,
        'matches': true,
        'message': 'Verified. This record is unchanged since it was anchored in '
            'block 5.',
        'block_index': 5,
        'block_hash': '0000abc',
        'anchored_payload_hash': 'a' * 64,
        'current_payload_hash': null,
      });

      expect(result.anchored, isTrue);
      expect(result.matches, isTrue);
      expect(result.blockIndex, 5);
      expect(result.entityType, LedgerEntityType.product);
    });

    test('parses a tampered record with both hashes for comparison', () {
      final result = RecordVerification.fromJson({
        'entity_type': 'HARVEST',
        'entity_id': '11111111-2222-3333-4444-555555555555',
        'anchored': true,
        'matches': false,
        'message': 'Tampering detected.',
        'block_index': 2,
        'anchored_payload_hash': 'a' * 64,
        'current_payload_hash': 'b' * 64,
      });

      expect(result.matches, isFalse);
      expect(result.anchoredPayloadHash, isNot(result.currentPayloadHash));
    });

    test('parses an unanchored record', () {
      final result = RecordVerification.fromJson({
        'entity_type': 'PRODUCT',
        'entity_id': '11111111-2222-3333-4444-555555555555',
        'anchored': false,
        'matches': false,
        'message': 'This record has no ledger entry.',
      });

      expect(result.anchored, isFalse);
      expect(result.blockIndex, isNull);
    });
  });

  test('shortenHash keeps the leading zeroes that prove the work', () {
    final short = shortenHash('0000b343bb0bb7e3a148b7cd7125ce22cef7ceb8', );
    expect(short.startsWith('0000b343bb'), isTrue);
    expect(short, contains('…'));
    // Short hashes are returned untouched.
    expect(shortenHash('abc'), 'abc');
  });
}
