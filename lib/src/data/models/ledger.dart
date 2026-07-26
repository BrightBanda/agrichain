import 'json_utils.dart';

/// Events the backend anchors to the simulated ledger.
///
/// Mirrors `LedgerEvent` in `app/modules/blockchain/events.py`.
enum LedgerEventType {
  genesis('GENESIS', 'Genesis', 'The first block, created with the chain.'),
  farmerRegistered(
    'FARMER_REGISTERED',
    'Farmer Registered',
    'A farmer KYC record was committed to the ledger.',
  ),
  produceListed(
    'PRODUCE_LISTED',
    'Produce Listed',
    'A farmer listed produce on the marketplace.',
  ),
  harvestRecorded(
    'HARVEST_RECORDED',
    'Harvest Recorded',
    'A farmer recorded a harvest.',
  ),
  harvestVerified(
    'HARVEST_VERIFIED',
    'Harvest Verified',
    'A cooperative or officer attested to a harvest.',
  ),
  loanAgreement(
    'LOAN_AGREEMENT',
    'Loan Agreement',
    'A financial institution approved a loan on agreed terms.',
  ),
  repaymentRecorded(
    'REPAYMENT_RECORDED',
    'Repayment Recorded',
    'A repayment was made against a loan.',
  ),
  scoreUpdated(
    'SCORE_UPDATED',
    'Lending Score Updated',
    'The credit engine recalculated a lending score.',
  ),
  unknown('UNKNOWN', 'Unknown Event', 'An event this app version cannot label.');

  const LedgerEventType(this.wireValue, this.label, this.description);

  final String wireValue;
  final String label;
  final String description;

  static LedgerEventType fromJson(String? value) => values.firstWhere(
    (event) => event.wireValue == value,
    orElse: () => LedgerEventType.unknown,
  );
}

/// The kind of record a block attests to. Mirrors `LedgerEntity`.
enum LedgerEntityType {
  none('NONE', 'None'),
  farmer('FARMER', 'Farmer KYC'),
  product('PRODUCT', 'Produce Listing'),
  harvest('HARVEST', 'Harvest'),
  loan('LOAN', 'Loan'),
  repayment('REPAYMENT', 'Repayment'),
  lendingScore('LENDING_SCORE', 'Lending Score');

  const LedgerEntityType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  /// Whether the backend can re-hash this record and compare it to the chain.
  bool get isVerifiable => const {
    LedgerEntityType.farmer,
    LedgerEntityType.product,
    LedgerEntityType.harvest,
    LedgerEntityType.loan,
    LedgerEntityType.repayment,
  }.contains(this);

  static LedgerEntityType fromJson(String? value) => values.firstWhere(
    (entity) => entity.wireValue == value,
    orElse: () => LedgerEntityType.none,
  );
}

/// One block in the chain.
class LedgerBlock {
  final int index;
  final DateTime? createdAt;
  final LedgerEventType eventType;
  final LedgerEntityType entityType;
  final String? entityId;
  final String payloadHash;
  final Map<String, dynamic> payloadSummary;
  final String previousHash;
  final int nonce;
  final int difficulty;
  final String blockHash;

  const LedgerBlock({
    required this.index,
    required this.eventType,
    required this.entityType,
    required this.payloadHash,
    required this.payloadSummary,
    required this.previousHash,
    required this.nonce,
    required this.difficulty,
    required this.blockHash,
    this.createdAt,
    this.entityId,
  });

  factory LedgerBlock.fromJson(Map<String, dynamic> json) {
    final summary = json['payload_summary'];
    return LedgerBlock(
      index: asInt(json['index']),
      createdAt: asDateTime(json['created_at']),
      eventType: LedgerEventType.fromJson(json['event_type'] as String?),
      entityType: LedgerEntityType.fromJson(json['entity_type'] as String?),
      entityId: json['entity_id'] as String?,
      payloadHash: json['payload_hash'] as String? ?? '',
      payloadSummary: summary is Map
          ? summary.cast<String, dynamic>()
          : const <String, dynamic>{},
      previousHash: json['previous_hash'] as String? ?? '',
      nonce: asInt(json['nonce']),
      difficulty: asInt(json['difficulty']),
      blockHash: json['block_hash'] as String? ?? '',
    );
  }

  bool get isGenesis => index == 0;

