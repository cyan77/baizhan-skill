import 'package:baizhan_skill/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('editing a Boss type closes its menu and saves cleanly',
      (tester) async {
    final store = SkillStore();
    final boss = Boss(
        id: 'test-boss',
        name: '测试 Boss',
        spirit: 400,
        stamina: 400,
        skills: []);
    store.bosses.add(boss);

    await tester.pumpWidget(AnimatedBuilder(
        animation: store,
        builder: (context, child) => MaterialApp(
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () =>
                            showBossDialog(context, store, boss: boss),
                        child: const Text('编辑 Boss')))))));

    await tester.tap(find.text('编辑 Boss'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('普通'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('精英'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存 Boss'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(boss.type, '精英');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Boss attributes must add up to 800', (tester) async {
    final store = SkillStore();
    final boss = Boss(
        id: 'attribute-test',
        name: '属性测试',
        spirit: 400,
        stamina: 400,
        skills: []);
    store.bosses.add(boss);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showBossDialog(context, store, boss: boss),
                    child: const Text('编辑 Boss'))))));

    await tester.tap(find.text('编辑 Boss'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '精神提升'), '300');
    await tester.tap(find.text('保存 Boss'));
    await tester.pumpAndSettle();

    expect(find.text('精神提升与耐力提升相加必须等于 800'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(boss.spirit, 400);
    expect(boss.stamina, 400);
  });

  testWidgets('Boss management supports drag ordering', (tester) async {
    final store = SkillStore();
    store.bosses.addAll([
      Boss(id: 'first', name: '第一个 Boss', spirit: 0, stamina: 0, skills: []),
      Boss(id: 'second', name: '第二个 Boss', spirit: 0, stamina: 0, skills: [])
    ]);

    await tester.pumpWidget(MaterialApp(home: BossPage(store: store)));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byIcon(Icons.drag_indicator).first, const Offset(0, 220));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(store.bosses.map((boss) => boss.id), ['second', 'first']);
  });

  testWidgets('add character dialog lays out shared dropdowns cleanly',
      (tester) async {
    final store = SkillStore();

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showCharacterDialog(context, store),
                    child: const Text('添加角色'))))));

    await tester.tap(find.text('添加角色'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('新增角色'), findsOneWidget);
    expect(find.text('角色性别'), findsOneWidget);
    expect(find.text('门派'), findsOneWidget);
    expect(find.text('心法'), findsOneWidget);
    expect(find.text('定位'), findsOneWidget);
    expect(find.text('全部技能重数'), findsOneWidget);
    expect(find.text('导入 Excel'), findsOneWidget);
    expect(find.text('导入图片'), findsOneWidget);
    expect(find.text('预览技能与属性'), findsOneWidget);

    await tester.tap(find.text('预览技能与属性'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('角色技能预览'), findsOneWidget);
    expect(find.text('关闭预览'), findsOneWidget);
  });

  test('new characters default every skill to rank one and support batching',
      () {
    final store = SkillStore();
    store.bosses.add(Boss(
        id: 'boss',
        name: 'Boss',
        spirit: 400,
        stamina: 400,
        skills: [
          Skill(id: 'skill-a', name: '技能 A'),
          Skill(id: 'skill-b', name: '技能 B')
        ]));

    store.addCharacter(
        name: '角色', gender: '女性', school: '未设置', mind: '未设置', position: 'dps');
    final character = store.characters.single;
    expect(character.levels.values, everyElement(1));

    store.setAllSkillLevels(8, characterId: character.id);
    expect(character.levels.values, everyElement(8));
  });

  test('imported skill ranks override the selected default rank', () {
    final store = SkillStore();
    store.bosses.add(Boss(
        id: 'boss',
        name: 'Boss',
        spirit: 400,
        stamina: 400,
        skills: [
          Skill(id: 'skill-a', name: '技能 A'),
          Skill(id: 'skill-b', name: '技能 B')
        ]));

    store.addCharacter(
        name: '角色',
        gender: '女性',
        school: '未设置',
        mind: '未设置',
        position: 'dps',
        initialSkillLevel: 4,
        skillLevelsByName: const {'技能 A': 9});

    expect(store.characters.single.levels['skill-a'], 9);
    expect(store.characters.single.levels['skill-b'], 4);
  });

  test('male aliases map to shared skills and swap the gender Boss stats', () {
    final store = SkillStore();
    store.bosses.add(Boss(
        id: 'gender-boss',
        name: '杜姬欣/钱宗龙',
        spirit: 560,
        stamina: 240,
        skills: [
          Skill(id: 's1', name: '剑心通明'),
          Skill(id: 's2', name: '帝骖龙翔'),
          Skill(id: 's3', name: '水遁水流闪'),
          Skill(id: 's4', name: '蛮熊碎颅击')
        ]));

    store.addCharacter(
        name: '男角色',
        gender: '男性',
        school: '未设置',
        mind: '未设置',
        position: 'dps',
        skillLevelsByName: const {'巨猿劈山': 6, '顽抗': 7, '水遁水流闪': 8, '蛮熊碎颅击': 9});
    final character = store.characters.single;

    expect(character.levels['s1'], 6);
    expect(character.levels['s2'], 7);
    expect(character.levels['s3'], 8);
    expect(character.levels['s4'], 9);
    expect(bossNameForGender(store.bosses.single, character.gender), '钱宗龙');
    expect(skillNameForGender(store.bosses.single.skills[0], character.gender),
        '巨猿劈山');
    expect(skillNameForGender(store.bosses.single.skills[2], character.gender),
        '水遁水流闪');
    expect(skillNameForGender(store.bosses.single.skills[3], character.gender),
        '蛮熊碎颅击');
    expect(bossStatForGender(store.bosses.single, character.gender, true), 240);
    expect(
        bossStatForGender(store.bosses.single, character.gender, false), 560);
    expect(store.rankFor(character.id, store.bosses.single), 6);

    final female = CharacterData(
        id: 'female',
        name: '女角色',
        gender: '女性',
        school: '未设置',
        mind: '未设置',
        position: 'dps',
        levels: const {'s1': 5, 's2': 5, 's3': 5, 's4': 1});
    store.characters.add(female);
    expect(store.rankFor(female.id, store.bosses.single), 5);
  });

  test('characters can be reordered without disturbing archived entries', () {
    final store = SkillStore();
    store.characters.addAll([
      CharacterData(
          id: 'first',
          name: '角色一',
          gender: '女性',
          school: '未设置',
          mind: '未设置',
          position: 'dps',
          levels: {}),
      CharacterData(
          id: 'archived',
          name: '已归档',
          gender: '女性',
          school: '未设置',
          mind: '未设置',
          position: 'dps',
          levels: {},
          archived: true),
      CharacterData(
          id: 'second',
          name: '角色二',
          gender: '男性',
          school: '未设置',
          mind: '未设置',
          position: 'dps',
          levels: {})
    ]);

    store.reorderCharacter('second', 'first');

    expect(store.activeCharacters.map((item) => item.id), ['second', 'first']);
    expect(store.characters.map((item) => item.id),
        ['second', 'archived', 'first']);
  });
}
