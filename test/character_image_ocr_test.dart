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
}