  /// Whether this block anchors a record the backend can re-verify.
  bool get isRecordVerifiable => entityId != null && entityType.isVerifiable;

  /// `0000a1b2…9f8e` — enough to recognise a hash without filling the screen.
  String get shortHash => shortenHash(blockHash);
}

/// Truncates a 64-character hex digest for display.
String shortenHash(String hash, {int lead = 10, int tail = 6}) {
  if (hash.length <= lead + tail + 1) return hash;
  return '${hash.substring(0, lead)}…${hash.substring(hash.length - tail)}';
}

/// A single reason the chain failed verification.
class ChainProblem {
  final int index;
  final String issue;
  final String detail;
  final String? expected;
  final String? found;

  const ChainProblem({
    required this.index,
    required this.issue,
    required this.detail,
    this.expected,
    this.found,
  });

  factory ChainProblem.fromJson(Map<String, dynamic> json) => ChainProblem(
    index: asInt(json['index']),
    issue: json['issue'] as String? ?? 'UNKNOWN',
    detail: json['detail'] as String? ?? '',
    expected: json['expected'] as String?,
    found: json['found'] as String?,
  );

  /// `HASH_MISMATCH` reads better as `Hash mismatch`.
  String get title {
    if (issue.isEmpty) return 'Unknown issue';
    final words = issue.replaceAll('_', ' ').toLowerCase();
    return words.replaceRange(0, 1, words[0].toUpperCase());
  }
}

/// The result of re-hashing every block and checking every link.
class ChainIntegrity {
  final bool valid;
  final int blockCount;
  final String? tipHash;
  final List<ChainProblem> problems;
  final DateTime? checkedAt;

  const ChainIntegrity({
    required this.valid,
    required this.blockCount,
    required this.problems,
    this.tipHash,
    this.checkedAt,
  });

  factory ChainIntegrity.fromJson(Map<String, dynamic> json) => ChainIntegrity(
    valid: json['valid'] as bool? ?? false,
    blockCount: asInt(json['block_count']),
    tipHash: json['tip_hash'] as String?,
    problems: (json['problems'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ChainProblem.fromJson(item.cast<String, dynamic>()))
        .toList(),
    checkedAt: asDateTime(json['checked_at']),
  );
}

/// Chain-wide counters shown at the top of the explorer.
class ChainStats {
  final int blockCount;
  final String? tipHash;
  final int difficulty;
  final Map<String, int> events;
  final bool isSimulation;
  final String note;

  const ChainStats({
    required this.blockCount,
    required this.difficulty,
    required this.events,
    required this.isSimulation,
    required this.note,
    this.tipHash,
  });

  factory ChainStats.fromJson(Map<String, dynamic> json) {
    final events = json['events'];
    return ChainStats(
      blockCount: asInt(json['block_count']),
      tipHash: json['tip_hash'] as String?,
      difficulty: asInt(json['difficulty']),
      events: events is Map
          ? {
              for (final entry in events.entries)
                '${entry.key}': asInt(entry.value),
            }
          : const <String, int>{},
      isSimulation: json['is_simulation'] as bool? ?? true,
      note: json['note'] as String? ?? '',
    );
  }
}

/// Does a live database row still match what the ledger committed to?
class RecordVerification {
  final LedgerEntityType entityType;
  final String entityId;
  final bool anchored;
  final bool matches;
  final String message;
  final int? blockIndex;
  final String? blockHash;
  final String? anchoredPayloadHash;
  final String? currentPayloadHash;

  const RecordVerification({
    required this.entityType,
    required this.entityId,
    required this.anchored,
    required this.matches,
    required this.message,
    this.blockIndex,
    this.blockHash,
    this.anchoredPayloadHash,
    this.currentPayloadHash,
  });

  factory RecordVerification.fromJson(Map<String, dynamic> json) =>
      RecordVerification(
        entityType: LedgerEntityType.fromJson(json['entity_type'] as String?),
        entityId: json['entity_id'] as String? ?? '',
        anchored: json['anchored'] as bool? ?? false,
        matches: json['matches'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        blockIndex: json['block_index'] == null
            ? null
            : asInt(json['block_index']),
        blockHash: json['block_hash'] as String?,
        anchoredPayloadHash: json['anchored_payload_hash'] as String?,
        currentPayloadHash: json['current_payload_hash'] as String?,
      );
}
