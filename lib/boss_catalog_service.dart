import 'dart:convert';
import 'dart:io';

class RemoteBossCatalog {
  const RemoteBossCatalog({
    required this.version,
    required this.updatedAt,
    required this.notes,
    required this.bosses,
    this.maxSkillRank = 10,
  });

  final int version;
  final String updatedAt;
  final String notes;
  final List<dynamic> bosses;
  final int maxSkillRank;

  factory RemoteBossCatalog.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'baizhan-bosses' || json['bosses'] is! List) {
      throw const FormatException('首领技能数据格式不正确');
    }
    return RemoteBossCatalog(
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      bosses: json['bosses'] as List<dynamic>,
      maxSkillRank:
          ((json['maxSkillRank'] as num?)?.toInt() ?? 10).clamp(1, 99),
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
