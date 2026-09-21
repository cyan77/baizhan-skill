import 'dart:convert';
import 'dart:io';

class RemoteBossCatalog {
  const RemoteBossCatalog({
    required this.version,
    required this.updatedAt,
    required this.notes,
    required this.bosses,
  });

  final int version;
  final String updatedAt;
  final String notes;
  final List<dynamic> bosses;

  factory RemoteBossCatalog.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'baizhan-bosses' || json['bosses'] is! List) {
      throw const FormatException('Boss 技能数据格式不正确');
    }
    return RemoteBossCatalog(
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      bosses: json['bosses'] as List<dynamic>,
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
        throw HttpException('获取 Boss 技能数据失败：${response.statusCode}');
      }
      final text = await utf8.decoder.bind(response).join();
      return RemoteBossCatalog.fromJson(
          jsonDecode(text) as Map<String, dynamic>);
    } finally {
      client.close(force: true);
    }
  }
}
