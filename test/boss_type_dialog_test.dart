import 'package:baizhan_skill/main.dart';
import 'package:baizhan_skill/boss_catalog_service.dart';
import 'package:baizhan_skill/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekly CD uses Monday as the start of each week', () {
    expect(currentWeekKey(DateTime(2026, 9, 21)), '2026-09-21');
    expect(currentWeekKey(DateTime(2026, 9, 27)), '2026-09-21');
    expect(currentWeekKey(DateTime(2026, 9, 28)), '2026-09-28');
  });

  test('Boss collection progress uses the next rank target', () {
    final store = SkillStore();
    final boss = Boss(
        id: 'progress-boss',
        name: '进度 Boss',
        spirit: 240,
        stamina: 560,
        skills: List.generate(
            4, (index) => Skill(id: 'progress-$index', name: '技能$index')));
    final character = CharacterData(
        id: 'progress-character',
        name: '进度角色',
        gender: '女性',
        school: '未设置',
        mind: '未设置',
        position: 'dps',
        levels: const {
          'progress-0': 8,
          'progress-1': 8,
          'progress-2': 9,
          'progress-3': 10
        });
    store.bosses.add(boss);
    store.characters.add(character);

    final progress = bossCollectionProgress(store, character, boss);
    expect(progress.completedRank, 8);
    expect(progress.strategyRank, 9);
    expect(progress.collectedSkills, 2);
    expect(progress.totalSkills, 4);
    expect(chineseRankLabel(progress.strategyRank), '九重');
  });

  testWidgets('all skills strategy header toggles Boss ordering',
      (tester) async {
    final store = SkillStore();
    final highBoss = Boss(
        id: 'high-boss',
        name: '高进度首领',
        spirit: 400,
        stamina: 400,
        skills: [Skill(id: 'high-skill', name: '高进度技能')]);
    final lowBoss = Boss(
        id: 'low-boss',
        name: '低进度首领',
        spirit: 400,
        stamina: 400,
        skills: [Skill(id: 'low-skill', name: '低进度技能')]);
    final character = CharacterData(
        id: 'sort-character',
        name: '排序角色',
        gender: '女性',
        school: '未设置',
        mind: '未设置',
        position: 'dps',
        levels: const {'high-skill': 9, 'low-skill': 7});
    store.bosses.addAll([lowBoss, highBoss]);
    store.characters.add(character);
    store.selectedCharacterId = character.id;

    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AllSkillsPage(store: store))));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('低进度首领')).dy,
        lessThan(tester.getTopLeft(find.text('高进度首领')).dy));

    await tester.tap(find.text('攻略进度'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('高进度首领')).dy,
        lessThan(tester.getTopLeft(find.text('低进度首领')).dy));

    await tester.tap(find.text('攻略进度'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('低进度首领')).dy,
        lessThan(tester.getTopLeft(find.text('高进度首领')).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('character preview expands skills and edits their ranks',
      (tester) async {
    final store = SkillStore();
    final skill = Skill(id: 'preview-skill', name: '预览技能');
    store.bosses.add(Boss(
        id: 'preview-boss',
        name: '预览首领',
        spirit: 240,
        stamina: 560,
        skills: [skill]));
    final overrides = <String, int>{};

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showCharacterDraftPreview(
                        context, store, overrides, 1, '女性'),
                    child: const Text('打开预览'))))));
    await tester.tap(find.text('打开预览'));
    await tester.pumpAndSettle();

    expect(find.text('攻略进度'), findsOneWidget);
    expect(find.text('收集进度'), findsOneWidget);
    expect(find.text('精神'), findsOneWidget);
    expect(find.text('耐力'), findsOneWidget);
    await tester.tap(find.text('预览首领'));
    await tester.pumpAndSettle();
    expect(find.text('预览技能'), findsOneWidget);
    expect(find.text('1 重'), findsOneWidget);

    await tester.tap(find.text('1 重'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 重').last);
    await tester.pumpAndSettle();
    expect(overrides['预览技能'], 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home book needs fits inside a narrow fourth card',
      (tester) async {
    final store = SkillStore();
    final character = CharacterData(
        id: 'narrow-home',
        name: '测试角色',
        gender: '女性',
        school: '未设置',
        mind: '未设置',
        position: 'dps',
        levels: const {'one': 1, 'two': 10});

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                    width: 136,
                    child:
                        HomeBookNeeds(store: store, character: character))))));

    expect(tester.takeException(), isNull);
    expect(find.text('通本4'), findsOneWidget);
  });

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
                        child: const Text('编辑首领')))))));

    await tester.tap(find.text('编辑首领'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('普通'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('精英'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存首领'));
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
                    child: const Text('编辑首领'))))));

    await tester.tap(find.text('编辑首领'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '精神提升'), '300');
    await tester.tap(find.text('保存首领'));
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

  testWidgets('closing max skill rank dialog disposes cleanly', (tester) async {
    final store = SkillStore();
    await tester.pumpWidget(MaterialApp(home: BossPage(store: store)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('最高重 10 重'));
    await tester.pumpAndSettle();
    expect(find.text('设置技能最高重'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('设置技能最高重'), findsNothing);
    expect(tester.takeException(), isNull);
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
    expect(find.text('换将点'), findsOneWidget);
    expect(find.text('本周 CD 已完成'), findsOneWidget);
    expect(find.text('全部技能重数'), findsOneWidget);
    expect(find.text('导入 Excel'), findsOneWidget);
    expect(find.text('导入图片'), findsOneWidget);
    expect(find.text('预览技能与属性'), findsOneWidget);

    await tester.ensureVisible(find.text('预览技能与属性'));
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

  test('remote Boss updates preserve ranks and default new skills to one',
      () async {
    final store = SkillStore();
    store.bosses.add(Boss(
        id: 'boss-a',
        name: '旧 Boss',
        spirit: 400,
        stamina: 400,
        skills: [Skill(id: 'skill-a', name: '保留技能')]));
    store.characters.add(CharacterData(
        id: 'character',
        name: '角色',
        gender: '女性',
        school: '未设置',
        mind: '未设置',
        position: 'dps',
        levels: const {'skill-a': 8}));
    store.availableBossCatalog = const RemoteBossCatalog(
        version: 2,
        updatedAt: '2026-09-21',
        notes: '测试更新',
        bosses: [
          {
            'id': 'boss-a',
            'name': '新 Boss',
            'type': '精英',
            'spirit': 240,
            'stamina': 560,
            'skills': [
              {'id': 'skill-a', 'name': '保留技能', 'tradable': false},
              {'id': 'skill-b', 'name': '新增技能', 'tradable': true}
            ]
          }
        ]);

    await store.applyBossCatalogUpdate();

    expect(store.bossCatalogVersion, 2);
    expect(store.bosses.single.name, '新 Boss');
    expect(store.characters.single.levels['skill-a'], 8);
    expect(store.characters.single.levels['skill-b'], 1);
    expect(store.purpleSkills, contains('新增技能'));
  });

  test('newer cloud backup is detected before upload and prevents overwrite',
      () async {
    final service = _FakeWebDavSyncService();
    final store = SkillStore(webDavSyncService: service)
      ..syncConfig = const SyncConfig(
          url: 'https://example.com',
          username: 'user',
          password: 'password',
          remotePath: '/backup.json')
      ..lastSyncAt = DateTime(2026, 9, 20);

    final checked = await store.checkForNewerBackup();
    final synced = await store.syncNow();

    expect(checked, isTrue);
    expect(store.newerRemoteBackup?.path, '/newer.json');
    expect(synced, isFalse);
    expect(service.uploadCalled, isFalse);
    expect(store.syncMessage, contains('请先恢复'));
  });

  test('invalid cloud backup does not erase current local data', () async {
    final service = _FakeWebDavSyncService(
        downloadPayload: '{"characters": [], "importantSkills": []}');
    final store = SkillStore(webDavSyncService: service)
      ..syncConfig = const SyncConfig(
          url: 'https://example.com',
          username: 'user',
          password: 'password',
          remotePath: '/backup.json')
      ..bosses.add(Boss(
          id: 'safe-boss',
          name: '保留 Boss',
          spirit: 400,
          stamina: 400,
          skills: []));

    final restored = await store.restoreRemoteBackup(
        const RemoteBackup(name: 'broken.json', path: '/broken.json'));

    expect(restored, isFalse);
    expect(store.bosses.single.name, '保留 Boss');
  });

  testWidgets('remote backup list marks latest and current versions',
      (tester) async {
    final store = SkillStore()
      ..syncConfig = const SyncConfig(
          url: 'https://example.com',
          username: 'user',
          password: 'password',
          remotePath: '/backup.json')
      ..currentRemoteBackupPath = '/latest.json'
      ..remoteBackups = const [
        RemoteBackup(name: '最新备份', path: '/latest.json'),
        RemoteBackup(name: '历史备份', path: '/older.json')
      ];

    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SyncBackupPage(store: store))));
    await tester.pumpAndSettle();

    expect(find.text('当前'), findsOneWidget);
    expect(find.text('最新'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeWebDavSyncService extends WebDavSyncService {
  _FakeWebDavSyncService({this.downloadPayload = '{}'});

  final String downloadPayload;
  bool uploadCalled = false;

  @override
  Future<List<RemoteBackup>> listBackups(SyncConfig config) async => [
        RemoteBackup(
            name: 'backup_20260921_120000000_device.json',
            path: '/newer.json',
            modifiedAt: DateTime(2026, 9, 21, 12))
      ];

  @override
  Future<RemoteBackup> upload(SyncConfig config, String json) async {
    uploadCalled = true;
    return const RemoteBackup(name: 'uploaded.json', path: '/uploaded.json');
  }

  @override
  Future<String> downloadBackup(SyncConfig config, RemoteBackup backup) async =>
      downloadPayload;
}
