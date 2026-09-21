import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final version = args.isEmpty ? 1 : int.parse(args.first);
  final result = await Process.run('defaults', [
    'read',
    'lynn.game.jx3.baizhan',
    'flutter.battle_skill_data_v3',
  ]);
  if (result.exitCode != 0) {
    stderr.writeln('没有找到已安装应用的 Boss 技能数据。');
    exitCode = 1;
    return;
  }

  final defaultsJson = (result.stdout as String).replaceAllMapped(
      RegExp(r'\\([0-7]{3})'),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 8)));
  final appData = jsonDecode(defaultsJson) as Map<String, dynamic>;
  final catalog = <String, dynamic>{
    'type': 'baizhan-bosses',
    'version': version,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
    'notes': 'Boss 技能基础数据',
    'bosses': appData['bosses'],
  };
  final output = File('data/baizhan-bosses.json');
  await output.parent.create(recursive: true);
  await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(catalog)}\n');
  stdout.writeln('已生成 ${output.path}（数据版本 $version）');
}
