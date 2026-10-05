import 'package:baizhan_skill/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  SkillStore fixture() {
    final store = SkillStore();
    store.bosses.add(
      Boss(
        id: 'boss',
        name: '快照首领',
        type: '精英',
        spirit: 200,
        stamina: 200,
        skills: [Skill(id: 'skill', name: '快照技能', tradable: true)],
      ),
    );
    store.characters.add(
      CharacterData(
        id: 'character',
        name: '快照角色',
        gender: '女性',
        school: '万花',
        mind: '花间游',
        position: '输出',
        levels: const {'skill': 9},
      ),
    );
    store.selectedCharacterId = 'character';
    return store;
  }

  Future<void> mount(WidgetTester tester, SkillStore store, Widget Function() page) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(animation: store, builder: (_, __) => page()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final pageId in [1, 2]) {
    testWidgets(
      'summary $pageId retains ranks and incomplete character pairs',
      (tester) async {
        final store = fixture();
        store.skillPageFilters[pageId] = (
          characterId: 'all',
          maxRank: 9,
          query: '',
        );
        await mount(
          tester,
          store,
          () => SkillSummaryFilters(
            store: store,
            pageId: pageId,
            skillNames: const ['快照技能'],
            accent: teal,
          ),
        );
        await tester.tap(find.text('只看未完成'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('快照技能'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('增加一重'));
        await tester.pumpAndSettle();
        expect(store.level('character', 'skill'), 10);
        expect(find.text('快照技能'), findsOneWidget);
        expect(find.text('快照角色'), findsOneWidget);
        expect(find.text('1/1 个角色已全部收集'), findsOneWidget);
        await tester.tap(find.text('重新筛选'));
        await tester.pumpAndSettle();
        expect(find.text('快照技能'), findsNothing);
        await tester.tap(find.text('重置筛选'));
        await tester.pumpAndSettle();
        expect(find.text('快照技能'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('boss rank results survive 9 to 10 until reapplication', (
    tester,
  ) async {
    final store = fixture();
    store.skillPageFilters[3] = (
      characterId: 'character',
      maxRank: 9,
      query: '',
    );
    await mount(tester, store, () => AllSkillsPage(store: store));
    store.setLevelForCharacter('character', 'skill', 10);
    await tester.pumpAndSettle();
    expect(find.text('快照首领'), findsOneWidget);
    await tester.tap(find.text('重新筛选'));
    await tester.pumpAndSettle();
    expect(find.text('快照首领'), findsNothing);
    await tester.tap(find.text('重置筛选'));
    await tester.pumpAndSettle();
    expect(find.text('快照首领'), findsOneWidget);
  });

  testWidgets('existing skills retain edited ranks and boss names', (tester) async {
    final store = fixture();
    await mount(tester, store, () => ExistingSkillsPanel(
      store: store, character: store.characters.single));
    await tester.tap(find.text('全部重数'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9 重及以下'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '快照');
    await tester.pumpAndSettle();
    store.bosses.single.name = '编辑后首领';
    store.setLevelForCharacter('character', 'skill', 10);
    await tester.pumpAndSettle();
    expect(find.text('快照技能'), findsOneWidget);
    expect(find.text('编辑后首领'), findsOneWidget);
    expect(find.text('10 重'), findsOneWidget);
    await tester.tap(find.text('重新筛选'));
    await tester.pumpAndSettle();
    expect(find.text('快照技能'), findsNothing);
    await tester.tap(find.text('重置筛选'));
    await tester.pumpAndSettle();
    expect(find.text('快照技能'), findsOneWidget);
  });

  testWidgets('changing a condition reapplies the entire progress filter', (tester) async {
    final store = fixture();
    await mount(tester, store, () => AllSkillsPage(store: store));
    await tester.tap(find.text('首领进度'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('只看未完成'));
    await tester.pumpAndSettle();
    store.setLevelForCharacter('character', 'skill', 10);
    await tester.pumpAndSettle();
    expect(find.text('快照首领'), findsOneWidget);
    await tester.enterText(find.byWidgetPredicate((widget) =>
      widget is TextField && widget.decoration?.hintText == '全部首领'), '快照');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('快照首领'), findsNothing);
    await tester.tap(find.text('重置筛选'));
    await tester.pumpAndSettle();
    expect(find.text('快照首领'), findsOneWidget);
    await tester.tap(find.text('全部类型'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('精英').last);
    await tester.pumpAndSettle();
    store.bosses.single.type = '普通';
    store.setWeeklyCompleted(store.characters.single, false);
    await tester.pumpAndSettle();
    expect(find.text('快照首领'), findsOneWidget);
    await tester.tap(find.text('重新筛选'));
    await tester.pumpAndSettle();
    expect(find.text('快照首领'), findsNothing);
  });

  testWidgets(
    'boss progress retains both the boss and its completed character',
    (tester) async {
      final store = fixture();
      await mount(tester, store, () => AllSkillsPage(store: store));
      await tester.tap(find.text('首领进度'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('只看未完成'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('快照首领'));
      await tester.pumpAndSettle();
      store.setLevelForCharacter('character', 'skill', 10);
      await tester.pumpAndSettle();
      expect(find.text('快照首领'), findsOneWidget);
      expect(find.text('快照角色'), findsOneWidget);
      expect(find.textContaining('1/1 个角色已全部收集'), findsOneWidget);
      await tester.tap(find.text('重新筛选'));
      await tester.pumpAndSettle();
      expect(find.text('快照首领'), findsNothing);
      await tester.tap(find.text('重置筛选'));
      await tester.pumpAndSettle();
      expect(find.text('快照首领'), findsOneWidget);
    },
  );

  testWidgets('home CD results retain completed characters', (tester) async {
    final store = fixture()..homeCdFilter = '未完成';
    await mount(tester, store, () => HomePage(store: store));
    store.setWeeklyCompleted(store.characters.single, true);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CharacterSwitcher>(find.byType(CharacterSwitcher))
          .characters,
      hasLength(1),
    );
    await tester.tap(find.text('重新筛选').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CharacterSwitcher>(find.byType(CharacterSwitcher))
          .characters,
      isEmpty,
    );
    await tester.tap(find.text('重置筛选').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CharacterSwitcher>(find.byType(CharacterSwitcher))
          .characters,
      hasLength(1),
    );
  });

  testWidgets('character edits do not reapply name, gender or school filters', (
    tester,
  ) async {
    final store = fixture()
      ..characterSearch = '快照'
      ..characterGenderFilter = '女性'
      ..characterSchoolFilter = '万花';
    await mount(tester, store, () => CharacterFilterPanel(store: store));
    final character = store.characters.single;
    character.name = '编辑后角色';
    character.gender = '男性';
    character.school = '天策';
    store.setWeeklyCompleted(store.characters.single, false);
    await tester.pumpAndSettle();
    expect(find.text('编辑后角色'), findsOneWidget);
    await tester.tap(find.text('重新筛选'));
    await tester.pumpAndSettle();
    expect(find.text('编辑后角色'), findsNothing);
    await tester.tap(find.text('重置筛选'));
    await tester.pumpAndSettle();
    expect(find.text('编辑后角色'), findsOneWidget);
  });
}
