import 'package:baizhan_skill/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SkillStore testStore() {
    final store = SkillStore();
    store.bosses
        .add(Boss(id: 'boss', name: '测试', spirit: 400, stamina: 400, skills: [
      Skill(id: 'one', name: '万花金创药'),
      Skill(id: 'two', name: '阴阳术退散'),
      Skill(id: 'three', name: '火魅指'),
      Skill(id: 'four', name: '画影飞赴'),
    ]));
    return store;
  }

  test('assumes the clipped first section is ten ranks', () {
    final result = parseCharacterImageOcr([
      {'text': '万花金创药'},
      {'text': '阴阳术退散'},
      {'text': '九重'},
      {'text': '火魅指'},
    ], testStore(), '女性');

    expect(result['万花金创药'], 10);
    expect(result['阴阳术退散'], 10);
    expect(result['火魅指'], 9);
  });

  test('matches small OCR errors and multiple columns in one line', () {
    final result = parseCharacterImageOcr([
      {'text': '万花金剑药 阴阳术退敞'},
      {'text': '九重'},
      {'text': '画影飞赴'},
    ], testStore(), '女性');

    expect(result['万花金创药'], 10);
    expect(result['阴阳术退散'], 10);
    expect(result['画影飞赴'], 9);
  });

  test('ignores an implausible one-rank heading in the ten-rank section', () {
    final result = parseCharacterImageOcr([
      {'text': '十重'},
      {'text': '万花金创药'},
      {'text': '一重'}, // Windows OCR can misread a small rank heading.
      {'text': '阴阳术退散'},
      {'text': '九重'},
      {'text': '火魅指'},
    ], testStore(), '女性');

    expect(result['万花金创药'], 10);
    expect(result['阴阳术退散'], 10);
    expect(result['火魅指'], 9);
  });

  test('assigns three-column skills by heading position, not OCR line order', () {
    final result = parseCharacterImageOcr([
      {'text': '火魅指', 'x': 0.75, 'y': 0.34},
      {'text': '画影飞赴', 'x': 0.35, 'y': 0.54},
      {'text': '万花金创药', 'x': 0.06, 'y': 0.09},
      {'text': '八重', 'x': 0.07, 'y': 0.50},
      {'text': '九重', 'x': 0.07, 'y': 0.30},
      {'text': '阴阳术退散', 'x': 0.73, 'y': 0.10},
    ], testStore(), '女性');

    expect(result['万花金创药'], 10);
    expect(result['阴阳术退散'], 10);
    expect(result['火魅指'], 9);
    expect(result['画影飞赴'], 8);
  });
}
