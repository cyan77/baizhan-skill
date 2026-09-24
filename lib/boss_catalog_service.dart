import 'dart:convert';
import 'dart:io';

const defaultBossRankMultipliers = <int, double>{
  1: 1,
  2: 2,
  3: 3,
  4: 4,
  5: 5,
  6: 7,
  7: 10,
  8: 15,
  9: 22.5,
  10: 33.75,
};

const defaultThreeSkillBonuses = <int, double>{
  1: 100,
  2: 200,
  3: 300,
  4: 400,
  5: 2000,
  6: 6000,
  7: 8000,
  8: 10000,
  9: 12000,
  10: 14000,
};

/// The first ten ranks are the rules from the current version and are always
/// read-only.  For catalogs whose maximum is below ten, the first rank after
/// the maximum remains the natural "nothing editable yet" boundary.
int minimumEditableRankFor(int maxSkillRank) =>
    maxSkillRank < 10 ? maxSkillRank + 1 : 11;

class BossStatRules {
  BossStatRules({
    required Map<int, double> rankMultipliers,
    required Map<int, double> threeSkillBonuses,
    required this.editableFromRank,
  })  : rankMultipliers = {...rankMultipliers},
        threeSkillBonuses = {...threeSkillBonuses};

  factory BossStatRules.defaults({int maxSkillRank = 10}) {
    final rules = BossStatRules(
      rankMultipliers: defaultBossRankMultipliers,
      threeSkillBonuses: defaultThreeSkillBonuses,
      editableFromRank: maxSkillRank + 1,
    );
    rules.ensureThrough(maxSkillRank);
    return rules;
  }

  factory BossStatRules.fromJson(
    dynamic value, {
    required int maxSkillRank,
    int? defaultEditableFromRank,
  }) {
    final raw = value is Map ? Map<String, dynamic>.from(value) : const {};
    final rules = BossStatRules(
      rankMultipliers:
          _readNumberMap(raw['rankMultipliers'], defaultBossRankMultipliers),
      threeSkillBonuses:
          _readNumberMap(raw['threeSkillBonuses'], defaultThreeSkillBonuses),
      editableFromRank: (raw['editableFromRank'] as num?)?.toInt() ??
          defaultEditableFromRank ??
          maxSkillRank + 1,
    );
    rules.ensureThrough(maxSkillRank);
    return rules;
  }

  final Map<int, double> rankMultipliers;
  final Map<int, double> threeSkillBonuses;
  int editableFromRank;

  void ensureThrough(int maxSkillRank) {
    for (var rank = 1; rank <= maxSkillRank; rank++) {
      if (!rankMultipliers.containsKey(rank)) {
        final previous = rankMultipliers[rank - 1] ?? 1;
        rankMultipliers[rank] = previous * 1.5;
      }
      threeSkillBonuses.putIfAbsent(rank, () => 0);
    }
    editableFromRank = editableFromRank
        .clamp(minimumEditableRankFor(maxSkillRank), maxSkillRank + 1)
        .toInt();
  }

  BossStatRules copy() => BossStatRules(
        rankMultipliers: rankMultipliers,
        threeSkillBonuses: threeSkillBonuses,
        editableFromRank: editableFromRank,
      );

  Map<String, dynamic> toJson() => {
        'rankMultipliers': _writeNumberMap(rankMultipliers),
        'threeSkillBonuses': _writeNumberMap(threeSkillBonuses),
        'editableFromRank': editableFromRank,
      };

  static Map<int, double> _readNumberMap(
      dynamic value, Map<int, double> fallback) {
    final result = <int, double>{...fallback};
    if (value is Map) {
      value.forEach((key, item) {
        final rank = int.tryParse(key.toString());
        final number = item is num ? item.toDouble() : double.tryParse('$item');
        if (rank != null && rank > 0 && number != null) {
          result[rank] = number;
        }
      });
    }
    return result;
  }

  static Map<String, double> _writeNumberMap(Map<int, double> value) =>
      {for (final entry in value.entries) '${entry.key}': entry.value};
}

class RemoteBossCatalog {
  RemoteBossCatalog({
    required this.version,
    required this.updatedAt,
    required this.notes,
    required this.bosses,
    this.maxSkillRank = 10,
    BossStatRules? rules,
  }) : rules = rules ?? BossStatRules.defaults(maxSkillRank: maxSkillRank);

  final int version;
  final String updatedAt;
  final String notes;
  final List<dynamic> bosses;
  final int maxSkillRank;
  final BossStatRules rules;

  factory RemoteBossCatalog.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'baizhan-bosses' || json['bosses'] is! List) {
      throw const FormatException('首领技能数据格式不正确');
    }
    final maxSkillRank =
        ((json['maxSkillRank'] as num?)?.toInt() ?? 10).clamp(1, 99);
    return RemoteBossCatalog(
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      bosses: json['bosses'] as List<dynamic>,
      maxSkillRank: maxSkillRank,
      rules: BossStatRules.fromJson(json['rules'],
          maxSkillRank: maxSkillRank,
          defaultEditableFromRank: maxSkillRank + 1),
    );
  }
}

class BossCatalogService {
  static const catalogUrl =
      'https://raw.githubusercontent.com/cyan77/baizhan-skill/main/data/baizhan-bosses.json';

  Future<RemoteBossCatalog> fetch() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(Uri.parse(catalogUrl));
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('获取首领技能数据失败：${response.statusCode}');
      }
      final text = await utf8.decoder.bind(response).join();
      return RemoteBossCatalog.fromJson(
          jsonDecode(text) as Map<String, dynamic>);
    } finally {
      client.close(force: true);
    }
  }
}
