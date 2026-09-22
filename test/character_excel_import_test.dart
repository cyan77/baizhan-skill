import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:baizhan_skill/character_excel_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a supported single-sheet character workbook', () {
    final data = CharacterExcelParser.parse(_characterWorkbook());

    expect(data.name, '测试角色');
    expect(data.gender, '女性');
    expect(data.skillLevels, {'万花金创药': 8});
  });

  test('rejects damaged workbooks with a readable format error', () {
    expect(() => CharacterExcelParser.parse(Uint8List.fromList([1, 2, 3])),
        throwsA(anyOf(isA<FormatException>(), isA<ArchiveException>())));
  });
}

Uint8List _characterWorkbook() {
  final archive = Archive()
    ..addFile(ArchiveFile.string('xl/workbook.xml', '''
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets><sheet name="测试角色" sheetId="1" r:id="rId1"/></sheets>
</workbook>'''))
    ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', '''
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Target="worksheets/sheet1.xml"/>
</Relationships>'''))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', '''
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="1"><c r="A1" t="inlineStr"><is><t>角色性别</t></is></c></row>
    <row r="2"><c r="A2" t="inlineStr"><is><t>女性</t></is></c></row>
    <row r="4"><c r="A4" t="inlineStr"><is><t>首领名字</t></is></c></row>
    <row r="5"><c r="B5" t="inlineStr"><is><t>万花金创药</t></is></c></row>
    <row r="6"><c r="B6"><v>8</v></c></row>
  </sheetData>
</worksheet>'''));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
