import 'dart:convert';
import 'dart:io';

const windowsPortableAssetName = 'BaizhanSkill-Windows-x64.zip';
const windowsInstallerAssetName = 'BaizhanSkill-Windows-x64-Setup.exe';
const macosInstallerAssetName = 'BaizhanSkill-macOS-Setup.pkg';
const windowsInstallMarkerName = '.baizhanskill-installed';

class AppRelease {
  const AppRelease({
    required this.version,
    required this.notes,
    required this.pageUri,
    required this.assets,
  });

  final String version;
  final String notes;
  final Uri pageUri;
  final Map<String, Uri> assets;

  Uri? get platformDownloadUri {
    final candidates = Platform.isWindows
        ? [windowsUpdateAssetName(installed: isWindowsInstalledBuild())]
        : Platform.isMacOS
            ? const [macosInstallerAssetName]
            : const <String>[];
    for (final name in candidates) {
      final uri = assets[name];
      if (uri != null) return uri;
    }
    return Platform.isWindows || Platform.isMacOS ? null : pageUri;
  }

  String get platformDownloadLabel {
    if (Platform.isWindows) {
      return isWindowsInstalledBuild() ? '下载 Windows 安装版' : '下载 Windows 便携版';
    }
    if (Platform.isMacOS) return '下载 macOS 安装版';
    return '打开发布页';
  }
}

String windowsUpdateAssetName({required bool installed}) =>
    installed ? windowsInstallerAssetName : windowsPortableAssetName;

bool isWindowsInstalledBuild() {
  if (!Platform.isWindows) return false;
  final executable = File(Platform.resolvedExecutable);
  final marker = File(
      '${executable.parent.path}${Platform.pathSeparator}$windowsInstallMarkerName');
  return marker.existsSync() ||
      isWindowsInstalledExecutablePath(executable.path);
}

bool isWindowsInstalledExecutablePath(String executablePath) {
  final normalized = executablePath.replaceAll('\\', '/').toLowerCase();
  return normalized.contains('/program files/') ||
      normalized.contains('/program files (x86)/');
}

class UpdateService {
  static final Uri _latestReleaseApi = Uri.https(
    'api.github.com',
    '/repos/cyan77/baizhan-skill/releases/latest',
  );

  Future<AppRelease> fetchLatestRelease() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(_latestReleaseApi);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'Baizhan-Skill-Update-Checker');
      final response =
          await request.close().timeout(const Duration(seconds: 12));
      final raw = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GitHub 返回 ${response.statusCode}');
      }
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('更新信息格式无效');
      }
      final tag = json['tag_name'] as String?;
      final page = Uri.tryParse(json['html_url'] as String? ?? '');
      if (tag == null || page == null || !_isTrustedGitHubUri(page)) {
        throw const FormatException('更新信息缺少有效版本或下载地址');
      }
      final assets = <String, Uri>{};
      for (final item in json['assets'] as List? ?? const []) {
        if (item is! Map) continue;
        final name = item['name'] as String?;
        final uri = Uri.tryParse(item['browser_download_url'] as String? ?? '');
        if (name != null && uri != null && _isTrustedGitHubUri(uri)) {
          assets[name] = uri;
        }
      }
      return AppRelease(
        version: tag.replaceFirst(RegExp(r'^v'), ''),
        notes: json['body'] as String? ?? '',
        pageUri: page,
        assets: assets,
      );
    } finally {
      client.close(force: true);
    }
  }
}

bool isVersionNewer(String candidate, String current) {
  List<int> parts(String value) => value
      .replaceFirst(RegExp(r'^v'), '')
      .split(RegExp(r'[-+]'))
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();

  final candidateParts = parts(candidate);
  final currentParts = parts(current);
  final count = candidateParts.length > currentParts.length
      ? candidateParts.length
      : currentParts.length;
  for (var index = 0; index < count; index++) {
    final next = index < candidateParts.length ? candidateParts[index] : 0;
    final installed = index < currentParts.length ? currentParts[index] : 0;
    if (next != installed) return next > installed;
  }
  return false;
}

bool _isTrustedGitHubUri(Uri uri) =>
    uri.scheme == 'https' &&
    uri.host == 'github.com' &&
    uri.path.startsWith('/cyan77/baizhan-skill/');
