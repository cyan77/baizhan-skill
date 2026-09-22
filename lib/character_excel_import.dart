import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class CharacterExcelData {
  const CharacterExcelData(
      {required this.name, required this.gender, required this.skillLevels});

  final String name;
  final String gender;
  final Map<String, int> skillLevels;
}

class CharacterExcelParser {
  static CharacterExcelData parse(Uint8List bytes, {int maxSkillRank = 10}) {
    final archive = ZipDecoder().decodeBytes(bytes);
    String readEntry(String path) {
      final file = archive.findFile(path);
      if (file == null) throw const FormatException('Excel 文件结构不完整');
      return utf8.decode(file.content);
    }

    final workbook = XmlDocument.parse(readEntry('xl/workbook.xml'));
    final sheets = workbook.findAllElements('sheet').toList();
    if (sheets.length != 1) {
      throw const FormatException('角色 Excel 必须且只能包含一个 Sheet');
    }
    final sheetName = sheets.single.getAttribute('name')?.trim() ?? '';
    if (sheetName.isEmpty) throw const FormatException('无法读取角色名称');

    final relationshipId = sheets.single.attributes
        .where((attribute) => attribute.name.local == 'id')
        .map((attribute) => attribute.value)
        .firstOrNull;
    final relationships =
        XmlDocument.parse(readEntry('xl/_rels/workbook.xml.rels'));
    final target = relationships
        .findAllElements('Relationship')
        .where((element) => element.getAttribute('Id') == relationshipId)
        .map((element) => element.getAttribute('Target'))
        .firstOrNull;
    if (target == null) throw const FormatException('无法读取角色 Sheet');
    final sheetPath = target.startsWith('/')
        ? target.substring(1)
        : target.startsWith('xl/')
            ? target
            : 'xl/$target';

    final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
    final sharedStrings = sharedStringsFile == null
        ? <String>[]
        : XmlDocument.parse(utf8.decode(sharedStringsFile.content))
            .findAllElements('si')
            .map((item) =>
                item.findAllElements('t').map((text) => text.innerText).join())
            .toList();
    final cells = <String, String>{};
    final sheet = XmlDocument.parse(readEntry(sheetPath));
    for (final cell in sheet.findAllElements('c')) {
      final reference = cell.getAttribute('r');
      if (reference == null) continue;
      final type = cell.getAttribute('t');
      String value;
      if (type == 'inlineStr') {
        value = cell.findAllElements('t').map((item) => item.innerText).join();
      } else {
        value = cell.findElements('v').firstOrNull?.innerText ?? '';
        if (type == 's') {
          final index = int.tryParse(value);
          value = index != null && index >= 0 && index < sharedStrings.length
              ? sharedStrings[index]
              : '';
        }
      }
      cells[reference] = value.trim();
    }

    if (cells['A1'] != '角色性别' || cells['A4'] != '首领名字') {
      throw const FormatException('Excel 不是受支持的百战角色技能模板');
    }
    final gender = cells['A2'] ?? '';
    if (gender != '女性' && gender != '男性') {
      throw const FormatException('无法读取角色性别');
    }

    final levels = <String, int>{};
    for (var nameRow = 5; nameRow <= 69; nameRow += 2) {
      for (final column in const ['B', 'C', 'D', 'E', 'F', 'G']) {
        final skillName = cells['$column$nameRow']?.trim() ?? '';
        if (skillName.isEmpty) continue;
        final parsed = int.tryParse(cells['$column${nameRow + 1}'] ?? '');
        levels[skillName] = (parsed ?? 1).clamp(1, maxSkillRank).toInt();
      }
    }
    return CharacterExcelData(
        name: sheetName, gender: gender, skillLevels: levels);
  }
}
