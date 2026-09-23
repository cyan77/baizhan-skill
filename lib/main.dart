import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'boss_catalog_service.dart';
import 'character_excel_import.dart';
import 'seed_data.dart';
import 'sync_service.dart';
import 'theme_settings.dart';
import 'update_service.dart';

const navy = Color(0xffffffff);
const ink = Color(0xff26332f);
const muted = Color(0xff76857f);
const canvas = Color(0xffffffff);
const line = Color(0xffe4eae7);
const teal = Color(0xff3c8c72);
const purple = Color(0xff8d54c7);
const gold = Color(0xffb56a18);
const formLabelStyle = TextStyle(
    color: muted, fontSize: 12, fontWeight: FontWeight.w400, height: 1.1);

class NavigationPageOption {
  const NavigationPageOption(
      {required this.id,
      required this.label,
      required this.icon,
      required this.page});
  final String id;
  final String label;
  final IconData icon;
  final int page;
}

const navigationPageOptions = <NavigationPageOption>[
  NavigationPageOption(
      id: 'important', label: '重要技能', icon: Icons.star_border, page: 1),
  NavigationPageOption(
      id: 'tradable',
      label: '可交易技能',
      icon: Icons.auto_awesome_outlined,
      page: 2),
  NavigationPageOption(
      id: 'all', label: '所有技能', icon: Icons.account_tree_outlined, page: 3),
  NavigationPageOption(
      id: 'characters', label: '角色管理', icon: Icons.groups_outlined, page: 5),
  NavigationPageOption(
      id: 'bosses', label: '首领管理', icon: Icons.edit_note_outlined, page: 6),
];

const defaultNavigationOrder = [
  'important',
  'tradable',
  'all',
  'characters',
  'bosses'
];
const defaultNavigationVisible = ['important', 'tradable', 'all'];

const schoolOptions = [
  '未设置',
  '七秀',
  '万花',
  '五毒',
  '长歌',
  '药宗',
  '天策',
  '少林',
  '明教',
  '苍云',
  '纯阳',
  '唐门',
  '藏剑',
  '丐帮',
  '霸刀',
  '蓬莱',
  '凌雪',
  '衍天',
  '刀宗',
  '万灵',
  '段氏',
  '无相'
];

const schoolMindPositions = <String, Map<String, String>>{
  '七秀': {'冰心诀': '输出', '云裳心经': '治疗'},
  '万花': {'花间游': '输出', '离经易道': '治疗'},
  '五毒': {'毒经': '输出', '补天诀': '治疗'},
  '长歌': {'莫问': '输出', '相知': '治疗'},
  '药宗': {'无方': '输出', '灵素': '治疗'},
  '天策': {'傲血战意': '输出', '铁牢律': '防御'},
  '少林': {'易筋经': '输出', '洗髓经': '防御'},
  '明教': {'焚影圣诀': '输出', '明尊琉璃体': '防御'},
  '苍云': {'分山劲': '输出', '铁骨衣': '防御'},
  '纯阳': {'紫霞功': '输出', '太虚剑意': '输出'},
  '唐门': {'天罗诡道': '输出', '惊羽诀': '输出'},
  '藏剑': {'问水诀': '输出', '山居剑意': '输出'},
  '丐帮': {'笑尘诀': '输出'},
  '霸刀': {'北傲诀': '输出'},
  '蓬莱': {'凌海诀': '输出'},
  '凌雪': {'隐龙诀': '输出'},
  '衍天': {'太玄经': '输出'},
  '刀宗': {'孤峰诀': '输出'},
  '万灵': {'山海心诀': '输出'},
  '段氏': {'周天功': '输出'},
  '无相': {'幽罗引': '输出'},
};

const positionOptions = ['输出', '治疗', '防御'];

const mindIconAssets = <String, String>{
  '冰心诀': 'assets/minds/bingxin.jpg',
  '云裳心经': 'assets/minds/yunshang.jpg',
  '花间游': 'assets/minds/huajian.jpg',
  '离经易道': 'assets/minds/lijing.jpg',
  '毒经': 'assets/minds/dujing.jpg',
  '补天诀': 'assets/minds/butian.jpg',
  '莫问': 'assets/minds/mowen.jpg',
  '相知': 'assets/minds/xiangzhi.jpg',
  '无方': 'assets/minds/wufang.jpg',
  '灵素': 'assets/minds/lingsu.jpg',
  '傲血战意': 'assets/minds/aoxue.jpg',
  '铁牢律': 'assets/minds/tielao.jpg',
  '易筋经': 'assets/minds/yijin.jpg',
  '洗髓经': 'assets/minds/xisui.jpg',
  '焚影圣诀': 'assets/minds/fenying.jpg',
  '明尊琉璃体': 'assets/minds/mingzun.jpg',
  '分山劲': 'assets/minds/fenshan.jpg',
  '铁骨衣': 'assets/minds/tiegu.jpg',
  '紫霞功': 'assets/minds/zixia.jpg',
  '太虚剑意': 'assets/minds/taixu.jpg',
  '天罗诡道': 'assets/minds/tianluo.jpg',
  '惊羽诀': 'assets/minds/jingyu.jpg',
  '问水诀': 'assets/minds/wenshui.jpg',
  '山居剑意': 'assets/minds/shanju.jpg',
  '笑尘诀': 'assets/minds/xiaochen.jpg',
  '北傲诀': 'assets/minds/beiao.jpg',
  '凌海诀': 'assets/minds/linghai.jpg',
  '隐龙诀': 'assets/minds/yinlong.jpg',
  '太玄经': 'assets/minds/taixuan.jpg',
  '孤峰诀': 'assets/minds/gufeng.jpg',
  '山海心诀': 'assets/minds/shanhai.jpg',
  '周天功': 'assets/minds/zhoutian.png',
  '幽罗引': 'assets/minds/youluo.png',
};

String normalizePosition(String value) =>
    const {
      'dps': '输出',
      '奶': '治疗',
      't': '防御',
    }[value] ??
    value;

String normalizeSchool(String value) =>
    const {
      '衍天宗': '衍天',
      '凌雪阁': '凌雪',
      '北天药宗': '药宗',
    }[value] ??
    value;

String normalizeMind(String value) =>
    const {
      '问水诀/山居剑意': '问水诀',
      '孤锋诀': '孤峰诀',
    }[value] ??
    value;

String currentWeekKey([DateTime? now]) {
  final date = (now ?? DateTime.now()).toLocal();
  final monday = DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: date.weekday - DateTime.monday));
  String two(int value) => value.toString().padLeft(2, '0');
  return '${monday.year}-${two(monday.month)}-${two(monday.day)}';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SkillStore();
  await store.load();
  runApp(BattleSkillsApp(store: store));
}

class Skill {
  Skill({required this.id, required this.name, this.tradable = false});
  final String id;
  String name;
  bool tradable;
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'tradable': tradable};
  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      tradable: json['tradable'] as bool? ?? false);
}

class Boss {
  Boss(
      {required this.id,
      required this.name,
      required this.spirit,
      required this.stamina,
      required this.skills,
      this.type = '普通'});
  final String id;
  String name;
  String type;
  double spirit;
  double stamina;
  final List<Skill> skills;
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'spirit': spirit,
        'stamina': stamina,
        'skills': skills.map((skill) => skill.toJson()).toList()
      };
  factory Boss.fromJson(Map<String, dynamic> json) => Boss(
      id: json['id'] as String,
      name: json['name'] as String,
      type: bossTypeOptions.contains(json['type'])
          ? json['type'] as String
          : '普通',
      spirit: (json['spirit'] as num).toDouble(),
      stamina: (json['stamina'] as num).toDouble(),
      skills: (json['skills'] as List)
          .map((item) => Skill.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList());
}

const bossTypeOptions = ['普通', '精英', '异象'];

String bossNameForGender(Boss boss, String gender) {
  if (boss.name == '杜姬欣' || boss.name == '杜姬欣/钱宗龙') {
    return gender == '男性' ? '钱宗龙' : '杜姬欣';
  }
  return boss.name;
}

String skillNameForGender(Skill skill, String gender) {
  if (gender != '男性') return skill.name;
  return const {'剑心通明': '巨猿劈山', '帝骖龙翔': '顽抗'}[skill.name] ?? skill.name;
}

bool skillAppliesToGender(Skill skill, String gender) =>
    skill.name != '蛮熊碎颅击' || gender == '男性';

class BossCollectionProgress {
  const BossCollectionProgress(
      {required this.completedRank,
      required this.strategyRank,
      required this.collectedSkills,
      required this.totalSkills});

  final int completedRank;
  final int strategyRank;
  final int collectedSkills;
  final int totalSkills;

  double get collectionRatio =>
      totalSkills == 0 ? 0 : collectedSkills / totalSkills;
}

BossCollectionProgress bossCollectionProgress(
    SkillStore store, CharacterData character, Boss boss) {
  return bossCollectionProgressForLevels(boss, character.gender,
      (skill) => store.level(character.id, skill.id), store.maxSkillRank);
}

BossCollectionProgress bossCollectionProgressForLevels(
    Boss boss, String gender, int Function(Skill skill) levelFor,
    [int maxSkillRank = 10]) {
  final skills = boss.skills
      .where((skill) => skillAppliesToGender(skill, gender))
      .toList();
  if (skills.isEmpty) {
    return const BossCollectionProgress(
        completedRank: 0, strategyRank: 0, collectedSkills: 0, totalSkills: 0);
  }
  final levels =
      skills.map((skill) => levelFor(skill).clamp(0, maxSkillRank)).toList();
  final completedRank = levels.reduce(math.min);
  final strategyRank = math.min(maxSkillRank, completedRank + 1);
  final collectedSkills = levels.where((level) => level >= strategyRank).length;
  return BossCollectionProgress(
      completedRank: completedRank,
      strategyRank: strategyRank,
      collectedSkills: collectedSkills,
      totalSkills: skills.length);
}

String chineseRankLabel(int rank) {
  if (rank > 10) return '$rank 重';
  return const [
    '未开始',
    '一重',
    '二重',
    '三重',
    '四重',
    '五重',
    '六重',
    '七重',
    '八重',
    '九重',
    '十重'
  ][rank.clamp(0, 10)];
}

String managementSkillName(Skill skill) =>
    const {'剑心通明': '剑心通明/巨猿劈山', '帝骖龙翔': '帝骖龙翔/顽抗'}[skill.name] ?? skill.name;

double bossStatForGender(Boss boss, String gender, bool spirit) {
  if (gender == '男性' && (boss.name == '杜姬欣' || boss.name == '杜姬欣/钱宗龙')) {
    return spirit ? 240 : 560;
  }
  return spirit ? boss.spirit : boss.stamina;
}

Map<String, int> normalizeGenderSkillLevels(
    SkillStore store, String gender, Map<String, int> imported) {
  final normalized = <String, int>{};
  for (final boss in store.bosses) {
    for (final skill in boss.skills) {
      final level =
          imported[skillNameForGender(skill, gender)] ?? imported[skill.name];
      if (level != null) normalized[skill.name] = level;
    }
  }
  return normalized;
}

class BossImportResult {
  const BossImportResult(
      {required this.bossesAdded, required this.skillsAdded});
  final int bossesAdded;
  final int skillsAdded;
}

class CharacterData {
  CharacterData(
      {required this.id,
      required this.name,
      required this.gender,
      required this.school,
      required this.mind,
      required this.position,
      required Map<String, int> levels,
      this.swapPoints = 0,
      this.weeklyCompletedWeek = '',
      this.archived = false})
      : levels = Map<String, int>.from(levels);
  final String id;
  String name;
  String gender;
  String school;
  String mind;
  String position;
  int swapPoints;
  String weeklyCompletedWeek;
  final Map<String, int> levels;
  bool archived;
  bool get weeklyCompleted => weeklyCompletedWeek == currentWeekKey();
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender,
        'school': school,
        'mind': mind,
        'position': position,
        'swapPoints': swapPoints,
        'weeklyCompletedWeek': weeklyCompletedWeek,
        'levels': levels,
        'archived': archived
      };
  factory CharacterData.fromJson(Map<String, dynamic> json) {
    return CharacterData(
        id: json['id'] as String,
        name: json['name'] as String,
        gender: json['gender'] as String? ?? '女性',
        school: normalizeSchool(json['school'] as String? ?? '未设置'),
        mind: normalizeMind(json['mind'] as String? ?? '未设置'),
        position: normalizePosition(json['position'] as String? ?? '输出'),
        swapPoints:
            ((json['swapPoints'] as num?)?.toInt() ?? 0).clamp(0, 1 << 31),
        weeklyCompletedWeek: json['weeklyCompletedWeek'] as String? ?? '',
        levels: (json['levels'] as Map).map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt())),
        archived: json['archived'] as bool? ?? false);
  }
}

class SkillStore extends ChangeNotifier {
  SkillStore({
    SyncSettingsStore? syncSettingsStore,
    WebDavSyncService? webDavSyncService,
    BossCatalogService? bossCatalogService,
    this.remoteCheckInterval = const Duration(minutes: 1),
  })  : syncSettingsStore = syncSettingsStore ?? SyncSettingsStore(),
        webDavSyncService = webDavSyncService ?? WebDavSyncService(),
        bossCatalogService = bossCatalogService ?? BossCatalogService();

  final List<CharacterData> characters = [];
  final List<Boss> bosses = [];
  final List<String> importantSkills = [];
  final List<String> purpleSkills = [];
  int maxSkillRank = 10;
  String selectedCharacterId = '';
  int page = 0;
  List<String> navigationOrder = [...defaultNavigationOrder];
  Set<String> navigationVisible = {...defaultNavigationVisible};
  Map<String, String> navigationLabels = {};
  String? pendingSkillPageCharacterId;
  int? pendingSkillPageMaxRank;
  static const storageKey = 'battle_skill_data_v3';
  static const localDataPathKey = 'local_data_path';
  static const pendingLocalDataPathKey = 'pending_local_data_path';
  static const bossCatalogVersionKey = 'boss_catalog_version';
  static const bossCatalogSkippedVersionKey = 'boss_catalog_skipped_version';
  SharedPreferences? _prefs;
  final ThemeSettingsStore themeSettingsStore = ThemeSettingsStore();
  final SyncSettingsStore syncSettingsStore;
  final WebDavSyncService webDavSyncService;
  final BossCatalogService bossCatalogService;
  final Duration remoteCheckInterval;
  ThemeMode themeMode = ThemeMode.light;
  SyncConfig? syncConfig;
  DateTime? lastSyncAt;
  String? currentRemoteBackupPath;
  String? syncMessage;
  bool syncBusy = false;
  bool restoreBusy = false;
  bool backupCheckBusy = false;
  List<RemoteBackup> remoteBackups = [];
  RemoteBackup? newerRemoteBackup;
  RemoteBossCatalog? availableBossCatalog;
  String? localDataPath;
  String? pendingLocalDataPath;
  bool localDataMigrationPending = false;
  bool _localStorageReady = false;
  Future<void> _localWriteQueue = Future<void>.value();
  int bossCatalogVersion = 1;
  int? skippedBossCatalogVersion;
  bool bossCatalogCheckBusy = false;
  String? bossCatalogCheckError;
  Timer? _autoSyncTimer;
  Timer? _remoteCheckTimer;
  Timer? _backupCheckRetryTimer;
  Timer? _changeSyncTimer;
  int _dataRevision = 0;
  int _syncedRevision = 0;
  int _successfulSyncGeneration = 0;
  bool _syncInitialized = false;
  CharacterData? get selectedCharacter {
    final selected = _findCharacter(selectedCharacterId);
    if (selected != null && !selected.archived) return selected;
    return activeCharacters.firstOrNull;
  }

  List<CharacterData> get activeCharacters =>
      characters.where((item) => !item.archived).toList();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    themeMode = await themeSettingsStore.load();
    syncConfig = await syncSettingsStore.load();
    lastSyncAt = await syncSettingsStore.loadLastSyncAt();
    currentRemoteBackupPath = await syncSettingsStore.loadCurrentBackupPath();
    bossCatalogVersion = _prefs!.getInt(bossCatalogVersionKey) ?? 1;
    skippedBossCatalogVersion = _prefs!.getInt(bossCatalogSkippedVersionKey);
    await _migratePendingLocalData();
    localDataPath = _prefs!.getString(localDataPathKey);
    final raw = await _readLocalData();
    _localStorageReady = true;
    if (raw == null)
      _seed();
    else
      _restore(jsonDecode(raw) as Map<String, dynamic>);
    _syncInitialized = true;
    _scheduleAutoSync();
    _scheduleRemoteBackupChecks();
    notifyListeners();
    unawaited(_initializeRemoteSync());
    unawaited(checkForBossCatalogUpdate());
  }

  Future<String?> _readLocalData() async {
    final path = localDataPath;
    if (path == null || path.trim().isEmpty) {
      return _prefs?.getString(storageKey);
    }
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      return raw.trim().isEmpty ? null : raw;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readDataFromPath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      return _prefs?.getString(storageKey);
    }
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      return raw.trim().isEmpty ? null : raw;
    } catch (_) {
      return null;
    }
  }

  Future<void> _migratePendingLocalData() async {
    final pending = _prefs?.getString(pendingLocalDataPathKey);
    if (pending == null) return;

    localDataMigrationPending = true;
    pendingLocalDataPath = pending.trim().isEmpty ? null : pending.trim();
    final previousPath = _prefs?.getString(localDataPathKey);
    final raw = await _readDataFromPath(previousPath);
    final targetPath = pending.trim().isEmpty ? null : pending.trim();
    try {
      if (targetPath == null) {
        if (raw != null) await _prefs?.setString(storageKey, raw);
        await _prefs?.remove(localDataPathKey);
      } else {
        final target = File(targetPath);
        await target.parent.create(recursive: true);
        if (raw != null) await target.writeAsString(raw);
        await _prefs?.setString(localDataPathKey, targetPath);
        await _prefs?.remove(storageKey);
      }
      await _prefs?.remove(pendingLocalDataPathKey);
      localDataMigrationPending = false;
      pendingLocalDataPath = null;
    } catch (_) {
      // Keep the pending path so the next launch can retry the migration.
    }
  }

  Future<void> _persistLocalData(String encoded) async {
    final path = localDataPath;
    if (path == null || path.trim().isEmpty) {
      await _prefs?.setString(storageKey, encoded);
      return;
    }
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(encoded);
  }

  String localDataLocationLabel() {
    if (localDataMigrationPending) {
      final target = pendingLocalDataPath;
      return target == null ? '重启后迁移到系统默认位置' : '重启后迁移到：$target';
    }
    return localDataPath ?? '系统默认位置（应用数据目录）';
  }

  Future<void> scheduleLocalDataMigration(String? path) async {
    final normalized = path?.trim();
    localDataMigrationPending = true;
    pendingLocalDataPath = normalized?.isEmpty == true ? null : normalized;
    await _prefs?.setString(pendingLocalDataPathKey, normalized ?? '');
    notifyListeners();
  }

  Future<void> restartForLocalDataMigration() async {
    await _localWriteQueue;
    if (Platform.isMacOS) {
      final appPath =
          File(Platform.resolvedExecutable).parent.parent.parent.path;
      // Without -n, macOS may only activate the existing process instead of
      // launching a new one. The pending migration would then remain in the
      // current in-memory store and continue to appear as "待重启".
      await Process.start('open', ['-n', appPath],
          mode: ProcessStartMode.detached);
    } else {
      await Process.start(
          Platform.resolvedExecutable, Platform.executableArguments,
          mode: ProcessStartMode.detached);
    }
    exit(0);
  }

  Future<void> _initializeRemoteSync() async {
    final checked = await checkForNewerBackupWithRetry();
    if (checked && newerRemoteBackup == null) _scheduleChangeSync();
  }

  Future<bool> checkForBossCatalogUpdate({bool manual = false}) async {
    if (bossCatalogCheckBusy) return false;
    bossCatalogCheckBusy = true;
    bossCatalogCheckError = null;
    notifyListeners();
    try {
      final catalog = await bossCatalogService.fetch();
      if (catalog.version > bossCatalogVersion &&
          (manual || catalog.version != skippedBossCatalogVersion)) {
        availableBossCatalog = catalog;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      bossCatalogCheckError = '无法连接首领技能数据服务，请稍后重试';
      return false;
    } finally {
      bossCatalogCheckBusy = false;
      notifyListeners();
    }
  }

  void dismissBossCatalogUpdate() {
    availableBossCatalog = null;
    notifyListeners();
  }

  Future<void> skipBossCatalogUpdate() async {
    final catalog = availableBossCatalog;
    if (catalog == null) return;
    skippedBossCatalogVersion = catalog.version;
    availableBossCatalog = null;
    await _prefs?.setInt(
        bossCatalogSkippedVersionKey, skippedBossCatalogVersion!);
    notifyListeners();
  }

  Future<void> applyBossCatalogUpdate() async {
    final catalog = availableBossCatalog;
    if (catalog == null) return;
    final importedBosses = catalog.bosses
        .map((item) => Boss.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final previousSkillsById = <String, Skill>{
      for (final boss in bosses)
        for (final skill in boss.skills) skill.id: skill,
    };
    final previousSkillsByName = <String, Skill>{
      for (final boss in bosses)
        for (final skill in boss.skills) skill.name.trim().toLowerCase(): skill,
    };

    for (final character in characters) {
      final nextLevels = <String, int>{};
      for (final boss in importedBosses) {
        for (final skill in boss.skills) {
          final previous = previousSkillsById[skill.id] ??
              previousSkillsByName[skill.name.trim().toLowerCase()];
          nextLevels[skill.id] = previous == null
              ? 1
              : (character.levels[previous.id] ?? 1)
                  .clamp(1, catalog.maxSkillRank);
        }
      }
      character.levels
        ..clear()
        ..addAll(nextLevels);
    }

    bosses
      ..clear()
      ..addAll(importedBosses);
    maxSkillRank = catalog.maxSkillRank;
    purpleSkills
      ..clear()
      ..addAll(bosses
          .expand((boss) => boss.skills)
          .where((skill) => skill.tradable)
          .map((skill) => skill.name));
    bossCatalogVersion = catalog.version;
    skippedBossCatalogVersion = null;
    availableBossCatalog = null;
    await _prefs?.setInt(bossCatalogVersionKey, bossCatalogVersion);
    await _prefs?.remove(bossCatalogSkippedVersionKey);
    _save();
    notifyListeners();
  }

  void _seed() {
    final data = seedData;
    final purpleNames = (data['purple'] as List).cast<String>().toSet();
    final rawBosses = [...(data['bosses'] as List)];
    if (!rawBosses.any((item) => (item as Map)['name'] == '罗伊客')) {
      final noSpiritIndex =
          rawBosses.indexWhere((item) => (item as Map)['name'] == '无精耐提升技能');
      rawBosses.insert(
          noSpiritIndex < 0 ? rawBosses.length : noSpiritIndex,
          <String, dynamic>{
            'name': '罗伊客',
            'sp': 320,
            'st': 480,
            'skills': ['狂澜摧城', '横绝八荒', '凝锋斩', '截影推山']
          });
    }
    final seedBossIdsByIndex = <int, String>{};
    for (var i = 0; i < rawBosses.length; i++) {
      final raw = Map<String, dynamic>.from(rawBosses[i] as Map);
      // 保留无精耐提升技能原有的 ID；罗伊客使用新增的 boss-33，避免旧数据错位。
      final bossId = raw['name'] == '无精耐提升技能'
          ? 'boss-32'
          : raw['name'] == '罗伊客'
              ? 'boss-33'
              : 'boss-$i';
      seedBossIdsByIndex[i] = bossId;
      bosses.add(Boss(
          id: bossId,
          name: raw['name'] == '杜姬欣' ? '杜姬欣/钱宗龙' : raw['name'] as String,
          spirit: (raw['sp'] as num).toDouble(),
          stamina: (raw['st'] as num).toDouble(),
          skills: (raw['skills'] as List)
              .asMap()
              .entries
              .map((entry) => Skill(
                  id: '$bossId-skill-${entry.key}',
                  name: entry.value as String,
                  tradable: purpleNames.contains(entry.value)))
              .toList()));
    }
    final rawNine = Map<String, dynamic>.from(data['nine'] as Map);
    final rawCharacters = data['characters'] as List;
    for (var i = 0; i < rawCharacters.length; i++) {
      final raw = Map<String, dynamic>.from(rawCharacters[i] as Map);
      final levels = <String, int>{};
      for (final boss in bosses)
        for (final skill in boss.skills) levels[skill.id] = 10;
      final overrides =
          Map<String, dynamic>.from(rawNine[raw['name']] as Map? ?? {});
      overrides.forEach((key, value) {
        final pieces = key.split(':');
        if (pieces.length == 2)
          levels['${int.tryParse(pieces[0]) == 32 ? 'boss-32' : seedBossIdsByIndex[int.tryParse(pieces[0]) ?? -1] ?? 'boss-${pieces[0]}'}-skill-${pieces[1]}'] =
              (value as num).toInt();
      });
      final isFemale = i == 0;
      characters.add(CharacterData(
          id: 'character-$i',
          name: isFemale ? '示例女角色' : '示例男角色',
          gender: isFemale ? '女性' : '男性',
          school: isFemale ? '万花' : '天策',
          mind: isFemale ? '花间游' : '傲血战意',
          position: '输出',
          levels: levels));
      if (i == 1) break;
    }
    importantSkills.addAll((data['summary'] as List).cast<String>());
    purpleSkills.addAll((data['purple'] as List).cast<String>());
    _ensureGenderSpecificSkills();
    selectedCharacterId = characters.first.id;
    _save();
  }

  void _restore(Map<String, dynamic> data) {
    maxSkillRank = ((data['maxSkillRank'] as num?)?.toInt() ?? 10).clamp(1, 99);
    characters.addAll((data['characters'] as List).map((item) =>
        CharacterData.fromJson(Map<String, dynamic>.from(item as Map))));
    bosses.addAll((data['bosses'] as List)
        .map((item) => Boss.fromJson(Map<String, dynamic>.from(item as Map))));
    for (final boss in bosses) {
      if (boss.name == '杜姬欣') boss.name = '杜姬欣/钱宗龙';
    }
    _ensureGenderSpecificSkills();
    importantSkills.addAll((data['importantSkills'] as List).cast<String>());
    purpleSkills.addAll((data['purpleSkills'] as List).cast<String>());
    for (final boss in bosses)
      for (final skill in boss.skills)
        skill.tradable = skill.tradable || purpleSkills.contains(skill.name);
    selectedCharacterId =
        data['selectedCharacterId'] as String? ?? characters.first.id;
    _ensureSelectedCharacterIsActive();
    page = (data['page'] as int? ?? 0).clamp(0, 7);
    final validNavigationIds =
        navigationPageOptions.map((item) => item.id).toSet();
    final savedOrder = (data['navigationOrder'] as List?)
            ?.map((item) => item.toString())
            .where(validNavigationIds.contains)
            .toList() ??
        const <String>[];
    navigationOrder = [
      ...savedOrder.toSet(),
      ...defaultNavigationOrder.where((id) => !savedOrder.contains(id))
    ];
    navigationVisible = (data['navigationVisible'] as List?)
            ?.map((item) => item.toString())
            .where(validNavigationIds.contains)
            .toSet() ??
        defaultNavigationVisible.toSet();
    navigationLabels = (data['navigationLabels'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
        {};
    navigationLabels.removeWhere((key, value) =>
        !validNavigationIds.contains(key) || value.trim().isEmpty);
  }

  void _replaceData(Map<String, dynamic> data) {
    final previous = _json();
    try {
      characters.clear();
      bosses.clear();
      importantSkills.clear();
      purpleSkills.clear();
      _restore(data);
    } catch (_) {
      characters.clear();
      bosses.clear();
      importantSkills.clear();
      purpleSkills.clear();
      _restore(previous);
      rethrow;
    }
  }

  void _ensureGenderSpecificSkills() {
    final boss = bosses.where((item) => item.name == '无精耐提升技能').firstOrNull;
    if (boss == null || boss.skills.any((skill) => skill.name == '蛮熊碎颅击')) {
      return;
    }
    final skill = Skill(id: '${boss.id}-skill-male-bear', name: '蛮熊碎颅击');
    boss.skills.add(skill);
    for (final character in characters) {
      character.levels[skill.id] = 1;
    }
  }

  Map<String, dynamic> _json() => {
        'characters': characters.map((item) => item.toJson()).toList(),
        'bosses': bosses.map((item) => item.toJson()).toList(),
        'importantSkills': importantSkills,
        'purpleSkills': purpleSkills,
        'maxSkillRank': maxSkillRank,
        'selectedCharacterId': selectedCharacterId,
        'page': page,
        'navigationOrder': navigationOrder,
        'navigationVisible': navigationVisible.toList(),
        'navigationLabels': navigationLabels
      };
  void _save() {
    final encoded = jsonEncode(_json());
    if (_localStorageReady) {
      _localWriteQueue = _localWriteQueue
          .then((_) => _persistLocalData(encoded))
          .catchError((_) {});
    } else {
      unawaited(_prefs?.setString(storageKey, encoded));
    }
    _dataRevision++;
    _scheduleChangeSync();
  }

  void _scheduleAutoSync() {
    _autoSyncTimer?.cancel();
    final config = syncConfig;
    if (config == null || !config.isValid || config.autoSyncMinutes <= 0) {
      return;
    }
    _autoSyncTimer = Timer.periodic(
        Duration(minutes: config.autoSyncMinutes), (_) => checkAutoSync());
  }

  void _scheduleRemoteBackupChecks() {
    _remoteCheckTimer?.cancel();
    final config = syncConfig;
    if (config == null || !config.isValid) return;
    _remoteCheckTimer = Timer.periodic(remoteCheckInterval, (_) {
      if (newerRemoteBackup == null &&
          !backupCheckBusy &&
          !syncBusy &&
          !restoreBusy) {
        unawaited(checkForNewerBackup(silent: true).then((checked) {
          if (checked && newerRemoteBackup == null) _scheduleChangeSync();
        }));
      }
    });
  }

  void _scheduleChangeSync() {
    _changeSyncTimer?.cancel();
    final config = syncConfig;
    if (!_syncInitialized ||
        _dataRevision <= _syncedRevision ||
        config == null ||
        !config.isValid ||
        newerRemoteBackup != null) {
      return;
    }
    _changeSyncTimer = Timer(const Duration(seconds: 2), () async {
      if (_dataRevision <= _syncedRevision || newerRemoteBackup != null) return;
      final checked = await checkForNewerBackup(silent: true);
      if (checked &&
          _dataRevision > _syncedRevision &&
          newerRemoteBackup == null) {
        await syncNow(silent: true);
      }
    });
  }

  Future<bool> checkForNewerBackupWithRetry() async {
    final config = syncConfig;
    if (config == null || !config.isValid) return false;
    final succeeded = await checkForNewerBackup();
    if (succeeded) {
      _backupCheckRetryTimer?.cancel();
      return true;
    }
    _backupCheckRetryTimer?.cancel();
    _backupCheckRetryTimer = Timer(const Duration(seconds: 10), () async {
      final checked = await checkForNewerBackup();
      if (checked && newerRemoteBackup == null) _scheduleChangeSync();
    });
    return false;
  }

  Future<void> checkAutoSync() async {
    final config = syncConfig;
    if (config == null || !config.isValid) return;
    final checked = await checkForNewerBackup(silent: true);
    if (!checked || newerRemoteBackup != null) return;
    if (_dataRevision <= _syncedRevision || config.autoSyncMinutes <= 0) return;
    final due = lastSyncAt == null ||
        DateTime.now().difference(lastSyncAt!).inMinutes >=
            config.autoSyncMinutes;
    if (due) await syncNow(silent: true);
  }

  Future<bool> checkForNewerBackup({bool silent = false}) async {
    if (backupCheckBusy || syncBusy || restoreBusy) return false;
    final config = syncConfig;
    if (config == null || !config.isValid) {
      newerRemoteBackup = null;
      return false;
    }
    backupCheckBusy = true;
    final previousPath = newerRemoteBackup?.path;
    final syncGenerationAtStart = _successfulSyncGeneration;
    if (!silent) notifyListeners();
    try {
      final backups = await webDavSyncService.listBackups(config);
      remoteBackups = backups;
      final latest = backups.firstOrNull;
      final latestTime =
          latest == null ? null : webDavSyncService.backupTime(latest);
      if (syncGenerationAtStart == _successfulSyncGeneration) {
        final isOwnLatest =
            latest != null && latest.path == currentRemoteBackupPath;
        newerRemoteBackup = !isOwnLatest &&
                latest != null &&
                (lastSyncAt == null ||
                    (latestTime != null && latestTime.isAfter(lastSyncAt!)))
            ? latest
            : null;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      backupCheckBusy = false;
      if (!silent || previousPath != newerRemoteBackup?.path) {
        notifyListeners();
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode == mode) return;
    themeMode = mode;
    await themeSettingsStore.save(mode);
    notifyListeners();
  }

  Future<void> saveSyncConfig(SyncConfig config) async {
    await syncSettingsStore.save(config);
    syncConfig = config;
    _scheduleAutoSync();
    _scheduleRemoteBackupChecks();
    notifyListeners();
    final checked = await checkForNewerBackup();
    if (checked && newerRemoteBackup == null) _scheduleChangeSync();
  }

  Future<bool> testSyncConnection([SyncConfig? candidate]) async {
    final config = candidate ?? syncConfig;
    if (config == null || !config.isValid) {
      syncMessage = '尚未配置完整的 WebDAV';
      notifyListeners();
      return false;
    }
    try {
      await webDavSyncService.testConnection(config);
      syncMessage = '连接成功';
      notifyListeners();
      return true;
    } catch (error) {
      syncMessage = '连接失败：$error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> syncNow({bool silent = false}) async {
    if (syncBusy || restoreBusy) return false;
    if (newerRemoteBackup != null) {
      syncMessage = '发现较新的云端备份，请先恢复后再同步';
      if (!silent) notifyListeners();
      return false;
    }
    final config = syncConfig;
    if (config == null || !config.isValid) {
      if (!silent) {
        syncMessage = '尚未配置完整的 WebDAV';
        notifyListeners();
      }
      return false;
    }
    syncBusy = true;
    notifyListeners();
    final revisionAtStart = _dataRevision;
    try {
      final backup =
          await webDavSyncService.upload(config, jsonEncode(_json()));
      lastSyncAt = DateTime.now();
      currentRemoteBackupPath = backup.path;
      _syncedRevision = revisionAtStart;
      _successfulSyncGeneration++;
      newerRemoteBackup = null;
      await syncSettingsStore.saveLastSyncAt(lastSyncAt!);
      await syncSettingsStore.saveCurrentBackupPath(backup.path);
      syncMessage = '已同步 · ${backup.name}';
      return true;
    } catch (error) {
      syncMessage = '同步失败：$error';
      return false;
    } finally {
      syncBusy = false;
      notifyListeners();
      _scheduleChangeSync();
    }
  }

  Future<bool> loadRemoteBackups() async {
    final config = syncConfig;
    if (config == null || !config.isValid) {
      syncMessage = '尚未配置完整的 WebDAV';
      notifyListeners();
      return false;
    }
    final loaded = await checkForNewerBackup();
    if (loaded) {
      syncMessage = '已读取 ${remoteBackups.length} 个远程备份';
      notifyListeners();
      return true;
    }
    syncMessage = '读取远程备份失败';
    notifyListeners();
    return false;
  }

  Future<bool> restoreRemoteBackup(RemoteBackup backup) async {
    final config = syncConfig;
    if (config == null || !config.isValid || syncBusy || restoreBusy) {
      return false;
    }
    _changeSyncTimer?.cancel();
    restoreBusy = true;
    notifyListeners();
    try {
      final raw = await webDavSyncService.downloadBackup(config, backup);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _replaceData(data);
      _dataRevision = 0;
      _syncedRevision = 0;
      currentRemoteBackupPath = backup.path;
      newerRemoteBackup = null;
      lastSyncAt = DateTime.now();
      await syncSettingsStore.saveLastSyncAt(lastSyncAt!);
      await syncSettingsStore.saveCurrentBackupPath(backup.path);
      await _persistLocalData(jsonEncode(_json()));
      _syncedRevision = _dataRevision;
      syncMessage = '已恢复 · ${backup.name}';
      return true;
    } catch (error) {
      syncMessage = '恢复失败：$error';
      return false;
    } finally {
      restoreBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _remoteCheckTimer?.cancel();
    _backupCheckRetryTimer?.cancel();
    _changeSyncTimer?.cancel();
    super.dispose();
  }

  CharacterData? _findCharacter(String id) {
    for (final character in characters)
      if (character.id == id) return character;
    return null;
  }

  Boss? bossForSkill(String skillId) {
    for (final boss in bosses)
      if (boss.skills.any((skill) => skill.id == skillId)) return boss;
    return null;
  }

  Skill? findSkill(String name) {
    for (final boss in bosses)
      for (final skill in boss.skills) if (skill.name == name) return skill;
    return null;
  }

  int level(String characterId, String skillId) =>
      _findCharacter(characterId)?.levels[skillId] ?? 0;
  void selectCharacter(String id) {
    final character = _findCharacter(id);
    if (character == null || character.archived) return;
    selectedCharacterId = id;
    _save();
    notifyListeners();
  }

  void setCharacterArchived(CharacterData character, bool archived) {
    if (character.archived == archived) return;
    character.archived = archived;
    _ensureSelectedCharacterIsActive();
    _save();
    notifyListeners();
  }

  void _ensureSelectedCharacterIsActive() {
    final selected = _findCharacter(selectedCharacterId);
    if (selected != null && !selected.archived) return;
    selectedCharacterId = activeCharacters.firstOrNull?.id ?? '';
  }

  void setPage(int value) {
    page = value;
    _save();
    notifyListeners();
  }

  void setNavigationConfiguration(List<String> order, Set<String> visible,
      [Map<String, String> labels = const {}]) {
    final validIds = navigationPageOptions.map((item) => item.id).toSet();
    navigationOrder = [
      ...order.where(validIds.contains).toSet(),
      ...defaultNavigationOrder.where((id) => !order.contains(id))
    ];
    navigationVisible = visible.where(validIds.contains).toSet();
    navigationLabels = Map.fromEntries(labels.entries.where((entry) =>
        validIds.contains(entry.key) && entry.value.trim().isNotEmpty));
    _save();
    notifyListeners();
  }

  void openSkillPage(int targetPage, String characterId) {
    pendingSkillPageCharacterId = characterId;
    pendingSkillPageMaxRank = math.max(1, maxSkillRank - 1);
    setPage(targetPage);
  }

  void setMaxSkillRank(int value) {
    final normalized = value.clamp(1, 99).toInt();
    if (normalized == maxSkillRank) return;
    maxSkillRank = normalized;
    for (final character in characters) {
      character.levels
          .updateAll((_, level) => level.clamp(0, maxSkillRank).toInt());
    }
    _save();
    notifyListeners();
  }

  void setLevel(String skillId, int value) {
    final character = selectedCharacter;
    if (character == null) return;
    character.levels[skillId] = value.clamp(0, maxSkillRank).toInt();
    _save();
    notifyListeners();
  }

  void setLevelForAllCharacters(String skillId, int value) {
    final normalized = value.clamp(0, maxSkillRank).toInt();
    for (final character in activeCharacters) {
      character.levels[skillId] = normalized;
    }
    _save();
    notifyListeners();
  }

  void setAllSkillLevels(int value, {String? characterId}) {
    final normalized = value.clamp(1, maxSkillRank).toInt();
    final targets = characterId == null
        ? activeCharacters
        : characters.where(
            (character) => character.id == characterId && !character.archived);
    for (final character in targets) {
      for (final boss in bosses) {
        for (final skill in boss.skills) {
          character.levels[skill.id] = normalized;
        }
      }
    }
    _save();
    notifyListeners();
  }

  int rankFor(String characterId, Boss boss) {
    final character = _findCharacter(characterId);
    if (character == null) return 0;
    final values = boss.skills
        .where((skill) => skillAppliesToGender(skill, character.gender))
        .map((skill) => level(characterId, skill.id))
        .toList();
    if (values.isEmpty || values.any((value) => value < 1)) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  double _multiplier(int rank) {
    const values = [0, 1, 2, 3, 4, 5, 7, 10, 15, 22.5, 33.75];
    if (rank < values.length) return values[rank].toDouble();
    return (values.last * math.pow(1.5, rank - 10)).toDouble();
  }

  double stat(String characterId, bool spirit) {
    final character = _findCharacter(characterId);
    if (character == null) return 0;
    var result = 10000.0;
    for (final boss in bosses) {
      final current = rankFor(characterId, boss);
      final base = bossStatForGender(boss, character.gender, spirit);
      result += base * _multiplier(current);
    }
    return result + thresholdBonus(characterId);
  }

  double computedBaseStat(String characterId, bool spirit) => 10000;

  double thresholdBonus(String characterId) {
    final character = _findCharacter(characterId);
    if (character == null) return 0;
    final values = bosses
        .expand((boss) => boss.skills)
        .where((skill) => skillAppliesToGender(skill, character.gender))
        .map((skill) => character.levels[skill.id] ?? 0);
    const bonus = [
      0,
      100,
      200,
      300,
      400,
      2000,
      6000,
      8000,
      10000,
      12000,
      14000
    ];
    return List<int>.generate(math.min(maxSkillRank, 10), (index) => index + 1)
        .where((value) => values.where((level) => level >= value).length > 2)
        .fold<double>(0, (sum, value) => sum + bonus[value]);
  }

  int skillLevelForName(String characterId, String name) {
    final matches = <int>[];
    for (final boss in bosses)
      for (final skill in boss.skills)
        if (skill.name == name) matches.add(level(characterId, skill.id));
    return matches.isEmpty ? 0 : matches.reduce((a, b) => a > b ? a : b);
  }

  int highestSkillLevelForName(String name) {
    var highest = 0;
    for (final character in activeCharacters) {
      final value = skillLevelForName(character.id, name);
      if (value > highest) highest = value;
    }
    return highest;
  }

  Map<String, int> bookNeeds(String characterId) {
    final character = _findCharacter(characterId);
    if (character == null) return {};
    final values = bosses
        .expand((boss) => boss.skills)
        .where((skill) => skillAppliesToGender(skill, character.gender))
        .map((skill) => character.levels[skill.id] ?? 0);
    return {
      // 与原始表格 I2 的公式一致：0/1/2 重分别需要 8/7/5 本。
      '通本1': values.fold<int>(
          0,
          (sum, value) =>
              sum +
              (value < 3 ? const [8, 7, 5][value.clamp(0, 2).toInt()] : 0)),
      // 与原始表格 I3、I71、J71 的公式一致。
      '通本2': values.where((value) => value < 4).length,
      '通本3': values.where((value) => value < 5).length,
      '通本4': values.where((value) => value < 6).length
    };
  }

  void addImportantSkill(String name) {
    final normalized = name.trim();
    final isExistingSkill = bosses
        .expand((boss) => boss.skills)
        .any((skill) => skill.name == normalized);
    if (normalized.isEmpty ||
        !isExistingSkill ||
        importantSkills.contains(normalized)) return;
    importantSkills.add(normalized);
    _save();
    notifyListeners();
  }

  void removeImportantSkill(String name) {
    importantSkills.remove(name);
    _save();
    notifyListeners();
  }

  void addBoss(
      {required String name,
      String type = '普通',
      required double spirit,
      required double stamina,
      required List<SkillInputData> skillInputs}) {
    final bossId = 'boss-${DateTime.now().microsecondsSinceEpoch}';
    final boss = Boss(
        id: bossId,
        name: name.trim(),
        type: type,
        spirit: spirit,
        stamina: stamina,
        skills: skillInputs
            .where((item) => item.name.trim().isNotEmpty)
            .map((item) => item.name.trim())
            .toSet()
            .toList()
            .asMap()
            .entries
            .map((entry) => Skill(
                id: '$bossId-skill-${entry.key}',
                name: entry.value,
                tradable: skillInputs
                    .firstWhere((item) => item.name.trim() == entry.value)
                    .tradable))
            .toList());
    bosses.add(boss);
    for (final character in characters)
      for (final skill in boss.skills) character.levels[skill.id] = 1;
    _save();
    notifyListeners();
  }

  void addSkillToBoss(Boss boss, String name, {bool tradable = false}) {
    if (name.trim().isEmpty ||
        boss.skills.any((skill) => skill.name == name.trim())) return;
    final skill = Skill(
        id: '${boss.id}-skill-${boss.skills.length}',
        name: name.trim(),
        tradable: tradable);
    boss.skills.add(skill);
    if (tradable && !purpleSkills.contains(skill.name)) {
      purpleSkills.add(skill.name);
    }
    for (final character in characters) character.levels[skill.id] = 1;
    _save();
    notifyListeners();
  }

  void updateBoss(Boss boss,
      {required String name,
      required String type,
      required double spirit,
      required double stamina}) {
    boss.name = name.trim();
    boss.type = type;
    boss.spirit = spirit;
    boss.stamina = stamina;
    _save();
    notifyListeners();
  }

  void reorderBoss(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= bosses.length) return;
    if (newIndex > oldIndex) newIndex--;
    if (newIndex < 0 || newIndex >= bosses.length || oldIndex == newIndex) {
      return;
    }
    final boss = bosses.removeAt(oldIndex);
    bosses.insert(newIndex, boss);
    _save();
    notifyListeners();
  }

  void reorderCharacter(String characterId, String targetCharacterId) {
    if (characterId == targetCharacterId) return;
    final oldIndex = characters.indexWhere((item) => item.id == characterId);
    final newIndex =
        characters.indexWhere((item) => item.id == targetCharacterId);
    if (oldIndex < 0 || newIndex < 0) return;
    final character = characters[oldIndex];
    characters[oldIndex] = characters[newIndex];
    characters[newIndex] = character;
    _save();
    notifyListeners();
  }

  void removeBoss(Boss boss) {
    bosses.removeWhere((item) => item.id == boss.id);
    for (final character in characters) {
      for (final skill in boss.skills) {
        character.levels.remove(skill.id);
      }
    }
    for (final skill in boss.skills) {
      if (!bosses
          .expand((item) => item.skills)
          .any((other) => other.name == skill.name && other.tradable)) {
        purpleSkills.remove(skill.name);
      }
    }
    _save();
    notifyListeners();
  }

  void renameSkill(Skill skill, String name) {
    final nextName = name.trim();
    if (nextName.isEmpty || nextName == skill.name) return;
    final oldName = skill.name;
    skill.name = nextName;
    for (var index = 0; index < importantSkills.length; index++) {
      if (importantSkills[index] == oldName) importantSkills[index] = nextName;
    }
    for (var index = 0; index < purpleSkills.length; index++) {
      if (purpleSkills[index] == oldName) purpleSkills[index] = nextName;
    }
    _save();
    notifyListeners();
  }

  void removeSkillFromBoss(Boss boss, Skill skill) {
    boss.skills.removeWhere((item) => item.id == skill.id);
    for (final character in characters) {
      character.levels.remove(skill.id);
    }
    if (!bosses
        .expand((item) => item.skills)
        .any((other) => other.name == skill.name && other.tradable)) {
      purpleSkills.remove(skill.name);
    }
    _save();
    notifyListeners();
  }

  Future<bool> exportBackup() async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(_json())));
    final path = await FilePicker.saveFile(
        dialogTitle: '导出百战技能备份',
        fileName: 'baizhan-skill-backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes);
    return path != null;
  }

  Future<bool> importBackup() async {
    final result = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'], withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes == null) return false;
    final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    _replaceData(data);
    _ensureSelectedCharacterIsActive();
    _save();
    notifyListeners();
    return true;
  }

  Future<bool> exportBosses() async {
    final data = {
      'type': 'baizhan-bosses',
      'version': bossCatalogVersion + 1,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'notes': '首领技能数据更新',
      'maxSkillRank': maxSkillRank,
      'bosses': bosses.map((boss) => boss.toJson()).toList()
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    final path = await FilePicker.saveFile(
        dialogTitle: '导出全部首领和技能',
        fileName: 'baizhan-bosses.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes);
    return path != null;
  }

  Future<BossImportResult?> importBosses() async {
    final result = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'], withData: true);
    final bytes = result?.files.single.bytes;
    if (bytes == null) return null;
    final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final rawBosses = data['bosses'];
    if (rawBosses is! List) {
      throw const FormatException('文件中没有首领数据');
    }

    final importedMaxRank = (data['maxSkillRank'] as num?)?.toInt();
    final previousMaxRank = maxSkillRank;
    if (importedMaxRank != null) setMaxSkillRank(importedMaxRank);
    var bossesAdded = 0;
    var skillsAdded = 0;
    final importStamp = DateTime.now().microsecondsSinceEpoch;
    for (var bossIndex = 0; bossIndex < rawBosses.length; bossIndex++) {
      final imported =
          Boss.fromJson(Map<String, dynamic>.from(rawBosses[bossIndex] as Map));
      final normalizedBossName = imported.name.trim().toLowerCase();
      if (normalizedBossName.isEmpty) continue;
      Boss? target;
      for (final boss in bosses) {
        if (boss.name.trim().toLowerCase() == normalizedBossName) {
          target = boss;
          break;
        }
      }

      if (target == null) {
        final bossId = 'boss-import-$importStamp-$bossIndex';
        final seenNames = <String>{};
        final newSkills = <Skill>[];
        for (final importedSkill in imported.skills) {
          final normalizedSkillName = importedSkill.name.trim().toLowerCase();
          if (normalizedSkillName.isEmpty ||
              !seenNames.add(normalizedSkillName)) continue;
          final skill = Skill(
              id: '$bossId-skill-${newSkills.length}',
              name: importedSkill.name.trim(),
              tradable: importedSkill.tradable);
          newSkills.add(skill);
          if (skill.tradable && !purpleSkills.contains(skill.name)) {
            purpleSkills.add(skill.name);
          }
        }
        final newBoss = Boss(
            id: bossId,
            name: imported.name.trim(),
            type: imported.type,
            spirit: imported.spirit,
            stamina: imported.stamina,
            skills: newSkills);
        bosses.add(newBoss);
        for (final character in characters) {
          for (final skill in newSkills) {
            character.levels[skill.id] = 1;
          }
        }
        bossesAdded++;
        skillsAdded += newSkills.length;
        continue;
      }

      final existingNames =
          target.skills.map((skill) => skill.name.trim().toLowerCase()).toSet();
      for (var skillIndex = 0;
          skillIndex < imported.skills.length;
          skillIndex++) {
        final importedSkill = imported.skills[skillIndex];
        final normalizedSkillName = importedSkill.name.trim().toLowerCase();
        if (normalizedSkillName.isEmpty ||
            !existingNames.add(normalizedSkillName)) continue;
        final skill = Skill(
            id: '${target.id}-skill-import-$importStamp-$skillIndex',
            name: importedSkill.name.trim(),
            tradable: importedSkill.tradable);
        target.skills.add(skill);
        for (final character in characters) {
          character.levels[skill.id] = 1;
        }
        if (skill.tradable && !purpleSkills.contains(skill.name)) {
          purpleSkills.add(skill.name);
        }
        skillsAdded++;
      }
    }

    if (bossesAdded > 0 || skillsAdded > 0 || previousMaxRank != maxSkillRank) {
      _save();
      notifyListeners();
    }
    return BossImportResult(bossesAdded: bossesAdded, skillsAdded: skillsAdded);
  }

  void addCharacter(
      {required String name,
      required String gender,
      required String school,
      required String mind,
      required String position,
      int swapPoints = 0,
      bool weeklyCompleted = false,
      int initialSkillLevel = 1,
      Map<String, int> skillLevelsByName = const {}}) {
    final character = CharacterData(
        id: 'character-${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        gender: gender,
        school: normalizeSchool(school),
        mind: normalizeMind(mind),
        position: normalizePosition(position),
        swapPoints: swapPoints.clamp(0, 1 << 31),
        weeklyCompletedWeek: weeklyCompleted ? currentWeekKey() : '',
        levels: {});
    for (final boss in bosses)
      for (final skill in boss.skills) {
        character.levels[skill.id] =
            (skillLevelsByName[skillNameForGender(skill, gender)] ??
                    skillLevelsByName[skill.name] ??
                    initialSkillLevel)
                .clamp(1, maxSkillRank)
                .toInt();
      }
    characters.add(character);
    selectedCharacterId = character.id;
    _save();
    notifyListeners();
  }

  int importCharacterExcel(CharacterExcelData data) {
    var character = characters
        .where((item) => item.name.trim() == data.name.trim())
        .firstOrNull;
    character ??= CharacterData(
        id: 'character-${DateTime.now().microsecondsSinceEpoch}',
        name: data.name.trim(),
        gender: data.gender,
        school: '未设置',
        mind: '未设置',
        position: '输出',
        levels: {});
    character.name = data.name.trim();
    character.gender = data.gender;
    character.archived = false;
    var matched = 0;
    for (final boss in bosses) {
      for (final skill in boss.skills) {
        final importedLevel =
            data.skillLevels[skillNameForGender(skill, data.gender)] ??
                data.skillLevels[skill.name];
        character.levels[skill.id] =
            (importedLevel ?? 1).clamp(1, maxSkillRank).toInt();
        if (importedLevel != null) matched++;
      }
    }
    if (!characters.contains(character)) characters.add(character);
    selectedCharacterId = character.id;
    _save();
    notifyListeners();
    return matched;
  }

  void updateCharacter(CharacterData character,
      {required String name,
      required String gender,
      required String school,
      required String mind,
      required String position,
      required int swapPoints,
      required bool weeklyCompleted,
      Map<String, int> skillLevelsByName = const {}}) {
    character.name = name.trim();
    character.gender = gender;
    character.school = normalizeSchool(school);
    character.mind = normalizeMind(mind);
    character.position = normalizePosition(position);
    character.swapPoints = swapPoints.clamp(0, 1 << 31);
    character.weeklyCompletedWeek = weeklyCompleted ? currentWeekKey() : '';
    for (final boss in bosses) {
      for (final skill in boss.skills) {
        final level = skillLevelsByName[skill.name];
        if (level != null) {
          character.levels[skill.id] = level.clamp(1, maxSkillRank).toInt();
        }
      }
    }
    _save();
    notifyListeners();
  }

  void setWeeklyCompleted(CharacterData character, bool completed) {
    character.weeklyCompletedWeek = completed ? currentWeekKey() : '';
    _save();
    notifyListeners();
  }

  void setSkillTradable(Skill skill, bool tradable) {
    skill.tradable = tradable;
    if (tradable) {
      if (!purpleSkills.contains(skill.name)) purpleSkills.add(skill.name);
    } else {
      final stillTradable = bosses
          .expand((boss) => boss.skills)
          .any((item) => item.name == skill.name && item.tradable);
      if (!stillTradable) purpleSkills.remove(skill.name);
    }
    _save();
    notifyListeners();
  }

  void removeCharacter(CharacterData character) {
    if (characters.length <= 1) return;
    characters.removeWhere((item) => item.id == character.id);
    _ensureSelectedCharacterIsActive();
    _save();
    notifyListeners();
  }
}

class SkillInputData {
  SkillInputData({required this.name, this.tradable = false});
  final String name;
  final bool tradable;
}

class SkillDraftController {
  SkillDraftController([String value = ''])
      : controller = TextEditingController(text: value);
  final TextEditingController controller;
  bool tradable = false;

  void dispose() => controller.dispose();
}

class BattleSkillsApp extends StatelessWidget {
  const BattleSkillsApp({required this.store, super.key});
  final SkillStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: store,
      builder: (context, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '百战异闻录助手',
          scrollBehavior: const _DesktopScrollBehavior(),
          themeMode: store.themeMode,
          theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: canvas,
              colorScheme:
                  ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.light)
                      .copyWith(
                          primary: teal,
                          onPrimary: Colors.white,
                          primaryContainer: const Color(0xffe1f1ea),
                          onPrimaryContainer: const Color(0xff245f4c),
                          secondary: const Color(0xff69a991),
                          secondaryContainer: const Color(0xffe8f3ee),
                          tertiary: const Color(0xff8bb7a5),
                          outline: const Color(0xffc5d5ce),
                          outlineVariant: line,
                          surface: Colors.white),
              fontFamily: 'Arial',
              textTheme: const TextTheme(
                  headlineSmall: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      height: 1.2),
                  titleLarge: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: ink),
                  titleMedium: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: ink),
                  bodyLarge: TextStyle(fontSize: 14, color: ink),
                  bodyMedium: TextStyle(fontSize: 13, color: ink),
                  labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xfff7f9f8), isDense: true, labelStyle: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w400), floatingLabelStyle: const TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.w400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: teal, width: 1.2)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11)),
              visualDensity: VisualDensity.compact,
              dividerTheme: const DividerThemeData(color: line, space: 1, thickness: 1),
              checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)), side: const BorderSide(color: teal, width: 1.5), fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? teal : Colors.transparent), checkColor: const WidgetStatePropertyAll<Color>(Colors.white)),
              appBarTheme: const AppBarTheme(centerTitle: false, titleSpacing: 24, backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
              navigationBarTheme: const NavigationBarThemeData(height: 62, labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w600)), indicatorColor: Color(0xffe5f3ed)),
              chipTheme: ChipThemeData(backgroundColor: const Color(0xfff7f9f8), side: const BorderSide(color: line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: ink)),
              popupMenuTheme: PopupMenuThemeData(color: const Color(0xf2f7fbf9), elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent, textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: ink), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: line))),
              dialogTheme: DialogThemeData(backgroundColor: const Color(0xf2f7fbf9), elevation: 0, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: line)), titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ink), contentTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: ink)),
              cardColor: Colors.white),
          darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xff121816), colorScheme: ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.dark).copyWith(primary: const Color(0xff76c7a7)), fontFamily: 'Arial', visualDensity: VisualDensity.compact, inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xff1c2521), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11)), popupMenuTheme: const PopupMenuThemeData(elevation: 0, shadowColor: Colors.transparent, surfaceTintColor: Colors.transparent), navigationBarTheme: const NavigationBarThemeData(height: 62)),
          home: Shell(store: store)));
}

class _DesktopScrollBehavior extends MaterialScrollBehavior {
  const _DesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

class Shell extends StatelessWidget {
  const Shell({required this.store, super.key});
  final SkillStore store;
  static const pageTitles = ['首页', '重要技能汇总', '可交易技能汇总', '所有技能汇总', '设置'];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          final content = Column(children: [
            if (store.availableBossCatalog != null)
              _BossCatalogUpdateBanner(store: store),
            Expanded(child: _page(context))
          ]);
          return Scaffold(
            body: SafeArea(
                child: wide
                    ? Row(children: [
                        SideNav(store: store),
                        Expanded(child: content)
                      ])
                    : content),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    selectedIndex: store.page.clamp(0, 4),
                    onDestinationSelected: store.setPage,
                    destinations: const [
                      NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: '首页'),
                      NavigationDestination(
                          icon: Icon(Icons.star_border),
                          selectedIcon: Icon(Icons.star),
                          label: '重要'),
                      NavigationDestination(
                          icon: Icon(Icons.auto_awesome_outlined),
                          selectedIcon: Icon(Icons.auto_awesome),
                          label: '可交易'),
                      NavigationDestination(
                          icon: Icon(Icons.account_tree_outlined),
                          selectedIcon: Icon(Icons.account_tree),
                          label: '所有技能'),
                      NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: '设置'),
                    ],
                  ),
          );
        },
      );
  Widget _page(BuildContext context) => switch (store.page) {
        1 => ImportantPage(store: store),
        2 => PurplePage(store: store),
        3 => AllSkillsPage(store: store),
        4 => SettingsPage(store: store),
        5 => CharacterManagementPage(store: store),
        6 => BossPage(store: store),
        7 => SyncBackupPage(store: store),
        _ => HomePage(store: store)
      };
}

class _BossCatalogUpdateBanner extends StatelessWidget {
  const _BossCatalogUpdateBanner({required this.store});
  final SkillStore store;

  @override
  Widget build(BuildContext context) {
    final catalog = store.availableBossCatalog!;
    return Material(
        color: const Color(0xffe8f3ee),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(children: [
              const Icon(Icons.system_update_alt, color: teal, size: 19),
              const SizedBox(width: 9),
              Expanded(
                  child: Text('发现首领技能数据更新（版本 ${catalog.version}）',
                      style: const TextStyle(
                          color: ink, fontWeight: FontWeight.w600))),
              TextButton(
                  onPressed: store.skipBossCatalogUpdate,
                  child: const Text('跳过此版本')),
              const SizedBox(width: 4),
              TextButton(
                  onPressed: store.dismissBossCatalogUpdate,
                  child: const Text('稍后')),
              const SizedBox(width: 4),
              FilledButton(
                  onPressed: () =>
                      _showBossCatalogUpdateDialog(context, store, catalog),
                  child: const Text('查看更新'))
            ])));
  }
}

Future<void> _showBossCatalogUpdateDialog(
    BuildContext context, SkillStore store, RemoteBossCatalog catalog) async {
  await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              title: const Text('首领技能数据更新'),
              content: SizedBox(
                  width: 420,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text('数据版本 ${catalog.version} · '
                            '${catalog.bosses.length} 个首领')),
                    if (catalog.updatedAt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('更新时间：${catalog.updatedAt}',
                              style:
                                  const TextStyle(color: muted, fontSize: 12)))
                    ],
                    if (catalog.notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(catalog.notes))
                    ],
                    const SizedBox(height: 14),
                    const Text('更新会同步首领基础信息和技能列表，并按技能保留角色现有重数。',
                        style: TextStyle(color: muted, fontSize: 12))
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () async {
                      await store.applyBossCatalogUpdate();
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('首领技能数据已更新到版本 ${catalog.version}')));
                      }
                    },
                    child: const Text('立即更新'))
              ]));
}

class SideNav extends StatelessWidget {
  const SideNav({required this.store, super.key});
  final SkillStore store;
  @override
  Widget build(BuildContext context) {
    final configuredItems = store.navigationOrder
        .where(store.navigationVisible.contains)
        .map((id) => navigationPageOptions.firstWhere((item) => item.id == id));
    final items = [
      const NavigationPageOption(
          id: 'home', label: '首页', icon: Icons.dashboard_outlined, page: 0),
      ...configuredItems,
      const NavigationPageOption(
          id: 'settings', label: '设置', icon: Icons.settings_outlined, page: 4)
    ];
    return Container(
        width: 190,
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: line))),
        padding: const EdgeInsets.fromLTRB(16, 22, 12, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
              padding: EdgeInsets.only(left: 10, bottom: 26),
              child: Row(children: [
                Icon(Icons.auto_awesome, color: teal),
                SizedBox(width: 10),
                Text('百战异闻录助手',
                    style: TextStyle(
                        color: ink, fontSize: 18, fontWeight: FontWeight.w700))
              ])),
          ...items.map((item) => NavItem(
              label: store.navigationLabels[item.id] ?? item.label,
              icon: item.icon,
              selected: store.page == item.page ||
                  (item.page == 4 && (store.page == 4 || store.page == 7)),
              onTap: () => store.setPage(item.page))),
          const Spacer(),
          Text(
              '${store.activeCharacters.length} 个角色 · ${store.bosses.length} 个首领',
              style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 6),
          const Text('数据自动保存在本机', style: TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 4),
          const AppVersionText(fontSize: 11)
        ]));
  }
}

class AppVersionText extends StatelessWidget {
  const AppVersionText({this.fontSize = 12, super.key});
  final double fontSize;

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Text(
            info == null ? '版本读取中…' : '版本 ${info.version}+${info.buildNumber}',
            style: TextStyle(color: muted, fontSize: fontSize));
      });
}

class NavItem extends StatelessWidget {
  const NavItem(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap,
      super.key});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(
                  color:
                      selected ? const Color(0xffe1f1ea) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Icon(icon, size: 19, color: selected ? teal : muted),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                        color: selected ? teal : ink,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400))
              ]))));
}

class TopBar extends StatelessWidget {
  const TopBar({required this.store, super.key});
  final SkillStore store;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: const BoxDecoration(
          color: Colors.white, border: Border(bottom: BorderSide(color: line))),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final title =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Shell.pageTitles[store.page],
              style: const TextStyle(
                  fontSize: 23, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text(
              store.page == 0
                  ? '按角色查看精耐、技能重数和通本需求'
                  : '基于 season4 v4.1 初始数据，可继续维护',
              style: const TextStyle(color: muted, fontSize: 12))
        ]);
        final actions = Row(mainAxisSize: MainAxisSize.min, children: [
          CharacterPicker(store: store),
          const SizedBox(width: 6),
          IconButton(
              tooltip: '新增角色',
              onPressed: () => showCharacterDialog(context, store),
              icon: const Icon(Icons.person_add_alt_1, color: teal))
        ]);
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 14), actions])
            : Row(children: [Expanded(child: title), actions]);
      }));
}

class CharacterPicker extends StatelessWidget {
  const CharacterPicker({required this.store, super.key});
  final SkillStore store;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
      initialValue: store.selectedCharacterId,
      onSelected: store.selectCharacter,
      itemBuilder: (context) => store.activeCharacters
          .map((character) =>
              PopupMenuItem(value: character.id, child: Text(character.name)))
          .toList(),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
              color: const Color(0xfff7f9f8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
                radius: 13,
                backgroundColor: teal.withOpacity(.14),
                child: Text(
                    store.selectedCharacter == null ||
                            store.selectedCharacter!.name.isEmpty
                        ? '角'
                        : store.selectedCharacter!.name.substring(0, 1),
                    style: const TextStyle(fontSize: 12, color: teal))),
            const SizedBox(width: 8),
            Text(store.selectedCharacter?.name ?? '选择角色',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, color: ink)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: muted)
          ])));
}

class PageBody extends StatelessWidget {
  const PageBody({required this.child, super.key, this.title, this.action});
  final Widget child;
  final String? title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 34),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null)
          Row(children: [
            Text(title!,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
            const Spacer(),
            if (action != null) action!
          ]),
        if (title != null) const SizedBox(height: 14),
        child
      ]));
}

double _filterItemWidth(double maxWidth, int itemCount) {
  final columns = itemCount <= 3
      ? itemCount
      : maxWidth >= 900
          ? itemCount
          : maxWidth >= 640
              ? math.min(itemCount, 3)
              : maxWidth >= 360
                  ? math.min(itemCount, 2)
                  : 1;
  final width = (maxWidth - (columns - 1) * 10) / columns;
  return itemCount <= 3 ? width : math.min(width, 280.0);
}

double _singleLineTextWidth(
    BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1)
    ..layout();
  return painter.width;
}

double _filterMenuWidth(BuildContext context,
    {required double triggerWidth,
    required Iterable<String> labels,
    double fontSize = 12,
    bool searchable = false}) {
  const horizontalPadding = 24.0;
  const checkWidth = 18.0;
  const checkGap = 5.0;
  final textStyle = TextStyle(fontSize: fontSize, color: ink);
  final widestLabel = labels.fold<double>(0, (widest, label) {
    return math.max(widest, _singleLineTextWidth(context, label, textStyle));
  });
  final contentWidth = widestLabel + horizontalPadding + checkWidth + checkGap;
  final minimumWidth = math.max(triggerWidth, searchable ? 180.0 : 140.0);
  final availableWidth = math.max(1.0, MediaQuery.sizeOf(context).width - 24.0);
  return math.min(
      math.min(280.0, availableWidth), math.max(minimumWidth, contentWidth));
}

Widget _equalCardRow(List<Widget> cards, double maxWidth) {
  return SizedBox(
      width: maxWidth,
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards.asMap().entries.map((entry) {
            final last = entry.key == cards.length - 1;
            return Expanded(
                child: Padding(
                    padding: EdgeInsets.only(right: last ? 0 : 12),
                    child: entry.value));
          }).toList()));
}

class _FilterDropdown<T> extends StatefulWidget {
  const _FilterDropdown(
      {required this.value,
      required this.values,
      required this.itemLabel,
      required this.width,
      required this.onChanged,
      this.compactLabel,
      this.searchable = false});
  final T value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final String Function(T value)? compactLabel;
  final double width;
  final ValueChanged<T?> onChanged;
  final bool searchable;

  @override
  State<_FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<_FilterDropdown<T>> {
  final _layerLink = LayerLink();
  final _menuController = OverlayPortalController();
  final _searchController = TextEditingController();
  double _menuHeight = 0;
  double _menuWidth = 0;
  double _menuOffsetX = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _closeMenu() {
    if (_menuController.isShowing) _menuController.hide();
  }

  double _spaceBelow() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return 0;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    return MediaQuery.sizeOf(context).height -
        MediaQuery.viewPaddingOf(context).bottom -
        bottom -
        14;
  }

  Future<void> _toggleMenu() async {
    if (_menuController.isShowing) {
      _closeMenu();
      return;
    }
    if (_spaceBelow() < 120) {
      await Scrollable.ensureVisible(context,
          alignment: 0.15,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut);
      if (!mounted) return;
    }
    _searchController.clear();
    final searchHeight = widget.searchable ? 50.0 : 0.0;
    _menuHeight = math.min(
        math.min(widget.values.length * 44.0 + 12 + searchHeight, 300.0),
        math.max(0.0, _spaceBelow()));
    if (_menuHeight < 1) return;
    _menuWidth = _filterMenuWidth(context,
        triggerWidth: widget.width,
        labels: widget.values.map(widget.itemLabel),
        searchable: widget.searchable);
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final left = box.localToGlobal(Offset.zero).dx;
      final preferredLeft = left + (widget.width - _menuWidth) / 2;
      final maxLeft =
          math.max(12.0, MediaQuery.sizeOf(context).width - _menuWidth - 12.0);
      final clampedLeft = preferredLeft.clamp(12.0, maxLeft).toDouble();
      _menuOffsetX = clampedLeft - left;
    } else {
      _menuOffsetX = (widget.width - _menuWidth) / 2;
    }
    _menuController.show();
  }

  Widget _buildMenu(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final values = widget.values
        .where((item) =>
            query.isEmpty ||
            widget.itemLabel(item).toLowerCase().contains(query))
        .toList();
    return Stack(children: [
      Positioned.fill(
          child: GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: _closeMenu)),
      CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(_menuOffsetX, 49),
          child: SizedBox(
              width: _menuWidth,
              height: _menuHeight,
              child: Material(
                  color: const Color(0xfff9fdfb),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xffd5e8df))),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    if (widget.searchable)
                      Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                          child: SizedBox(
                              height: 40,
                              child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                      isDense: true,
                                      prefixIcon: Icon(Icons.search, size: 16),
                                      prefixIconConstraints:
                                          BoxConstraints(minWidth: 32),
                                      hintText: '输入筛选')))),
                    Expanded(
                        child: values.isEmpty
                            ? const Center(
                                child: Text('没有匹配项',
                                    style:
                                        TextStyle(color: muted, fontSize: 12)))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                itemCount: values.length,
                                itemBuilder: (context, index) {
                                  final item = values[index];
                                  return InkWell(
                                      onTap: () {
                                        _closeMenu();
                                        widget.onChanged(item);
                                      },
                                      child: SizedBox(
                                          height: 44,
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: Row(children: [
                                                SizedBox(
                                                    width: 18,
                                                    child: item == widget.value
                                                        ? const Icon(
                                                            Icons.check,
                                                            size: 15,
                                                            color: teal)
                                                        : null),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                    child: Text(
                                                        widget.itemLabel(item),
                                                        maxLines: 1,
                                                        softWrap: false,
                                                        style: const TextStyle(
                                                            color: ink,
                                                            fontSize: 12)))
                                              ]))));
                                }))
                  ]))))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final selectedLabel = compact && widget.compactLabel != null
        ? widget.compactLabel!(widget.value)
        : widget.itemLabel(widget.value);
    return OverlayPortal(
        controller: _menuController,
        overlayChildBuilder: _buildMenu,
        child: CompositedTransformTarget(
            link: _layerLink,
            child: SizedBox(
                width: widget.width,
                height: 42,
                child: InkWell(
                    onTap: _toggleMenu,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        decoration: BoxDecoration(
                            color: const Color(0xfff9fdfb),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xffd5e8df))),
                        child: Row(children: [
                          Expanded(
                              child: Text(selectedLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500))),
                          const SizedBox(width: 5),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 17, color: muted)
                        ]))))));
  }
}

class _LabeledFilterDropdown<T> extends StatelessWidget {
  const _LabeledFilterDropdown(
      {required this.label,
      required this.value,
      required this.values,
      required this.itemLabel,
      required this.width,
      required this.onChanged});

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final double width;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: formLabelStyle),
            const SizedBox(height: 5),
            _FilterDropdown<T>(
                value: value,
                values: values,
                itemLabel: itemLabel,
                width: width,
                onChanged: onChanged)
          ]);
}

class _NameAutocomplete extends StatefulWidget {
  const _NameAutocomplete(
      {required this.controller,
      required this.names,
      required this.width,
      required this.hint,
      required this.compactHint});
  final TextEditingController controller;
  final List<String> names;
  final double width;
  final String hint;
  final String compactHint;

  @override
  State<_NameAutocomplete> createState() => _NameAutocompleteState();
}

class _NameAutocompleteState extends State<_NameAutocomplete> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _NameAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SizedBox(
        width: widget.width,
        height: 42,
        child: RawAutocomplete<String>(
            textEditingController: widget.controller,
            focusNode: focusNode,
            optionsViewOpenDirection: OptionsViewOpenDirection.down,
            displayStringForOption: (option) => option,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              return widget.names
                  .where((name) =>
                      query.isEmpty || name.toLowerCase().contains(query))
                  .toSet();
            },
            optionsViewBuilder: (context, onSelected, options) {
              final values = options.toList();
              final menuWidth = _filterMenuWidth(context,
                  triggerWidth: widget.width,
                  labels: values,
                  fontSize: 13,
                  searchable: true);
              return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                      width: menuWidth,
                      child: Material(
                          color: const Color(0xfff9fdfb),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xffd5e8df))),
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  shrinkWrap: true,
                                  itemCount: values.length,
                                  itemBuilder: (context, index) => InkWell(
                                      onTap: () => onSelected(values[index]),
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 13, vertical: 10),
                                          child: Text(values[index],
                                              maxLines: 1,
                                              softWrap: false,
                                              style: const TextStyle(
                                                  color: ink,
                                                  fontSize: 13)))))))));
            },
            fieldViewBuilder: (context, textController, focusNode,
                    onFieldSubmitted) =>
                TextField(
                    controller: textController,
                    focusNode: focusNode,
                    style: const TextStyle(
                        color: ink, fontSize: 12, fontWeight: FontWeight.w500),
                    onSubmitted: (_) => onFieldSubmitted(),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        prefixIcon: const Icon(Icons.search, size: 17),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 34),
                        hintText: compact ? widget.compactHint : widget.hint,
                        hintStyle: const TextStyle(color: muted, fontSize: 12),
                        suffixIcon: textController.text.isEmpty
                            ? IconButton(
                                tooltip: '展开技能列表',
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    size: 17),
                                onPressed: focusNode.requestFocus)
                            : IconButton(
                                tooltip: '清除',
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 15),
                                onPressed: textController.clear),
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 34)))));
  }
}

class CharacterFilterPanel extends StatefulWidget {
  const CharacterFilterPanel({required this.store, super.key});
  final SkillStore store;

  @override
  State<CharacterFilterPanel> createState() => _CharacterFilterPanelState();
}

class _CharacterFilterPanelState extends State<CharacterFilterPanel> {
  final query = TextEditingController();
  String gender = '全部';
  String school = '全部';

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  List<CharacterData> get matches =>
      widget.store.activeCharacters.where((character) {
        final text = query.text.trim().toLowerCase();
        return (text.isEmpty || character.name.toLowerCase().contains(text)) &&
            (gender == '全部' || character.gender == gender) &&
            (school == '全部' || character.school == school);
      }).toList();

  @override
  Widget build(BuildContext context) => CardShell(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.manage_search, color: teal),
          const SizedBox(width: 9),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('角色筛选',
                    style: TextStyle(
                        color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('按角色名、性别和门派快速找到要查看的角色',
                    style: TextStyle(color: muted, fontSize: 12))
              ])),
          Text('${matches.length} 个匹配',
              style: const TextStyle(color: teal, fontWeight: FontWeight.w800))
        ]),
        const SizedBox(height: 15),
        LayoutBuilder(builder: (context, constraints) {
          final width = _filterItemWidth(constraints.maxWidth, 3);
          return Wrap(spacing: 10, runSpacing: 10, children: [
            SizedBox(
                width: width,
                height: 42,
                child: TextField(
                    controller: query,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        prefixIcon: Icon(Icons.search, size: 17),
                        prefixIconConstraints: BoxConstraints(minWidth: 34),
                        hintText: '角色名称',
                        hintStyle: TextStyle(color: muted, fontSize: 12)))),
            _filterSelect('性别', gender, ['全部', '女性', '男性'], (value) {
              setState(() => gender = value!);
            }, width),
            _filterSelect('门派', school, ['全部', ...schoolOptions], (value) {
              setState(() => school = value!);
            }, width, searchable: true)
          ]);
        }),
        const SizedBox(height: 15),
        if (matches.isEmpty)
          const Text('没有符合条件的角色', style: TextStyle(color: muted, fontSize: 12))
        else
          Wrap(
              spacing: 10,
              runSpacing: 10,
              children: matches
                  .map((character) => _CharacterResultTile(
                      character: character,
                      selected:
                          character.id == widget.store.selectedCharacterId,
                      onTap: () => widget.store.selectCharacter(character.id)))
                  .toList())
      ]));

  Widget _filterSelect(String label, String value, List<String> values,
          ValueChanged<String?> onChanged, double width,
          {bool searchable = false}) =>
      _FilterDropdown<String>(
          value: value,
          values: values,
          itemLabel: (item) => item,
          width: width,
          searchable: searchable,
          onChanged: onChanged);
}

class _CharacterResultTile extends StatelessWidget {
  const _CharacterResultTile(
      {required this.character, required this.selected, required this.onTap});
  final CharacterData character;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 270),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color:
                  selected ? const Color(0xffe1f1ea) : const Color(0xfff7f9f8),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: selected ? teal : line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            MindAvatar(character: character, radius: 17),
            const SizedBox(width: 9),
            Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(character.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: ink, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                      '${character.gender} · ${character.school} · ${character.position}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11)),
                  Text(character.mind,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11))
                ]))
          ])));
}

class HomePage extends StatefulWidget {
  const HomePage({required this.store, super.key});
  final SkillStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool syncing = false;
  String cdFilter = '全部';
  String schoolFilter = '全部';
  String positionFilter = '全部';

  SkillStore get store => widget.store;

  @override
  Widget build(BuildContext context) {
    final character = store.selectedCharacter;
    final visibleCharacters = store.activeCharacters.where((item) {
      final matchesCd = cdFilter == '全部' ||
          (cdFilter == '已完成' && item.weeklyCompleted) ||
          (cdFilter == '未完成' && !item.weeklyCompleted);
      final matchesSchool = schoolFilter == '全部' || item.school == schoolFilter;
      final matchesPosition =
          positionFilter == '全部' || item.position == positionFilter;
      return matchesCd && matchesSchool && matchesPosition;
    }).toList();
    return PageBody(
        title: '首页',
        action: Text(
            '${store.activeCharacters.length} 个角色 · ${store.bosses.length} 个首领',
            style: const TextStyle(color: teal, fontWeight: FontWeight.w600)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _syncStatusBar(context),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final width = _filterItemWidth(constraints.maxWidth, 3);
            return Wrap(spacing: 10, runSpacing: 10, children: [
              _FilterDropdown<String>(
                  value: cdFilter,
                  values: const ['全部', '未完成', '已完成'],
                  itemLabel: (value) => value == '全部' ? '全部本周 CD' : value,
                  compactLabel: (value) => value == '全部' ? '本周 CD' : value,
                  width: width,
                  onChanged: (value) =>
                      setState(() => cdFilter = value ?? '全部')),
              _FilterDropdown<String>(
                  value: schoolFilter,
                  values: const ['全部', ...schoolOptions],
                  itemLabel: (value) => value == '全部' ? '全部门派' : value,
                  compactLabel: (value) => value == '全部' ? '门派' : value,
                  width: width,
                  searchable: true,
                  onChanged: (value) =>
                      setState(() => schoolFilter = value ?? '全部')),
              _FilterDropdown<String>(
                  value: positionFilter,
                  values: const ['全部', ...positionOptions],
                  itemLabel: (value) => value == '全部' ? '全部定位' : value,
                  compactLabel: (value) => value == '全部' ? '定位' : value,
                  width: width,
                  onChanged: (value) =>
                      setState(() => positionFilter = value ?? '全部'))
            ]);
          }),
          const SizedBox(height: 10),
          CharacterSwitcher(store: store, characters: visibleCharacters),
          const SizedBox(height: 14),
          CardShell(
              child: Row(children: [
            const Icon(Icons.auto_awesome, color: teal, size: 28),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('百战异闻录助手',
                      style: TextStyle(
                          color: ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      character == null
                          ? '请先添加一个角色'
                          : '当前查看：${character.name} · ${character.school} · ${character.mind} · 换将点 ${character.swapPoints}',
                      style: const TextStyle(color: muted, fontSize: 12))
                ])),
            if (character != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Transform.scale(
                    scale: .9,
                    child: Checkbox(
                        value: character.weeklyCompleted,
                        onChanged: (value) => store.setWeeklyCompleted(
                            character, value ?? false))),
                const Text('本周 CD',
                    style: TextStyle(
                        color: teal, fontWeight: FontWeight.w600, fontSize: 12))
              ])
          ])),
          const SizedBox(height: 18),
          if (character != null) ...[
            LayoutBuilder(builder: (context, constraints) {
              final allSkills = store.bosses
                  .expand((boss) => boss.skills)
                  .where(
                      (skill) => skillAppliesToGender(skill, character.gender))
                  .toList();
              int completed(Iterable<String> names) => names
                  .where((name) =>
                      store.skillLevelForName(character.id, name) >=
                      store.maxSkillRank)
                  .length;
              final firstRow = [
                MetricCard(
                    width: double.infinity,
                    height: 120,
                    label: '精神值',
                    value: formatNumber(store.stat(character.id, true)),
                    accent: teal,
                    icon: Icons.bolt),
                MetricCard(
                    width: double.infinity,
                    height: 120,
                    label: '耐力值',
                    value: formatNumber(store.stat(character.id, false)),
                    accent: const Color(0xff69a991),
                    icon: Icons.shield_outlined),
                HomeBookNeeds(store: store, character: character, height: 120)
              ];
              final secondRow = [
                MetricCard(
                    width: double.infinity,
                    height: 120,
                    label: '重要技能收集进度',
                    value:
                        '${completed(store.importantSkills)}/${store.importantSkills.length}',
                    accent: teal,
                    icon: Icons.star_outline,
                    onTap: () => store.openSkillPage(1, character.id)),
                MetricCard(
                    width: double.infinity,
                    height: 120,
                    label: '可交易技能收集进度',
                    value:
                        '${completed(store.purpleSkills)}/${store.purpleSkills.length}',
                    accent: purple,
                    icon: Icons.auto_awesome_outlined,
                    onTap: () => store.openSkillPage(2, character.id)),
                MetricCard(
                    width: double.infinity,
                    height: 120,
                    label: '现有技能收集进度',
                    value:
                        '${allSkills.where((skill) => store.level(character.id, skill.id) >= store.maxSkillRank).length}/${allSkills.length}',
                    accent: const Color(0xff69a991),
                    icon: Icons.menu_book_outlined,
                    onTap: () => store.openSkillPage(3, character.id))
              ];
              return Column(children: [
                _equalCardRow(firstRow, constraints.maxWidth),
                const SizedBox(height: 12),
                _equalCardRow(secondRow, constraints.maxWidth)
              ]);
            }),
            const SizedBox(height: 2),
          ]
        ]));
  }

  Widget _syncStatusBar(BuildContext context) => CardShell(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        const Icon(Icons.cloud_sync_outlined, color: teal, size: 22),
        const SizedBox(width: 10),
        const Text('同步状态',
            style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                store.newerRemoteBackup != null
                    ? '发现较新的云端备份，请先恢复后再同步'
                    : store.lastSyncAt == null
                        ? (store.syncConfig?.isValid == true
                            ? '尚未同步'
                            : '未配置 WebDAV')
                        : '上次成功 ${store.lastSyncAt!.toLocal().toString().substring(0, 16)}',
                style: const TextStyle(color: ink, fontSize: 12))),
        if (store.newerRemoteBackup != null)
          IconButton(
              tooltip: '恢复较新的云端备份',
              onPressed: store.restoreBusy
                  ? null
                  : () => confirmRemoteBackupRestore(
                      context, store, store.newerRemoteBackup!),
              icon: const Icon(Icons.cloud_download_outlined, color: gold)),
        IconButton(
            tooltip: '立即同步',
            onPressed: syncing || store.restoreBusy
                ? null
                : () async {
                    setState(() => syncing = true);
                    await store.syncNow();
                    if (mounted) setState(() => syncing = false);
                  },
            icon: syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync, color: teal)),
        IconButton(
            tooltip: '同步设置',
            onPressed: () => store.setPage(7),
            icon: const Icon(Icons.settings_outlined, color: muted))
      ]));
}

class ExistingSkillsPanel extends StatefulWidget {
  const ExistingSkillsPanel(
      {required this.store, required this.character, super.key});
  final SkillStore store;
  final CharacterData character;

  @override
  State<ExistingSkillsPanel> createState() => _ExistingSkillsPanelState();
}

class _ExistingSkillsPanelState extends State<ExistingSkillsPanel> {
  final bossQuery = TextEditingController();
  int maxRank = 0;

  @override
  void initState() {
    super.initState();
    bossQuery.addListener(_onBossQueryChanged);
  }

  void _onBossQueryChanged() => setState(() {});

  @override
  void dispose() {
    bossQuery.removeListener(_onBossQueryChanged);
    bossQuery.dispose();
    super.dispose();
  }

  SkillStore get store => widget.store;
  CharacterData get character => widget.character;

  bool _matches(Skill skill) {
    if (!skillAppliesToGender(skill, character.gender)) return false;
    final level = store.level(character.id, skill.id);
    return maxRank == 0 ? level > 0 : level > 0 && level <= maxRank;
  }

  List<Boss> get visibleBosses {
    final query = bossQuery.text.trim().toLowerCase();
    return store.bosses
        .where((boss) =>
            (query.isEmpty || boss.name.toLowerCase().contains(query)) &&
            boss.skills.any(_matches))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bosses = visibleBosses;
    final filteredSkillCount = bosses.fold<int>(
        0, (count, boss) => count + boss.skills.where(_matches).length);
    return CardShell(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('现有技能',
                style: TextStyle(
                    color: ink, fontSize: 15, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('$filteredSkillCount 个技能',
                style: const TextStyle(color: teal, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final width = _filterItemWidth(constraints.maxWidth, 2);
            return Wrap(spacing: 10, runSpacing: 10, children: [
              _NameAutocomplete(
                  controller: bossQuery,
                  names: store.bosses.map((boss) => boss.name).toList(),
                  width: width,
                  hint: '全部首领',
                  compactHint: '首领'),
              _FilterDropdown<int>(
                  value: maxRank,
                  values: [
                    0,
                    ...List.generate(store.maxSkillRank,
                        (index) => store.maxSkillRank - index)
                  ],
                  itemLabel: (value) => value == 0 ? '全部重数' : '$value 重及以下',
                  compactLabel: (value) => value == 0 ? '重数' : '$value 重以下',
                  width: width,
                  onChanged: (value) =>
                      setState(() => maxRank = value ?? maxRank))
            ]);
          }),
          const SizedBox(height: 6),
          const Text('点击技能可修改重数；名称、可交易状态和删除请前往首领技能管理。',
              style: TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 4),
          if (bosses.isEmpty)
            const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('没有符合筛选条件的技能',
                    style: TextStyle(color: muted, fontSize: 12)))
          else ...[
            const SizedBox(height: 10),
            Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                color: const Color(0xfff7f9f8),
                child: const Row(children: [
                  Expanded(
                      flex: 3,
                      child: Text('首领',
                          style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                  Expanded(
                      flex: 5,
                      child: Text('技能',
                          style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 58,
                      child: Text('重数',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)))
                ])),
            for (final boss in bosses)
              for (final entry
                  in boss.skills.where(_matches).toList().asMap().entries)
                InkWell(
                    onTap: () async {
                      await showSkillDialog(context, store, entry.value);
                      if (mounted) setState(() {});
                    },
                    child: Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: line))),
                        child: Row(children: [
                          Expanded(
                              flex: 3,
                              child: Text(
                                  entry.key == 0
                                      ? bossNameForGender(
                                          boss, character.gender)
                                      : '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700))),
                          Expanded(
                              flex: 5,
                              child: Text(
                                  skillNameForGender(
                                      entry.value, character.gender),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color:
                                          entry.value.tradable ? purple : ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500))),
                          SizedBox(
                              width: 58,
                              child: Text(
                                  '${store.level(character.id, entry.value.id)} 重',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)))
                        ])))
          ]
        ]));
  }
}

class HomeBookNeeds extends StatelessWidget {
  const HomeBookNeeds(
      {required this.store,
      required this.character,
      this.height = 120,
      super.key});
  final SkillStore store;
  final CharacterData character;
  final double height;

  @override
  Widget build(BuildContext context) {
    final needs = store.bookNeeds(character.id);
    return SizedBox(
        height: height,
        child: CardShell(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('通本需求',
                  style: TextStyle(
                      color: ink, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('按当前技能重数估算',
                  style: TextStyle(color: muted, fontSize: 11)),
              const Spacer(),
              LayoutBuilder(builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: needs.entries
                        .map((entry) => SizedBox(
                            width: itemWidth,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key,
                                      style: const TextStyle(
                                          color: muted,
                                          fontSize: 10,
                                          height: 1.1)),
                                  Text('${entry.value}',
                                      style: const TextStyle(
                                          color: ink,
                                          fontSize: 14,
                                          height: 1.15,
                                          fontWeight: FontWeight.w800))
                                ])))
                        .toList());
              })
            ])));
  }
}

class MindAvatar extends StatelessWidget {
  const MindAvatar(
      {required this.character,
      this.radius = 19,
      this.showCompletion = true,
      super.key});
  final CharacterData character;
  final double radius;
  final bool showCompletion;

  @override
  Widget build(BuildContext context) {
    final asset = mindIconAssets[normalizeMind(character.mind)];
    final size = radius * 2;
    return SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, children: [
          ClipOval(
              child: Container(
                  width: size,
                  height: size,
                  color: const Color(0xffe5ece8),
                  child: asset == null
                      ? Center(
                          child: Text(
                              character.name.isEmpty
                                  ? '角'
                                  : character.name.substring(0, 1),
                              style: const TextStyle(
                                  color: teal, fontWeight: FontWeight.w800)))
                      : Image.asset(asset,
                          width: size, height: size, fit: BoxFit.cover))),
          if (showCompletion && character.weeklyCompleted)
            Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                    width: radius * .9,
                    height: radius * .9,
                    decoration: BoxDecoration(
                        color: teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                    child: Icon(Icons.check,
                        color: Colors.white, size: radius * .62)))
        ]));
  }
}

class CharacterSwitcher extends StatefulWidget {
  const CharacterSwitcher(
      {required this.store, this.onSelected, this.characters, super.key});
  final SkillStore store;
  final ValueChanged<String>? onSelected;
  final List<CharacterData>? characters;

  @override
  State<CharacterSwitcher> createState() => _CharacterSwitcherState();
}

class _CharacterSwitcherState extends State<CharacterSwitcher> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final delta =
        event.scrollDelta.dx != 0 ? event.scrollDelta.dx : event.scrollDelta.dy;
    if (delta == 0) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final position = _controller.position;
      _controller.jumpTo((_controller.offset + delta)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleCharacters =
        widget.characters ?? widget.store.activeCharacters;
    return Listener(
        onPointerSignal: _handlePointerSignal,
        child: SizedBox(
            height: 82,
            child: ListView.separated(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: visibleCharacters.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == visibleCharacters.length) {
                    return InkWell(
                        onTap: () => showCharacterDialog(context, widget.store),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                            width: 128,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                                color: const Color(0xfff7f9f8),
                                border: Border.all(color: teal),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: teal, size: 20),
                                  SizedBox(width: 6),
                                  Text('添加角色',
                                      style: TextStyle(
                                          color: teal,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700))
                                ])));
                  }
                  final character = visibleCharacters[index];
                  final active =
                      character.id == widget.store.selectedCharacterId;
                  final minds = schoolMindPositions[character.school];
                  final characterLabel =
                      minds?.length == 1 ? character.school : character.mind;
                  final subtitle = '$characterLabel · ${character.swapPoints}';
                  final characterWidth = math.max(
                      166.0,
                      math.max(
                              _singleLineTextWidth(
                                  context,
                                  character.name,
                                  const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              _singleLineTextWidth(context, subtitle,
                                  const TextStyle(fontSize: 10))) +
                          70);
                  return InkWell(
                      onTap: () {
                        widget.store.selectCharacter(character.id);
                        widget.onSelected?.call(character.id);
                      },
                      onDoubleTap: () => showCharacterDialog(
                          context, widget.store, character: character),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: characterWidth,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xffedf7f3)
                                  : const Color(0xfff7f9f8),
                              border: Border.all(color: active ? teal : line),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            MindAvatar(character: character),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(character.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: active ? teal : ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(subtitle,
                                      maxLines: 1,
                                      style: const TextStyle(
                                          color: muted, fontSize: 10))
                                ]))
                          ])));
                })));
  }
}

class CharacterManagementPage extends StatelessWidget {
  const CharacterManagementPage({required this.store, super.key});
  final SkillStore store;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1180
        ? 3
        : width >= 760
            ? 2
            : 1;
    return PageBody(
        title: '角色列表',
        action: Row(mainAxisSize: MainAxisSize.min, children: [
          TextButton.icon(
              onPressed: () => store.setPage(4),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('设置')),
          const SizedBox(width: 8),
          FilledButton.icon(
              onPressed: () => showCharacterDialog(context, store),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('添加角色'))
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('按角色管理独立的技能重数记录，双击角色可编辑；打叉后不会出现在其他页面。',
              style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 18),
          if (store.characters.isEmpty)
            const CardShell(
                child: Text('暂无角色，请先添加角色。', style: TextStyle(color: muted)))
          else
            GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: store.characters.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 216),
                itemBuilder: (context, index) {
                  final character = store.characters[index];
                  final levels = character.levels.values;
                  final progress = levels.isEmpty
                      ? 0.0
                      : levels.fold<int>(0, (sum, value) => sum + value) /
                          (levels.length * store.maxSkillRank);
                  final spirit = store.stat(character.id, true);
                  final stamina = store.stat(character.id, false);
                  return DragTarget<String>(
                      onWillAcceptWithDetails: (details) =>
                          details.data != character.id,
                      onAcceptWithDetails: (details) =>
                          store.reorderCharacter(details.data, character.id),
                      builder: (context, candidates, rejected) => LongPressDraggable<
                              String>(
                          data: character.id,
                          feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                  width: 260,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: teal),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x22000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 5))
                                      ]),
                                  child: Row(children: [
                                    const Icon(Icons.drag_indicator,
                                        color: teal),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(character.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: ink,
                                                fontWeight: FontWeight.w700)))
                                  ]))),
                          child: InkWell(
                              onDoubleTap: () => showCharacterDialog(
                                  context, store, character: character),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                      color: character.archived
                                          ? const Color(0xfff4f7f5)
                                          : Colors.white,
                                      border: Border.all(
                                          color: character.archived
                                              ? const Color(0xffd5dfda)
                                              : line),
                                      borderRadius: BorderRadius.circular(10)),
                                  child:
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      const Tooltip(
                                          message: '长按角色卡片拖动调整顺序',
                                          child: Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8),
                                              child: Icon(Icons.drag_indicator,
                                                  color: muted))),
                                      MindAvatar(
                                          character: character, radius: 23),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(character.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: ink,
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.w700))),
                                      Tooltip(
                                          message: character.archived
                                              ? '已禁用，点击启用'
                                              : '已启用，点击禁用',
                                          child: Listener(
                                              behavior: HitTestBehavior.opaque,
                                              onPointerUp: (_) =>
                                                  store.setCharacterArchived(
                                                      character,
                                                      !character.archived),
                                              child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  margin: const EdgeInsets.only(
                                                      right: 2),
                                                  decoration: BoxDecoration(
                                                      color: character.archived
                                                          ? const Color(
                                                              0xfff3e9e7)
                                                          : const Color(
                                                              0xffe2f3eb),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(color: character.archived ? const Color(0xffd5aaa2) : const Color(0xffacd7c4))),
                                                  child: Icon(character.archived ? Icons.toggle_off_rounded : Icons.toggle_on_rounded, size: 19, color: character.archived ? const Color(0xffa96d65) : teal)))),
                                      Tooltip(
                                          message: '编辑角色',
                                          child: Listener(
                                              behavior: HitTestBehavior.opaque,
                                              onPointerUp: (_) =>
                                                  showCharacterDialog(
                                                      context, store,
                                                      character: character),
                                              child: const Padding(
                                                  padding: EdgeInsets.all(6),
                                                  child: Icon(
                                                      Icons.edit_outlined,
                                                      color: muted,
                                                      size: 20))))
                                    ]),
                                    const SizedBox(height: 14),
                                    Text(
                                        '${character.school} · ${character.mind} · ${character.position} · 换将点 ${character.swapPoints}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: muted, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: LinearProgressIndicator(
                                            value: progress.clamp(0, 1),
                                            minHeight: 7,
                                            backgroundColor:
                                                const Color(0xffe2e9e5),
                                            color: character.archived
                                                ? muted
                                                : teal)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Text('精神 ${formatNumber(spirit)}',
                                          style: const TextStyle(
                                              color: ink,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      Text('耐力 ${formatNumber(stamina)}',
                                          style: const TextStyle(
                                              color: ink,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600))
                                    ]),
                                    const Spacer(),
                                    Row(children: [
                                      Text(
                                          '${(progress * 100).round()}% 技能重数进度',
                                          style: const TextStyle(
                                              color: muted, fontSize: 12)),
                                      const Spacer(),
                                      Text(
                                          character.archived ? '已禁用' : '双击编辑角色',
                                          style: TextStyle(
                                              color: character.archived
                                                  ? muted
                                                  : teal,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700))
                                    ])
                                  ])))));
                })
        ]));
  }
}

class CharacterPage extends StatelessWidget {
  const CharacterPage({required this.store, super.key});
  final SkillStore store;

  @override
  Widget build(BuildContext context) {
    final characters = store.activeCharacters;
    if (characters.isEmpty) {
      return PageBody(
          title: '角色',
          child: const CardShell(
              child: Text('暂无角色，请前往设置中的角色管理新增角色。',
                  style: TextStyle(color: muted))));
    }
    final selectedIndex = characters
        .indexWhere((item) => item.id == store.selectedCharacterId)
        .clamp(0, characters.length - 1);
    final selected = characters[selectedIndex];
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 12),
          child: Row(children: [
            const Expanded(
                child: Text('角色',
                    style: TextStyle(
                        color: ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w700))),
            Text('${selectedIndex + 1} / ${characters.length}',
                style:
                    const TextStyle(color: teal, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            TextButton.icon(
                onPressed: () => store.setPage(5),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('角色列表'))
          ])),
      SizedBox(
          height: 92,
          child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              scrollDirection: Axis.horizontal,
              itemCount: characters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final character = characters[index];
                final active = character.id == selected.id;
                return InkWell(
                    onTap: () => store.selectCharacter(character.id),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 156,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: active
                                ? const Color(0xffe1f1ea)
                                : const Color(0xfff7f9f8),
                            border: Border.all(color: active ? teal : line),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          MindAvatar(character: character),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(character.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: active ? teal : ink,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(
                                    '${character.mind} · ${character.position}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: muted, fontSize: 10))
                              ]))
                        ])));
              })),
      Expanded(
          child: OverviewPage(
              store: store, character: selected, onlyBossSkills: true))
    ]);
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage(
      {required this.store,
      this.character,
      this.onlyBossSkills = false,
      super.key});
  final SkillStore store;
  final CharacterData? character;
  final bool onlyBossSkills;
  @override
  Widget build(BuildContext context) {
    final current = character ?? store.selectedCharacter;
    if (current == null) return const SizedBox.shrink();
    final needs = store.bookNeeds(current.id);
    final skillCount = current.levels.values.where((value) => value > 0).length;
    final maxed = current.levels.values.where((value) => value >= 10).length;
    final compact = MediaQuery.sizeOf(context).width < 760;
    if (onlyBossSkills) {
      return PageBody(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CardShell(
            child: Row(children: [
          MindAvatar(character: current, radius: 24),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(current.name,
                    style: const TextStyle(
                        color: ink, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                    '${current.gender} · ${current.school} · ${current.mind} · ${current.position}',
                    style: const TextStyle(color: muted, fontSize: 12))
              ]))
        ])),
        const SizedBox(height: 18),
        const Text('首领技能重数',
            style: TextStyle(
                color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _bossTable(current)
      ]));
    }
    return PageBody(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, constraints) {
        final cards = [
          MetricCard(
              width: double.infinity,
              label: '精神值',
              value: formatNumber(store.stat(current.id, true)),
              accent: teal,
              icon: Icons.bolt),
          MetricCard(
              width: double.infinity,
              label: '耐力值',
              value: formatNumber(store.stat(current.id, false)),
              accent: const Color(0xff69a991),
              icon: Icons.shield_outlined),
          MetricCard(
              width: double.infinity,
              label: '已录入技能',
              value: '$skillCount / ${current.levels.length}',
              accent: gold,
              icon: Icons.menu_book_outlined),
          MetricCard(
              width: double.infinity,
              label: '十重技能',
              value: '$maxed',
              accent: purple,
              icon: Icons.workspace_premium_outlined)
        ];
        return _equalCardRow(cards, constraints.maxWidth);
      }),
      const SizedBox(height: 22),
      compact
          ? Column(children: [
              _characterCard(context, current),
              const SizedBox(height: 18),
              _bookCard(needs)
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: _characterCard(context, current)),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: _bookCard(needs))
            ]),
      const SizedBox(height: 22),
      PageBody(title: '首领完成度', child: _bossTable(current))
    ]));
  }

  Widget _characterCard(BuildContext context, CharacterData character) =>
      CardShell(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          MindAvatar(character: character, radius: 24),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(character.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
                Text(
                    '${character.gender} · ${character.school} · ${character.mind} · ${character.position}',
                    style: const TextStyle(color: muted, fontSize: 12))
              ])),
        ]),
        const SizedBox(height: 24),
        Wrap(spacing: 28, runSpacing: 14, children: [
          InfoItem(
              label: '公式基础精神',
              value: formatNumber(store.computedBaseStat(character.id, true))),
          InfoItem(
              label: '公式基础耐力',
              value: formatNumber(store.computedBaseStat(character.id, false))),
          InfoItem(
              label: '未学技能',
              value: '${character.levels.values.where((v) => v == 0).length}')
        ])
      ]));
  Widget _bookCard(Map<String, int> needs) => CardShell(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('通本需求',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 5),
        const Text('按当前技能重数估算', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 16),
        ...needs.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(children: [
              Container(
                  width: 36,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: entry.key == '通本4'
                          ? const Color(0xfffff3dd)
                          : const Color(0xffe8f3ee),
                      borderRadius: BorderRadius.circular(7)),
                  child: Text(entry.key.substring(2),
                      style: TextStyle(
                          color: entry.key == '通本4' ? gold : teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              const Text('需要数量', style: TextStyle(color: muted, fontSize: 12)),
              const Spacer(),
              Text('${entry.value}',
                  style: const TextStyle(
                      color: ink, fontSize: 18, fontWeight: FontWeight.w800))
            ])))
      ]));
  Widget _bossTable(CharacterData character) => CardShell(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            color: const Color(0xfff7f9f8),
            child: const Row(children: [
              Expanded(
                  flex: 3,
                  child: Text('首领',
                      style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(
                  child: Text('完成重数',
                      style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(
                  child: Text('精神提升',
                      style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700))),
              Expanded(
                  child: Text('耐力提升',
                      style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)))
            ])),
        ...store.bosses.map((boss) {
          final rank = store.rankFor(character.id, boss);
          final multiplier =
              const [0, 1, 2, 3, 4, 5, 7, 10, 15, 22.5, 33.75][rank];
          return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: line))),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: Text(bossNameForGender(boss, character.gender),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: ink))),
                Expanded(child: RankBadge(rank: rank)),
                Expanded(
                    child: Text(
                        '+${formatNumber(bossStatForGender(boss, character.gender, true) * multiplier)}',
                        style: const TextStyle(
                            color: teal, fontWeight: FontWeight.w700))),
                Expanded(
                    child: Text(
                        '+${formatNumber(bossStatForGender(boss, character.gender, false) * multiplier)}',
                        style: const TextStyle(
                            color: Color(0xff69a991),
                            fontWeight: FontWeight.w700)))
              ]));
        })
      ]));
}

class SkillMatrix extends StatefulWidget {
  const SkillMatrix(
      {required this.store,
      required this.skillNames,
      this.accent = ink,
      this.characters,
      this.onDeleteSkill,
      super.key});
  final SkillStore store;
  final List<String> skillNames;
  final Color accent;
  final List<CharacterData>? characters;
  final ValueChanged<String>? onDeleteSkill;

  @override
  State<SkillMatrix> createState() => _SkillMatrixState();
}

class _SkillMatrixState extends State<SkillMatrix> {
  final horizontalController = ScrollController();

  @override
  void dispose() {
    horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final characters = widget.characters ?? store.activeCharacters;
    if (widget.skillNames.isEmpty) {
      return CardShell(
          child: const Text('暂无技能记录', style: TextStyle(color: muted)));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final skillColumnWidth = constraints.maxWidth < 600 ? 142.0 : 184.0;
      final characterColumnWidth = constraints.maxWidth < 600 ? 88.0 : 104.0;
      final visibleCharacterWidth =
          math.max(0.0, constraints.maxWidth - skillColumnWidth);
      final characterTableWidth = math.max(
          visibleCharacterWidth, characters.length * characterColumnWidth);
      final headerHeight = constraints.maxWidth < 600 ? 42.0 : 46.0;
      final rowHeight = constraints.maxWidth < 600 ? 46.0 : 50.0;

      String displaySkillLabel(String name) {
        final skill = store.findSkill(name);
        if (skill == null) return name;
        return characters.length == 1
            ? skillNameForGender(skill, characters.single.gender)
            : managementSkillName(skill);
      }

      Widget skillCell(String label,
              {bool header = false, String? skillName}) =>
          _SkillMatrixCell(
              width: skillColumnWidth,
              height: header ? headerHeight : rowHeight,
              header: header,
              alignment: Alignment.centerLeft,
              child: Row(children: [
                Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: header ? muted : widget.accent,
                            fontSize: header ? 12 : 13,
                            fontWeight:
                                header ? FontWeight.w700 : FontWeight.w600))),
                if (!header &&
                    skillName != null &&
                    widget.onDeleteSkill != null)
                  IconButton(
                      tooltip: '移除重要技能',
                      visualDensity: VisualDensity.compact,
                      iconSize: 17,
                      onPressed: () => widget.onDeleteSkill!(skillName),
                      icon: const Icon(Icons.close, color: muted))
              ]));

      Widget characterHeader(CharacterData character) => _SkillMatrixCell(
          width: characterColumnWidth,
          height: headerHeight,
          header: true,
          alignment: Alignment.center,
          child: Text(character.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: muted, fontSize: 12, fontWeight: FontWeight.w700)));

      return CardShell(
          padding: EdgeInsets.zero,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              skillCell('技能名称', header: true),
              ...widget.skillNames.map(
                  (name) => skillCell(displaySkillLabel(name), skillName: name))
            ]),
            Expanded(
                child: Scrollbar(
                    controller: horizontalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                        controller: horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                            width: characterTableWidth,
                            child: Column(children: [
                              Row(
                                  children:
                                      characters.map(characterHeader).toList()),
                              ...widget.skillNames.map((skillName) => Row(
                                  children: characters
                                      .map((character) => _SkillMatrixCell(
                                          width: characterColumnWidth,
                                          height: rowHeight,
                                          alignment: Alignment.center,
                                          child: RankBadge(
                                              rank: store.skillLevelForName(
                                                  character.id, skillName),
                                              plain: true)))
                                      .toList()))
                            ])))))
          ]));
    });
  }
}

class _SkillMatrixCell extends StatelessWidget {
  const _SkillMatrixCell(
      {required this.width,
      required this.height,
      required this.child,
      required this.alignment,
      this.header = false});
  final double width;
  final double height;
  final Widget child;
  final Alignment alignment;
  final bool header;

  @override
  Widget build(BuildContext context) => Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: header ? const Color(0xfff7f9f8) : Colors.white,
          border: const Border(
              right: BorderSide(color: line), bottom: BorderSide(color: line))),
      child: child);
}

class SkillSummaryFilters extends StatefulWidget {
  const SkillSummaryFilters(
      {required this.store,
      required this.skillNames,
      required this.accent,
      this.onDeleteSkill,
      super.key});
  final SkillStore store;
  final List<String> skillNames;
  final Color accent;
  final ValueChanged<String>? onDeleteSkill;

  @override
  State<SkillSummaryFilters> createState() => _SkillSummaryFiltersState();
}

class _SkillSummaryFiltersState extends State<SkillSummaryFilters> {
  final skillQuery = TextEditingController();
  String characterId = 'all';
  int maxRank = 0;

  @override
  void initState() {
    super.initState();
    skillQuery.addListener(_onSkillQueryChanged);
    characterId = widget.store.pendingSkillPageCharacterId ?? 'all';
    maxRank = widget.store.pendingSkillPageMaxRank ?? 0;
    widget.store.pendingSkillPageCharacterId = null;
    widget.store.pendingSkillPageMaxRank = null;
  }

  void _onSkillQueryChanged() => setState(() {});

  @override
  void dispose() {
    skillQuery.removeListener(_onSkillQueryChanged);
    skillQuery.dispose();
    super.dispose();
  }

  String get effectiveCharacterId => widget.store.activeCharacters
          .any((character) => character.id == characterId)
      ? characterId
      : 'all';

  List<CharacterData> get filteredCharacters => widget.store.activeCharacters
      .where((character) =>
          effectiveCharacterId == 'all' || character.id == effectiveCharacterId)
      .toList();

  List<String> get filteredSkills {
    final query = skillQuery.text.trim().toLowerCase();
    final characters = filteredCharacters;
    return widget.skillNames.where((name) {
      final matchesRank = maxRank == 0 ||
          characters.any((character) {
            final rank = widget.store.skillLevelForName(character.id, name);
            return rank > 0 && rank <= maxRank;
          });
      return (query.isEmpty || name.toLowerCase().contains(query)) &&
          matchesRank;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final characters = filteredCharacters;
    final skills = filteredSkills;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, constraints) {
        final width = _filterItemWidth(constraints.maxWidth, 3);
        return Wrap(spacing: 10, runSpacing: 10, children: [
          _FilterDropdown<String>(
              value: effectiveCharacterId,
              values: [
                'all',
                ...widget.store.activeCharacters.map((item) => item.id)
              ],
              itemLabel: (value) => value == 'all'
                  ? '全部角色'
                  : widget.store.activeCharacters
                      .firstWhere((item) => item.id == value)
                      .name,
              compactLabel: (value) => value == 'all'
                  ? '角色'
                  : widget.store.activeCharacters
                      .firstWhere((item) => item.id == value)
                      .name,
              width: width,
              searchable: true,
              onChanged: (value) =>
                  setState(() => characterId = value ?? 'all')),
          _NameAutocomplete(
              controller: skillQuery,
              names: widget.skillNames,
              width: width,
              hint: '技能名称',
              compactHint: '技能'),
          _FilterDropdown<int>(
              value: maxRank,
              values: [
                0,
                ...List.generate(widget.store.maxSkillRank,
                    (index) => widget.store.maxSkillRank - index)
              ],
              itemLabel: (value) => value == 0 ? '全部重数' : '$value 重及以下',
              compactLabel: (value) => value == 0 ? '重数' : '$value 重以下',
              width: width,
              onChanged: (value) => setState(() => maxRank = value ?? maxRank))
        ]);
      }),
      const SizedBox(height: 10),
      Text('技能 ${skills.length} 个 · 角色 ${characters.length} 个',
          style: TextStyle(
              color: widget.accent, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      if (characters.isEmpty)
        const CardShell(
            child: Text('没有符合条件的角色', style: TextStyle(color: muted)))
      else if (skills.isEmpty)
        const CardShell(
            child: Text('没有符合条件的技能', style: TextStyle(color: muted)))
      else
        SkillMatrix(
            store: widget.store,
            skillNames: skills,
            accent: widget.accent,
            characters: characters,
            onDeleteSkill: widget.onDeleteSkill)
    ]);
  }
}

class ImportantPage extends StatelessWidget {
  const ImportantPage({required this.store, super.key});
  final SkillStore store;

  @override
  Widget build(BuildContext context) => PageBody(
      title: '重要技能汇总',
      action: FilledButton.icon(
          onPressed: () => showImportantDialog(context, store),
          icon: const Icon(Icons.add, size: 17),
          label: const Text('添加技能')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text('重数随每个角色的技能页同步，仅用于查看，不在这里编辑。',
                style: TextStyle(color: muted, fontSize: 12))),
        SkillSummaryFilters(
            store: store,
            skillNames: store.importantSkills,
            accent: ink,
            onDeleteSkill: (name) =>
                showRemoveImportantSkillDialog(context, store, name))
      ]));
}

class PurplePage extends StatelessWidget {
  const PurplePage({required this.store, super.key});
  final SkillStore store;

  @override
  Widget build(BuildContext context) {
    final highest = store.purpleSkills.fold<int>(
        0,
        (current, name) =>
            math.max(current, store.highestSkillLevelForName(name)));
    final highestCount = store.purpleSkills
        .where((name) => store.highestSkillLevelForName(name) == highest)
        .length;
    return PageBody(
        title: '可交易技能统计',
        action: Text('${store.purpleSkills.length} 个可交易技能',
            style: const TextStyle(color: purple, fontWeight: FontWeight.w700)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CardShell(
                  child: Row(children: [
                const Icon(Icons.auto_awesome, color: purple),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('可交易技能以紫色标识，重数按角色技能页同步展示。',
                        style: TextStyle(color: muted, fontSize: 12))),
                Text(
                    highest == 0 ? '暂无已学习' : '$highestCount 个达到最高 ${highest} 重',
                    style: const TextStyle(
                        color: purple, fontWeight: FontWeight.w700))
              ]))),
          SkillSummaryFilters(
              store: store, skillNames: store.purpleSkills, accent: purple)
        ]));
  }
}

class AllSkillsPage extends StatefulWidget {
  const AllSkillsPage({required this.store, super.key});
  final SkillStore store;

  @override
  State<AllSkillsPage> createState() => _AllSkillsPageState();
}

class _AllSkillsPageState extends State<AllSkillsPage> {
  final bossQuery = TextEditingController();
  String characterId = 'all';
  int maxRank = 0;

  @override
  void initState() {
    super.initState();
    bossQuery.addListener(_onBossQueryChanged);
    characterId = widget.store.pendingSkillPageCharacterId ??
        (widget.store.selectedCharacterId.isNotEmpty
            ? widget.store.selectedCharacterId
            : 'all');
    maxRank = widget.store.pendingSkillPageMaxRank ?? 0;
    widget.store.pendingSkillPageCharacterId = null;
    widget.store.pendingSkillPageMaxRank = null;
  }

  void _onBossQueryChanged() => setState(() {});

  @override
  void dispose() {
    bossQuery.removeListener(_onBossQueryChanged);
    bossQuery.dispose();
    super.dispose();
  }

  List<CharacterData> get characters => widget.store.activeCharacters;

  String get effectiveCharacterId =>
      characters.any((character) => character.id == characterId)
          ? characterId
          : 'all';

  List<Boss> get filteredBosses {
    final query = bossQuery.text.trim().toLowerCase();
    final character = effectiveCharacterId == 'all' || characters.isEmpty
        ? null
        : characters.firstWhere((item) => item.id == effectiveCharacterId,
            orElse: () => characters.first);
    return widget.store.bosses.where((boss) {
      final rank =
          character == null ? 0 : widget.store.rankFor(character.id, boss);
      return (query.isEmpty || boss.name.toLowerCase().contains(query)) &&
          (maxRank == 0 || (rank > 0 && rank <= maxRank));
    }).toList();
  }

  Future<void> _setAllRanks() async {
    var selectedRank = 1;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                    title: const Text('设置全部技能重数'),
                    content: SizedBox(
                        width: 260,
                        child: _LabeledFilterDropdown<int>(
                            label: effectiveCharacterId == 'all'
                                ? '全部角色的全部技能'
                                : '当前角色的全部技能',
                            value: selectedRank,
                            values: List.generate(widget.store.maxSkillRank,
                                (index) => widget.store.maxSkillRank - index),
                            itemLabel: (value) => '$value 重',
                            width: 260,
                            onChanged: (value) => setDialogState(
                                () => selectedRank = value ?? selectedRank))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('取消')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('确认设置'))
                    ])));
    if (confirmed != true) return;
    widget.store.setAllSkillLevels(selectedRank,
        characterId:
            effectiveCharacterId == 'all' ? null : effectiveCharacterId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final character = effectiveCharacterId == 'all' || characters.isEmpty
        ? null
        : characters.firstWhere((item) => item.id == effectiveCharacterId,
            orElse: () => characters.first);
    return PageBody(
        title: '所有技能汇总',
        action: Text('${filteredBosses.length} 个首领',
            style: const TextStyle(color: teal, fontWeight: FontWeight.w600)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CharacterSwitcher(
              store: widget.store,
              onSelected: (value) => setState(() => characterId = value)),
          const SizedBox(height: 10),
          Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                  onPressed: characters.isEmpty ? null : _setAllRanks,
                  icon: const Icon(Icons.layers_outlined, size: 17),
                  label: Text(
                      characterId == 'all' ? '设置全部角色技能重数' : '设置当前角色全部技能重数'))),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final width = _filterItemWidth(constraints.maxWidth, 2);
            return Wrap(spacing: 10, runSpacing: 10, children: [
              _NameAutocomplete(
                  controller: bossQuery,
                  names: widget.store.bosses.map((boss) => boss.name).toList(),
                  width: width,
                  hint: '全部首领',
                  compactHint: '首领'),
              _FilterDropdown<int>(
                  value: maxRank,
                  values: [
                    0,
                    ...List.generate(widget.store.maxSkillRank,
                        (index) => widget.store.maxSkillRank - index)
                  ],
                  itemLabel: (value) => value == 0 ? '全部重数' : '$value 重及以下',
                  compactLabel: (value) => value == 0 ? '重数' : '$value 重以下',
                  width: width,
                  onChanged: (value) => setState(() => maxRank = value ?? 0))
            ]);
          }),
          const SizedBox(height: 10),
          Text(
              character == null
                  ? '切换角色后可按首领和技能重数筛选。'
                  : '当前角色：${character.name} · 符合条件的首领：${filteredBosses.length} 个',
              style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 14),
          if (filteredBosses.isEmpty)
            const CardShell(
                child: Text('没有符合条件的首领', style: TextStyle(color: muted)))
          else
            _AllSkillsTable(
                store: widget.store,
                bosses: filteredBosses,
                character: character,
                onChanged: () => setState(() {}))
        ]));
  }
}

class _AllSkillsTable extends StatefulWidget {
  const _AllSkillsTable(
      {required this.store,
      required this.bosses,
      required this.character,
      required this.onChanged});
  final SkillStore store;
  final List<Boss> bosses;
  final CharacterData? character;
  final VoidCallback onChanged;

  @override
  State<_AllSkillsTable> createState() => _AllSkillsTableState();
}

class _AllSkillsTableState extends State<_AllSkillsTable> {
  final Set<String> _expandedBossIds = {};
  bool? _strategyDescending;

  List<Boss> get _sortedBosses {
    final bosses = [...widget.bosses];
    final character = widget.character;
    if (character == null || _strategyDescending == null) return bosses;
    final originalOrder = <String, int>{
      for (var index = 0; index < bosses.length; index++)
        bosses[index].id: index
    };
    bosses.sort((left, right) {
      final leftProgress =
          bossCollectionProgress(widget.store, character, left);
      final rightProgress =
          bossCollectionProgress(widget.store, character, right);
      var comparison =
          leftProgress.strategyRank.compareTo(rightProgress.strategyRank);
      if (comparison == 0) {
        comparison = leftProgress.collectionRatio
            .compareTo(rightProgress.collectionRatio);
      }
      if (comparison == 0) {
        comparison = (originalOrder[left.id] ?? 0)
            .compareTo(originalOrder[right.id] ?? 0);
      }
      return _strategyDescending! ? -comparison : comparison;
    });
    return bosses;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
              width: math.max(560.0, constraints.maxWidth),
              child: Column(children: [
                Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: const Color(0xfff7f9f8),
                    child: Row(children: [
                      const Expanded(
                          flex: 4,
                          child: Text('首领 / 技能',
                              style: TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700))),
                      Expanded(
                          flex: 2,
                          child: InkWell(
                              onTap: widget.character == null
                                  ? null
                                  : () => setState(() => _strategyDescending =
                                      !(_strategyDescending ?? false)),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('攻略进度',
                                        style: TextStyle(
                                            color: muted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 2),
                                    Icon(
                                        _strategyDescending == null
                                            ? Icons.unfold_more
                                            : _strategyDescending!
                                                ? Icons.arrow_downward
                                                : Icons.arrow_upward,
                                        size: 13,
                                        color: muted)
                                  ]))),
                      const Expanded(
                          flex: 2,
                          child: Text('收集进度',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700))),
                      const Expanded(
                          flex: 2,
                          child: Text('精神',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700))),
                      const Expanded(
                          flex: 2,
                          child: Text('耐力',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)))
                    ])),
                for (final boss in _sortedBosses) ...[
                  Builder(builder: (context) {
                    final progress = widget.character == null
                        ? null
                        : bossCollectionProgress(
                            widget.store, widget.character!, boss);
                    final multiplier = progress == null
                        ? 0
                        : const [
                            0,
                            1,
                            2,
                            3,
                            4,
                            5,
                            7,
                            10,
                            15,
                            22.5,
                            33.75
                          ][progress.completedRank];
                    return InkWell(
                        onTap: () => setState(() {
                              if (!_expandedBossIds.add(boss.id)) {
                                _expandedBossIds.remove(boss.id);
                              }
                            }),
                        child: _AllSkillsTableRow(
                            name: bossNameForGender(
                                boss, widget.character?.gender ?? '女性'),
                            rank: progress?.strategyRank,
                            rankText: progress == null
                                ? null
                                : chineseRankLabel(progress.strategyRank),
                            collection: progress == null
                                ? '—'
                                : '${progress.collectedSkills}/${progress.totalSkills}',
                            spirit: progress == null
                                ? '—'
                                : '+${formatNumber(bossStatForGender(boss, widget.character!.gender, true) * multiplier)}',
                            stamina: progress == null
                                ? '—'
                                : '+${formatNumber(bossStatForGender(boss, widget.character!.gender, false) * multiplier)}',
                            bossRow: true,
                            expanded: _expandedBossIds.contains(boss.id)));
                  }),
                  if (_expandedBossIds.contains(boss.id))
                    for (final skill in boss.skills.where((skill) =>
                        widget.character == null ||
                        skillAppliesToGender(skill, widget.character!.gender)))
                      InkWell(
                          onTap: () async {
                            await showSkillDialog(context, widget.store, skill);
                            widget.onChanged();
                          },
                          child: _AllSkillsTableRow(
                              name: skillNameForGender(
                                  skill, widget.character?.gender ?? '女性'),
                              nameColor: skill.tradable ? purple : ink,
                              rank: widget.character == null
                                  ? null
                                  : widget.store
                                      .level(widget.character!.id, skill.id),
                              collection: ''))
                ]
              ]))));
}

class _AllSkillsTableRow extends StatelessWidget {
  const _AllSkillsTableRow(
      {required this.name,
      required this.rank,
      this.rankText,
      this.collection = '',
      this.spirit,
      this.stamina,
      this.bossRow = false,
      this.expanded = false,
      this.nameColor = ink});
  final String name;
  final int? rank;
  final String? rankText;
  final String collection;
  final String? spirit;
  final String? stamina;
  final bool bossRow;
  final bool expanded;
  final Color nameColor;

  @override
  Widget build(BuildContext context) => Container(
      constraints: BoxConstraints(minHeight: bossRow ? 44 : 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: bossRow ? const Color(0xfffbfcfb) : Colors.white,
          border: const Border(top: BorderSide(color: line))),
      child: Row(children: [
        Expanded(
            flex: 4,
            child: Padding(
                padding: EdgeInsets.only(left: bossRow ? 0 : 16),
                child: Row(children: [
                  if (bossRow) ...[
                    Icon(
                        expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 18,
                        color: muted),
                    const SizedBox(width: 4)
                  ],
                  Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: nameColor,
                              fontSize: bossRow ? 13 : 12,
                              fontWeight:
                                  bossRow ? FontWeight.w800 : FontWeight.w500)))
                ]))),
        Expanded(
            flex: 2,
            child: Text(
                rankText ??
                    (rank == null
                        ? '—'
                        : rank == 0
                            ? (bossRow ? '未完成' : '未学')
                            : '$rank 重'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: bossRow ? teal : ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700))),
        Expanded(
            flex: 2,
            child: Text(collection,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: bossRow ? ink : muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700))),
        Expanded(
            flex: 2,
            child: Text(spirit ?? '',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: teal, fontSize: 12, fontWeight: FontWeight.w700))),
        Expanded(
            flex: 2,
            child: Text(stamina ?? '',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Color(0xff69a991),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)))
      ]));
}

class BossPage extends StatelessWidget {
  const BossPage({required this.store, super.key});
  final SkillStore store;
  @override
  Widget build(BuildContext context) => PageBody(
      title: '首领技能管理',
      action: TextButton.icon(
          onPressed: () => store.setPage(4),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('设置')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CardShell(
            child: Row(children: [
          const Icon(Icons.info_outline, color: teal),
          const SizedBox(width: 10),
          const Expanded(
              child: Text('拖动首领左侧把手可调整显示顺序；技能修改会同步到所有已有角色，增量导入只补充未添加内容。',
                  style: TextStyle(color: muted, fontSize: 12))),
          Text('${store.bosses.length} 个首领',
              style: const TextStyle(color: teal, fontWeight: FontWeight.w800))
        ])),
        const SizedBox(height: 12),
        Wrap(spacing: 9, runSpacing: 9, children: [
          FilledButton.icon(
              onPressed: () => showBossDialog(context, store),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('录入新首领')),
          OutlinedButton.icon(
              onPressed: () => _exportBosses(context),
              icon: const Icon(Icons.file_upload_outlined, size: 17),
              label: const Text('导出全部')),
          OutlinedButton.icon(
              onPressed: () => _importBosses(context),
              icon: const Icon(Icons.file_download_outlined, size: 17),
              label: const Text('增量导入')),
          OutlinedButton.icon(
              onPressed: () => _setMaxRank(context),
              icon: const Icon(Icons.vertical_align_top, size: 17),
              label: Text('最高重 ${store.maxSkillRank} 重')),
          OutlinedButton.icon(
              onPressed: store.bossCatalogCheckBusy
                  ? null
                  : () => _checkCatalog(context),
              icon: store.bossCatalogCheckBusy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 17),
              label: const Text('检查数据更新'))
        ]),
        const SizedBox(height: 14),
        ReorderableListView.builder(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: store.bosses.length,
            onReorder: store.reorderBoss,
            itemBuilder: (context, index) {
              final boss = store.bosses[index];
              return Padding(
                  key: ValueKey(boss.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CardShell(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Tooltip(
                                      message: '拖动调整显示顺序',
                                      child: Icon(Icons.drag_indicator,
                                          color: muted)))),
                          Expanded(
                              child: Text(
                                  boss.name == '杜姬欣' || boss.name == '杜姬欣/钱宗龙'
                                      ? '杜姬欣/钱宗龙'
                                      : boss.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: ink))),
                          StatPill(label: boss.type),
                          const SizedBox(width: 7),
                          StatPill(label: '精 +${formatNumber(boss.spirit)}'),
                          const SizedBox(width: 7),
                          StatPill(label: '耐 +${formatNumber(boss.stamina)}'),
                          const SizedBox(width: 8),
                          IconButton(
                              tooltip: '编辑首领',
                              onPressed: () =>
                                  showBossDialog(context, store, boss: boss),
                              icon:
                                  const Icon(Icons.edit_outlined, color: teal)),
                          IconButton(
                              tooltip: '删除首领',
                              onPressed: () =>
                                  showDeleteBossDialog(context, store, boss),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent)),
                          IconButton(
                              tooltip: '新增技能',
                              onPressed: () =>
                                  showAddSkillDialog(context, store, boss),
                              icon: const Icon(Icons.add_circle_outline,
                                  color: teal))
                        ]),
                        const SizedBox(height: 12),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: boss.skills
                                .map((skill) => BossSkillTile(
                                    skill: skill,
                                    onTap: () => showSkillDialog(
                                        context, store, skill,
                                        allowNameEdit: true)))
                                .toList())
                      ])));
            })
      ]));

  Future<void> _setMaxRank(BuildContext context) async {
    final value = await showDialog<int>(
        context: context,
        builder: (_) => _MaxSkillRankDialog(initialValue: store.maxSkillRank));
    if (value != null) store.setMaxSkillRank(value);
  }

  Future<void> _exportBosses(BuildContext context) async {
    final exported = await store.exportBosses();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exported ? '已导出全部首领和技能' : '已取消导出')));
  }

  Future<void> _importBosses(BuildContext context) async {
    try {
      final result = await store.importBosses();
      if (!context.mounted || result == null) return;
      final message = result.bossesAdded == 0 && result.skillsAdded == 0
          ? '没有需要新增的首领或技能'
          : '已新增 ${result.bossesAdded} 个首领、${result.skillsAdded} 个技能';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导入失败：$error')));
    }
  }

  Future<void> _checkCatalog(BuildContext context) async {
    final found = await store.checkForBossCatalogUpdate(manual: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(store.bossCatalogCheckError ??
            (found
                ? '发现新的首领技能数据'
                : '当前已是最新首领技能数据（版本 ${store.bossCatalogVersion}）'))));
  }
}

class _MaxSkillRankDialog extends StatefulWidget {
  const _MaxSkillRankDialog({required this.initialValue});
  final int initialValue;

  @override
  State<_MaxSkillRankDialog> createState() => _MaxSkillRankDialogState();
}

class _MaxSkillRankDialogState extends State<_MaxSkillRankDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: '${widget.initialValue}');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('设置技能最高重'),
          content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: '最高重', helperText: '将影响全部重数筛选、统计和显示')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            FilledButton(
                onPressed: () {
                  final rank = int.tryParse(controller.text);
                  if (rank != null && rank > 0) Navigator.pop(context, rank);
                },
                child: const Text('保存'))
          ]);
}

class BossSkillTile extends StatelessWidget {
  const BossSkillTile({required this.skill, required this.onTap, super.key});
  final Skill skill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: skill.tradable
                  ? const Color(0xfff4edfb)
                  : const Color(0xfff7f9f8),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: skill.tradable ? const Color(0xffdec9f2) : line)),
          child: Text(managementSkillName(skill),
              style: TextStyle(
                  color: skill.tradable ? purpleColor : ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600))));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.store, super.key});
  final SkillStore store;

  @override
  Widget build(BuildContext context) => PageBody(
      title: '设置',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SettingCard(
            icon: store.themeMode == ThemeMode.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            title: '外观模式',
            subtitle: '浅色、深色，或自动跟随系统设置',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(themeModeLabel(store.themeMode),
                  style: const TextStyle(color: muted, fontSize: 12)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: muted, size: 20)
            ]),
            onTap: () => _selectThemeMode(context)),
        const SizedBox(height: 10),
        _SettingCard(
            icon: Icons.folder_open_outlined,
            title: '本地数据位置',
            subtitle: store.localDataLocationLabel(),
            trailing: Text(store.localDataMigrationPending ? '待重启' : '修改',
                style: const TextStyle(color: teal, fontSize: 12)),
            onTap: () => _selectLocalDataPath(context)),
        const SizedBox(height: 10),
        _SettingCard(
            icon: Icons.view_sidebar_outlined,
            title: '导航栏配置',
            subtitle: '选择左侧显示的页面，并拖动调整顺序',
            onTap: () => _configureNavigation(context)),
        const SizedBox(height: 10),
        _SettingCard(
            icon: Icons.cloud_sync_outlined,
            title: '同步与备份',
            subtitle: store.syncConfig?.isValid == true
                ? store.syncMessage ?? 'WebDAV 已配置 · 点击进入管理'
                : '本地备份、WebDAV 同步与远程恢复',
            onTap: () => store.setPage(7)),
        const SizedBox(height: 10),
        _SettingCard(
            icon: Icons.groups_outlined,
            title: '角色管理',
            subtitle: '${store.activeCharacters.length} 个角色 · 添加、编辑或删除角色',
            onTap: () => store.setPage(5)),
        const SizedBox(height: 10),
        _SettingCard(
            icon: Icons.edit_note_outlined,
            title: '首领管理',
            subtitle: '${store.bosses.length} 个首领 · 管理首领和所属技能',
            onTap: () => store.setPage(6)),
        const SizedBox(height: 10),
        const _UpdateSettingCard(),
        const SizedBox(height: 16),
        const AppVersionText()
      ]));

  Future<void> _selectLocalDataPath(BuildContext context) async {
    try {
      final currentPath = store.localDataPath;
      final selected = await FilePicker.saveFile(
          dialogTitle: '选择本地数据文件位置',
          initialDirectory:
              currentPath == null ? null : File(currentPath).parent.path,
          fileName: 'baizhan-skill-data.json',
          type: FileType.custom,
          allowedExtensions: ['json']);
      if (selected == null || selected.trim().isEmpty || !context.mounted) {
        return;
      }
      if (selected == currentPath && !store.localDataMigrationPending) return;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                  title: const Text('重启并迁移本地数据'),
                  content: Text('确认后应用会立即重启，并把当前数据迁移到：\n$selected'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('重启并迁移'))
                  ]));
      if (confirmed != true) return;
      await store.scheduleLocalDataMigration(selected);
      await store.restartForLocalDataMigration();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择位置失败：$error')));
      }
    }
  }

  Future<void> _configureNavigation(BuildContext context) async {
    final order = [...store.navigationOrder];
    final visible = {...store.navigationVisible};
    final labels = {...store.navigationLabels};
    final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                    title: const Text('导航栏配置'),
                    content: SizedBox(
                        width: 420,
                        height: 340,
                        child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: order.length,
                            onReorder: (oldIndex, newIndex) {
                              setDialogState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = order.removeAt(oldIndex);
                                order.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final option = navigationPageOptions.firstWhere(
                                  (item) => item.id == order[index]);
                              return ListTile(
                                  key: ValueKey(option.id),
                                  contentPadding: EdgeInsets.zero,
                                  leading: Checkbox(
                                      value: visible.contains(option.id),
                                      onChanged: (value) => setDialogState(() {
                                            if (value == true) {
                                              visible.add(option.id);
                                            } else {
                                              visible.remove(option.id);
                                            }
                                          })),
                                  title:
                                      Text(labels[option.id] ?? option.label),
                                  subtitle: labels.containsKey(option.id)
                                      ? Text('原名称：${option.label}',
                                          style: const TextStyle(
                                              color: muted, fontSize: 11))
                                      : null,
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            tooltip: '修改名称',
                                            onPressed: () async {
                                              final renamed =
                                                  await _renameNavigationItem(
                                                      context,
                                                      labels[option.id] ??
                                                          option.label);
                                              if (renamed != null) {
                                                setDialogState(() {
                                                  if (renamed == option.label) {
                                                    labels.remove(option.id);
                                                  } else {
                                                    labels[option.id] = renamed;
                                                  }
                                                });
                                              }
                                            },
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18)),
                                        ReorderableDragStartListener(
                                            index: index,
                                            child: const Padding(
                                                padding: EdgeInsets.all(10),
                                                child: Icon(
                                                    Icons.drag_indicator,
                                                    color: muted)))
                                      ]));
                            })),
                    actions: [
                      TextButton(
                          onPressed: () {
                            setDialogState(() {
                              order
                                ..clear()
                                ..addAll(defaultNavigationOrder);
                              visible
                                ..clear()
                                ..addAll(defaultNavigationVisible);
                              labels.clear();
                            });
                          },
                          child: const Text('恢复默认')),
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('取消')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('保存'))
                    ])));
    if (saved == true) {
      store.setNavigationConfiguration(order, visible, labels);
    }
  }

  Future<String?> _renameNavigationItem(
      BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final value = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('修改导航名称'),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 8,
                    decoration: const InputDecoration(labelText: '显示名称')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () {
                        final name = controller.text.trim();
                        if (name.isNotEmpty) Navigator.pop(dialogContext, name);
                      },
                      child: const Text('确定'))
                ]));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    return value;
  }

  Future<void> _selectThemeMode(BuildContext context) async {
    final selected = await showDialog<ThemeMode>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
            title: const Text('外观模式'),
            children: ThemeMode.values
                .map((mode) => RadioListTile<ThemeMode>(
                    value: mode,
                    groupValue: store.themeMode,
                    title: Text(themeModeLabel(mode)),
                    onChanged: (value) => Navigator.pop(dialogContext, value)))
                .toList()));
    if (selected != null) await store.setThemeMode(selected);
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(icon, color: teal, size: 21),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          color: ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(color: muted, fontSize: 12))
                ])),
            trailing ?? const Icon(Icons.chevron_right, color: muted, size: 20)
          ])));
}

class _UpdateSettingCard extends StatefulWidget {
  const _UpdateSettingCard();

  @override
  State<_UpdateSettingCard> createState() => _UpdateSettingCardState();
}

class _UpdateSettingCardState extends State<_UpdateSettingCard> {
  final UpdateService _updateService = UpdateService();
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  bool _checking = false;

  @override
  Widget build(BuildContext context) => _SettingCard(
      icon: Icons.system_update_outlined,
      title: '检查更新',
      subtitle: _checking ? '正在查询 GitHub Release…' : '查询新版本并下载当前平台安装包',
      trailing: _checking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : null,
      onTap: _checking ? () {} : _checkForUpdates);

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    try {
      final results = await Future.wait([
        _packageInfo,
        _updateService.fetchLatestRelease(),
      ]);
      final packageInfo = results[0] as PackageInfo;
      final release = results[1] as AppRelease;
      if (!mounted) return;
      setState(() => _checking = false);
      if (!isVersionNewer(release.version, packageInfo.version)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('当前已是最新版本 v${packageInfo.version}')));
        return;
      }
      await _showUpdateDialog(release, packageInfo.version);
    } catch (error) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('检查更新失败：$error')));
    }
  }

  Future<void> _showUpdateDialog(
      AppRelease release, String currentVersion) async {
    final download = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: Text('发现新版本 v${release.version}'),
                content: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text(
                              '当前版本 v$currentVersion · 最新版本 v${release.version}',
                              style:
                                  const TextStyle(color: muted, fontSize: 12)),
                          if (release.notes.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Text('更新内容',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 7),
                            SelectableText(release.notes.trim(),
                                style:
                                    const TextStyle(fontSize: 12, height: 1.5))
                          ]
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('稍后')),
                  FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('下载更新'))
                ]));
    if (download != true) return;
    final opened = await launchUrl(release.platformDownloadUri,
        mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开下载地址')));
    }
  }
}

class SyncBackupPage extends StatefulWidget {
  const SyncBackupPage({required this.store, super.key});
  final SkillStore store;

  @override
  State<SyncBackupPage> createState() => _SyncBackupPageState();
}

class _SyncBackupPageState extends State<SyncBackupPage> {
  SkillStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    if (store.syncConfig?.isValid == true && store.remoteBackups.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) store.loadRemoteBackups();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
      title: '同步与备份',
      action: TextButton.icon(
          onPressed: () => store.setPage(4),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('设置')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CardShell(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.save_outlined, color: teal),
            SizedBox(width: 9),
            Text('本地备份',
                style: TextStyle(
                    color: ink, fontSize: 16, fontWeight: FontWeight.w600))
          ]),
          const SizedBox(height: 10),
          const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('本地自动保存', style: TextStyle(color: ink, fontSize: 13)),
              subtitle: Text('每次修改会自动保存到本机，无需手动操作。',
                  style: TextStyle(color: muted, fontSize: 12)),
              trailing: Icon(Icons.check_circle, color: teal)),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(
                onPressed: () => _export(context),
                icon: const Icon(Icons.file_upload_outlined, size: 17),
                label: const Text('导出本地备份')),
            OutlinedButton.icon(
                onPressed: () => _import(context),
                icon: const Icon(Icons.file_download_outlined, size: 17),
                label: const Text('导入本地备份'))
          ])
        ])),
        const SizedBox(height: 16),
        CardShell(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.cloud_outlined, color: teal),
            SizedBox(width: 9),
            Text('WebDAV 云同步',
                style: TextStyle(
                    color: ink, fontSize: 16, fontWeight: FontWeight.w600))
          ]),
          const SizedBox(height: 10),
          if (store.newerRemoteBackup != null) ...[
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xfffff4e5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffffd59a))),
                child: Row(children: [
                  const Icon(Icons.cloud_download_outlined,
                      color: gold, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                      child: Text('发现较新的云端备份：${store.newerRemoteBackup!.name}',
                          style: const TextStyle(
                              color: ink, fontWeight: FontWeight.w600))),
                  TextButton(
                      onPressed: store.restoreBusy
                          ? null
                          : () => confirmRemoteBackupRestore(
                              context, store, store.newerRemoteBackup!),
                      child: const Text('恢复'))
                ])),
            const SizedBox(height: 10)
          ],
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(store.syncConfig?.isValid == true ? '已配置' : '尚未配置',
                  style: const TextStyle(color: ink, fontSize: 13)),
              subtitle: Text(
                  store.syncConfig?.isValid == true
                      ? '${store.syncConfig!.url}\n${store.syncMessage ?? '可在多个设备间同步数据'}'
                      : '配置 WebDAV 地址、账号、远程路径和自动同步间隔',
                  style: const TextStyle(color: muted, fontSize: 12)),
              trailing: TextButton(
                  onPressed: () => _configureSync(context),
                  child: const Text('配置'))),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(
                onPressed: store.syncBusy ? null : () => _syncNow(context),
                icon: const Icon(Icons.sync, size: 17),
                label: Text(store.syncBusy ? '同步中…' : '立即同步')),
            OutlinedButton.icon(
                onPressed:
                    store.backupCheckBusy ? null : () => _loadBackups(context),
                icon: const Icon(Icons.history, size: 17),
                label: Text(store.backupCheckBusy ? '读取中…' : '远程备份'))
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(children: [
                const Expanded(
                    child: Text('远程备份列表',
                        style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600))),
                IconButton(
                    tooltip: '刷新远程备份',
                    onPressed: store.backupCheckBusy
                        ? null
                        : () => _loadBackups(context),
                    icon: store.backupCheckBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 19))
              ])),
          if (store.remoteBackups.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: Text(
                        store.syncConfig?.isValid == true
                            ? '暂无远程备份，点击刷新重新读取'
                            : '配置并测试 WebDAV 后，这里会显示远程备份',
                        style: const TextStyle(color: muted, fontSize: 12))))
          else
            ...store.remoteBackups.asMap().entries.map((entry) =>
                _RemoteBackupListTile(
                    backup: entry.value,
                    isLatest: entry.key == 0,
                    isCurrent:
                        entry.value.path == store.currentRemoteBackupPath,
                    onRestore: store.syncBusy || store.restoreBusy
                        ? null
                        : () => confirmRemoteBackupRestore(
                            context, store, entry.value)))
        ]))
      ]));

  Future<void> _export(BuildContext context) async {
    final ok = await store.exportBackup();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ok ? '备份已导出' : '已取消导出')));
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final ok = await store.importBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ok ? '备份已恢复' : '已取消恢复')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('备份文件格式无法读取')));
      }
    }
  }

  Future<void> _syncNow(BuildContext context) async {
    await store.syncNow();
    if (context.mounted && store.syncMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(store.syncMessage!)));
    }
  }

  Future<void> _loadBackups(BuildContext context) async {
    await store.loadRemoteBackups();
    if (context.mounted && store.syncMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(store.syncMessage!)));
    }
  }

  Future<void> _configureSync(BuildContext context) async {
    final config = store.syncConfig;
    final url = TextEditingController(
        text: config?.url ?? 'https://dav.jianguoyun.com/dav/');
    final username = TextEditingController(text: config?.username ?? '');
    final password = TextEditingController(text: config?.password ?? '');
    final remotePath = TextEditingController(
        text: config?.remotePath ?? defaultWebDavBackupPath);
    var autoMinutes = config?.autoSyncMinutes ?? 0;
    var testing = false;
    String? testResult;
    SyncConfig draftConfig() => SyncConfig(
        url: url.text,
        username: username.text,
        password: password.text,
        remotePath: remotePath.text,
        autoSyncMinutes: autoMinutes);
    final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  title: const Text('WebDAV 同步配置'),
                  content: SizedBox(
                      width: 480,
                      child: SingleChildScrollView(
                          child: Column(children: [
                        TextField(
                            controller: url,
                            decoration:
                                const InputDecoration(labelText: 'WebDAV 地址')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: username,
                            decoration: const InputDecoration(labelText: '账号')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: password,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: '密码 / 应用密码')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: remotePath,
                            decoration:
                                const InputDecoration(labelText: '远程备份路径')),
                        const SizedBox(height: 10),
                        _LabeledFilterDropdown<int>(
                            label: '自动同步间隔',
                            value: autoMinutes,
                            values: const [0, 5, 15, 30, 60],
                            width: 480,
                            itemLabel: (value) =>
                                value == 0 ? '关闭' : '每 $value 分钟',
                            onChanged: (value) =>
                                setState(() => autoMinutes = value ?? 0)),
                        if (testResult != null) ...[
                          const SizedBox(height: 10),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(testResult!,
                                  style: TextStyle(
                                      color: testResult == '连接成功'
                                          ? teal
                                          : Theme.of(context).colorScheme.error,
                                      fontSize: 12)))
                        ]
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('取消')),
                    OutlinedButton.icon(
                        onPressed: testing
                            ? null
                            : () async {
                                setState(() {
                                  testing = true;
                                  testResult = null;
                                });
                                final ok = await store
                                    .testSyncConnection(draftConfig());
                                if (!dialogContext.mounted) return;
                                setState(() {
                                  testing = false;
                                  testResult = store.syncMessage ??
                                      (ok ? '连接成功' : '连接失败');
                                });
                              },
                        icon: testing
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.wifi_tethering, size: 17),
                        label: Text(testing ? '测试中…' : '测试连接')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('保存'))
                  ],
                )));
    if (saved == true) {
      await store.saveSyncConfig(draftConfig());
      if (store.syncConfig?.isValid == true) await store.loadRemoteBackups();
    }
    url.dispose();
    username.dispose();
    password.dispose();
    remotePath.dispose();
  }
}

class _RemoteBackupListTile extends StatelessWidget {
  const _RemoteBackupListTile({
    required this.backup,
    required this.isLatest,
    required this.isCurrent,
    required this.onRestore,
  });

  final RemoteBackup backup;
  final bool isLatest;
  final bool isCurrent;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.backup_outlined, size: 18, color: muted),
      title: Row(children: [
        Expanded(
            child: Text(backup.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))),
        if (isCurrent) ...[
          const SizedBox(width: 6),
          const _BackupVersionBadge(label: '当前版本', emphasized: true)
        ],
        if (isLatest) ...[
          const SizedBox(width: 6),
          const _BackupVersionBadge(label: '最新版本')
        ]
      ]),
      subtitle: Text(backup.modifiedAt?.toLocal().toString() ?? '时间未知',
          style: const TextStyle(fontSize: 11, color: muted)),
      trailing: TextButton(onPressed: onRestore, child: const Text('恢复')));
}

class _BackupVersionBadge extends StatelessWidget {
  const _BackupVersionBadge({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: emphasized
                ? scheme.primaryContainer
                : scheme.surfaceContainerLow,
            border: Border.all(
                color: emphasized ? scheme.primary : scheme.outlineVariant),
            borderRadius: BorderRadius.circular(5)),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: emphasized
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant)));
  }
}

Future<void> confirmRemoteBackupRestore(
    BuildContext context, SkillStore store, RemoteBackup backup) async {
  final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
            title: const Text('恢复远程备份'),
            content: Text(
                '本地角色、首领、技能和重数将被“${backup.name}”替换。恢复不会自动上传；如需保留当前本地数据，请先手动同步或导出备份。'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('恢复'))
            ],
          ));
  if (confirmed != true) return;
  final restored = await store.restoreRemoteBackup(backup);
  if (context.mounted && store.syncMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(store.syncMessage ?? (restored ? '已恢复' : '恢复失败'))));
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard(
      {required this.label,
      required this.value,
      required this.accent,
      required this.icon,
      this.width,
      this.height,
      this.onTap,
      super.key});
  final String label, value;
  final Color accent;
  final IconData icon;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: width ?? 180,
      height: height,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: CardShell(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(icon, color: accent, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(label,
                              maxLines: 2,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: muted, fontSize: 12, height: 1.15)))
                    ]),
                    const SizedBox(height: 14),
                    Text(value,
                        style: TextStyle(
                            color: accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w800))
                  ]))));
}

class CardShell extends StatelessWidget {
  const CardShell(
      {required this.child,
      super.key,
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: line)),
      child: child);
}

class InfoItem extends StatelessWidget {
  const InfoItem({required this.label, required this.value, super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 116,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w800))
      ]));
}

class RankBadge extends StatelessWidget {
  const RankBadge({required this.rank, this.plain = false, super.key});
  final int rank;
  final bool plain;
  @override
  Widget build(BuildContext context) {
    final color = rank >= 10
        ? teal
        : rank >= 9
            ? purple
            : rank > 0
                ? gold
                : muted;
    if (plain) {
      return Text(rank == 0 ? '未学' : '$rank 重',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12));
    }
    return Container(
        width: 58,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(.11),
            borderRadius: BorderRadius.circular(7)),
        child: Text(rank == 0 ? '未学' : '$rank重',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 12)));
  }
}

class StatPill extends StatelessWidget {
  const StatPill({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xfff7f9f8),
          borderRadius: BorderRadius.circular(7)),
      child: Text(label,
          style: const TextStyle(
              color: muted, fontSize: 11, fontWeight: FontWeight.w700)));
}

class SkillChip extends StatelessWidget {
  const SkillChip(
      {required this.name,
      required this.onTap,
      this.purple = false,
      super.key});
  final String name;
  final VoidCallback onTap;
  final bool purple;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: purple ? const Color(0xfff4edfb) : const Color(0xfff7f9f8),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: purple ? const Color(0xffdec9f2) : line)),
          child: Text(name,
              style: TextStyle(
                  color: purple ? purpleColor : ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600))));
}

const purpleColor = Color(0xff8d54c7);
String formatNumber(num value) => value
    .round()
    .toString()
    .replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+$)'), (match) => ',');

Future<void> showSkillDialog(
    BuildContext context, SkillStore store, Skill skill,
    {bool allowNameEdit = false}) async {
  final nameController = TextEditingController(text: skill.name);
  final current = store.level(store.selectedCharacterId, skill.id);
  var selectedLevel = current;
  var tradable = skill.tradable;
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                  title: Text(allowNameEdit ? '编辑技能' : skill.name),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (allowNameEdit) ...[
                          TextField(
                              controller: nameController,
                              decoration:
                                  const InputDecoration(labelText: '技能名称')),
                          const SizedBox(height: 12)
                        ],
                        Text(store.bossForSkill(skill.id)?.name ?? '技能',
                            style: const TextStyle(color: muted, fontSize: 12)),
                        const SizedBox(height: 14),
                        Row(children: [
                          Text(allowNameEdit ? '统一重数' : '当前重数',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w400)),
                          const Spacer(),
                          _FilterDropdown<int>(
                              value: selectedLevel,
                              values: [
                                ...List.generate(store.maxSkillRank,
                                    (index) => store.maxSkillRank - index),
                                0
                              ],
                              itemLabel: (value) =>
                                  value == 0 ? '未学习' : '$value 重',
                              width: 112,
                              onChanged: (value) => setState(
                                  () => selectedLevel = value ?? selectedLevel))
                        ]),
                        if (allowNameEdit) ...[
                          const SizedBox(height: 10),
                          CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: tradable,
                              title: const Text('可交易技能',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400)),
                              subtitle: const Text('紫色显示并进入可交易技能统计',
                                  style: TextStyle(color: muted, fontSize: 11)),
                              onChanged: (value) =>
                                  setState(() => tradable = value ?? false)),
                        ] else ...[
                          const SizedBox(height: 12),
                          const Text('名称、可交易状态和删除请前往首领技能管理。',
                              style: TextStyle(color: muted, fontSize: 11))
                        ],
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                    if (allowNameEdit)
                      TextButton(
                          onPressed: () {
                            final boss = store.bossForSkill(skill.id);
                            if (boss != null) {
                              store.removeSkillFromBoss(boss, skill);
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('删除技能',
                              style: TextStyle(color: Colors.redAccent))),
                    FilledButton(
                        onPressed: () {
                          if (allowNameEdit) {
                            store.renameSkill(skill, nameController.text);
                            store.setSkillTradable(skill, tradable);
                            store.setLevelForAllCharacters(
                                skill.id, selectedLevel);
                          } else {
                            store.setLevel(skill.id, selectedLevel);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('保存'))
                  ])));
  nameController.dispose();
}

Future<void> showImportantDialog(BuildContext context, SkillStore store) async {
  final skillNames = store.bosses
      .expand((boss) => boss.skills)
      .map((skill) => skill.name)
      .toSet()
      .toList()
    ..sort();
  final controller = TextEditingController();
  String? errorText;
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                  title: const Text('添加重要技能'),
                  content: skillNames.isEmpty
                      ? const Text('暂无已有技能，请先在首领管理中录入技能。')
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          _NameAutocomplete(
                              controller: controller,
                              names: skillNames,
                              width: math.min(
                                  300.0, MediaQuery.sizeOf(context).width - 96),
                              hint: '从已有技能中搜索技能',
                              compactHint: '搜索已有技能'),
                          if (errorText != null) ...[
                            const SizedBox(height: 8),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(errorText!,
                                    style: const TextStyle(
                                        color: Colors.redAccent, fontSize: 12)))
                          ]
                        ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: skillNames.isEmpty
                            ? null
                            : () {
                                final name = controller.text.trim();
                                if (!skillNames.contains(name)) {
                                  setState(() => errorText = '请选择已有技能');
                                  return;
                                }
                                if (store.importantSkills.contains(name)) {
                                  setState(() => errorText = '该技能已经添加');
                                  return;
                                }
                                store.addImportantSkill(name);
                                Navigator.pop(context);
                              },
                        child: const Text('添加'))
                  ])));
  controller.dispose();
}

Future<void> showRemoveImportantSkillDialog(
    BuildContext context, SkillStore store, String skillName) async {
  final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              title: const Text('移除重要技能'),
              content: Text('确定将「$skillName」从重要技能中移除吗？\n不会删除首领技能或角色重数。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('移除'))
              ]));
  if (confirmed == true) store.removeImportantSkill(skillName);
}

Future<void> showAddSkillDialog(
    BuildContext context, SkillStore store, Boss boss) async {
  final controller = TextEditingController();
  var tradable = false;
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                  title: Text('给 ${boss.name} 添加技能'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: '技能名称')),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: tradable,
                        title: const Text('可交易技能'),
                        subtitle: const Text('默认关闭，开启后会进入可交易技能统计'),
                        onChanged: (value) =>
                            setState(() => tradable = value ?? false))
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: () {
                          store.addSkillToBoss(boss, controller.text,
                              tradable: tradable);
                          Navigator.pop(context);
                        },
                        child: const Text('保存'))
                  ])));
}

Future<void> showBossDialog(BuildContext context, SkillStore store,
    {Boss? boss}) async {
  await showDialog<void>(
      context: context,
      builder: (context) => _BossEditorDialog(store: store, boss: boss));
}

class _BossEditorDialog extends StatefulWidget {
  const _BossEditorDialog({required this.store, this.boss});
  final SkillStore store;
  final Boss? boss;

  @override
  State<_BossEditorDialog> createState() => _BossEditorDialogState();
}

class _BossEditorDialogState extends State<_BossEditorDialog> {
  late final TextEditingController name;
  late final TextEditingController spirit;
  late final TextEditingController stamina;
  late final List<SkillDraftController> skillDrafts;
  late String bossType;
  String? attributeError;

  @override
  void initState() {
    super.initState();
    final boss = widget.boss;
    name = TextEditingController(text: boss?.name ?? '');
    bossType = boss?.type ?? '普通';
    spirit = TextEditingController(
        text: boss == null ? '0' : boss.spirit.round().toString());
    stamina = TextEditingController(
        text: boss == null ? '0' : boss.stamina.round().toString());
    skillDrafts = boss == null
        ? [SkillDraftController()]
        : boss.skills
            .map((skill) =>
                SkillDraftController(skill.name)..tradable = skill.tradable)
            .toList();
  }

  @override
  void dispose() {
    name.dispose();
    spirit.dispose();
    stamina.dispose();
    for (final draft in skillDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _save() {
    final boss = widget.boss;
    final nextName = name.text.trim();
    final nextSpirit = int.tryParse(spirit.text);
    final nextStamina = int.tryParse(stamina.text);
    if (nextSpirit == null ||
        nextStamina == null ||
        nextSpirit + nextStamina != 800) {
      setState(() => attributeError = '精神提升与耐力提升相加必须等于 800');
      return;
    }
    if (boss == null) {
      widget.store.addBoss(
          name: nextName,
          type: bossType,
          spirit: nextSpirit.toDouble(),
          stamina: nextStamina.toDouble(),
          skillInputs: skillDrafts
              .map((draft) => SkillInputData(
                  name: draft.controller.text, tradable: draft.tradable))
              .toList());
    } else {
      widget.store.updateBoss(boss,
          name: nextName,
          type: bossType,
          spirit: nextSpirit.toDouble(),
          stamina: nextStamina.toDouble());
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final boss = widget.boss;
    return AlertDialog(
        title: Text(boss == null ? '录入新首领' : '编辑首领'),
        content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
                child: Column(children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: '首领名称')),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('首领类型',
                            style: TextStyle(color: muted, fontSize: 12)),
                        const SizedBox(height: 5),
                        _FilterDropdown<String>(
                            value: bossType,
                            values: bossTypeOptions,
                            itemLabel: (value) => value,
                            width: 160,
                            onChanged: (value) =>
                                setState(() => bossType = value ?? bossType))
                      ])),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: spirit,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) => setState(() => attributeError = null),
                        decoration: const InputDecoration(labelText: '精神提升'))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: stamina,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) => setState(() => attributeError = null),
                        decoration: const InputDecoration(labelText: '耐力提升')))
              ]),
              if (attributeError != null) ...[
                const SizedBox(height: 7),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(attributeError!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)))
              ],
              if (boss == null) ...[
                const SizedBox(height: 17),
                Row(children: [
                  const Expanded(
                      child: Text('相关技能',
                          style: TextStyle(
                              color: ink, fontWeight: FontWeight.w800))),
                  TextButton.icon(
                      onPressed: () => setState(
                          () => skillDrafts.add(SkillDraftController())),
                      icon: const Icon(Icons.add, size: 17),
                      label: const Text('添加一条'))
                ]),
                const SizedBox(height: 4),
                ...skillDrafts.asMap().entries.map((entry) {
                  final draft = entry.value;
                  return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(children: [
                        Expanded(
                            child: TextField(
                                controller: draft.controller,
                                decoration: InputDecoration(
                                    labelText: '技能名称 ${entry.key + 1}'))),
                        const SizedBox(width: 6),
                        Tooltip(
                            message: '默认不可交易',
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Checkbox(
                                  value: draft.tradable,
                                  activeColor: purple,
                                  onChanged: (value) => setState(
                                      () => draft.tradable = value ?? false)),
                              const Text('可交易', style: TextStyle(fontSize: 12))
                            ])),
                        IconButton(
                            tooltip: '删除这一条',
                            onPressed: skillDrafts.length == 1
                                ? null
                                : () => setState(() {
                                      final removed =
                                          skillDrafts.removeAt(entry.key);
                                      removed.dispose();
                                    }),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: muted))
                      ]));
                })
              ] else
                const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('技能可在首领卡片中点击后编辑、删除或新增。',
                            style: TextStyle(color: muted, fontSize: 12))))
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
              onPressed: _save, child: Text(boss == null ? '保存并同步角色' : '保存首领'))
        ]);
  }
}

Future<void> showDeleteBossDialog(
    BuildContext context, SkillStore store, Boss boss) async {
  await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text('删除首领'),
              content: Text('确定删除「${boss.name}」及其全部技能吗？相关角色的重数也会一并删除。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消')),
                FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    onPressed: () {
                      store.removeBoss(boss);
                      Navigator.pop(context);
                    },
                    child: const Text('删除'))
              ]));
}

Future<void> showCharacterDialog(BuildContext context, SkillStore store,
    {CharacterData? character}) async {
  final name = TextEditingController(text: character?.name ?? '');
  final swapPoints =
      TextEditingController(text: '${character?.swapPoints ?? 0}');
  var gender = character?.gender ?? '女性';
  var school = normalizeSchool(character?.school ?? '未设置');
  var mind = normalizeMind(character?.mind ?? '未设置');
  var position = normalizePosition(character?.position ?? '输出');
  var weeklyCompleted = character?.weeklyCompleted ?? false;
  String? swapPointsError;
  final initialMinds = schoolMindPositions[school];
  if (initialMinds != null) {
    if (!initialMinds.containsKey(mind)) mind = initialMinds.keys.first;
    position = initialMinds[mind]!;
  } else {
    school = '未设置';
    mind = '未设置';
  }
  var initialSkillLevel = 1;
  String? importing;
  final importedLevels = <String, int>{};
  if (character != null) {
    final recordedLevels =
        character.levels.values.where((level) => level > 0).toList();
    if (recordedLevels.isNotEmpty) {
      initialSkillLevel = recordedLevels
          .reduce((lowest, level) => level < lowest ? level : lowest);
      initialSkillLevel =
          initialSkillLevel.clamp(1, store.maxSkillRank).toInt();
    }
    for (final boss in store.bosses) {
      for (final skill in boss.skills) {
        importedLevels[skill.name] = store.level(character.id, skill.id);
      }
    }
  }
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                  scrollable: true,
                  title: Text(character == null ? '新增角色' : '编辑角色'),
                  content: SizedBox(
                      width: 440,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('角色名称', style: formLabelStyle)),
                        const SizedBox(height: 5),
                        TextField(
                            controller: name,
                            decoration: const InputDecoration()),
                        const SizedBox(height: 12),
                        Wrap(spacing: 10, runSpacing: 12, children: [
                          _LabeledFilterDropdown<String>(
                              label: '角色性别',
                              value: gender,
                              values: const ['女性', '男性'],
                              width: 215,
                              itemLabel: (value) => value,
                              onChanged: (value) =>
                                  setState(() => gender = value ?? gender)),
                          _LabeledFilterDropdown<String>(
                              label: '门派',
                              value: school,
                              values: schoolOptions,
                              width: 215,
                              itemLabel: (value) => value,
                              onChanged: (value) => setState(() {
                                    school = value ?? school;
                                    final minds = schoolMindPositions[school];
                                    mind = minds?.keys.firstOrNull ?? '未设置';
                                    position = minds?[mind] ?? '输出';
                                  })),
                          _LabeledFilterDropdown<String>(
                              label: '心法',
                              value: mind,
                              values: school == '未设置'
                                  ? const ['未设置']
                                  : schoolMindPositions[school]!.keys.toList(),
                              width: 215,
                              itemLabel: (value) => value,
                              onChanged: (value) => setState(() {
                                    mind = value ?? mind;
                                    position = schoolMindPositions[school]
                                            ?[mind] ??
                                        position;
                                  })),
                          _LabeledFilterDropdown<String>(
                              label: '定位',
                              value: position,
                              values: school == '未设置' || mind == '未设置'
                                  ? positionOptions
                                  : [schoolMindPositions[school]![mind]!],
                              width: 215,
                              itemLabel: (value) => value,
                              onChanged: (value) =>
                                  setState(() => position = value ?? position)),
                          SizedBox(
                              width: 215,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('换将点', style: formLabelStyle),
                                    const SizedBox(height: 5),
                                    TextField(
                                        controller: swapPoints,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        onChanged: (_) => setState(
                                            () => swapPointsError = null),
                                        decoration: InputDecoration(
                                            errorText: swapPointsError))
                                  ])),
                          SizedBox(
                              width: 215,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 18),
                                    InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => setState(() =>
                                            weeklyCompleted = !weeklyCompleted),
                                        child: Container(
                                            height: 42,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            decoration: BoxDecoration(
                                                color: const Color(0xfff7f9f8),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border:
                                                    Border.all(color: line)),
                                            child: Row(children: [
                                              Checkbox(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  value: weeklyCompleted,
                                                  onChanged: (value) =>
                                                      setState(() =>
                                                          weeklyCompleted =
                                                              value ?? false)),
                                              const SizedBox(width: 2),
                                              const Text('本周 CD',
                                                  style: TextStyle(
                                                      color: ink, fontSize: 13))
                                            ])))
                                  ])),
                          _LabeledFilterDropdown<int>(
                              label: '全部技能重数',
                              value: initialSkillLevel,
                              values: List.generate(store.maxSkillRank,
                                  (index) => store.maxSkillRank - index),
                              width: 215,
                              itemLabel: (value) => '$value 重',
                              onChanged: (value) => setState(() {
                                    initialSkillLevel =
                                        value ?? initialSkillLevel;
                                    if (character != null) {
                                      for (final boss in store.bosses) {
                                        for (final skill in boss.skills) {
                                          importedLevels[skill.name] =
                                              initialSkillLevel;
                                        }
                                      }
                                    }
                                  }))
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: importing == null
                                      ? () async {
                                          setState(() => importing = 'excel');
                                          try {
                                            final data =
                                                await pickCharacterExcelData(
                                                    store.maxSkillRank);
                                            if (data == null) return;
                                            final levels =
                                                normalizeGenderSkillLevels(
                                                    store,
                                                    data.gender,
                                                    data.skillLevels);
                                            setState(() {
                                              if (name.text.trim().isEmpty) {
                                                name.text = data.name;
                                              }
                                              gender = data.gender;
                                              if (character == null) {
                                                importedLevels.clear();
                                              }
                                              importedLevels.addAll(levels);
                                              importing = null;
                                            });
                                            if (context.mounted) {
                                              await showCharacterDraftPreview(
                                                  context,
                                                  store,
                                                  importedLevels,
                                                  initialSkillLevel,
                                                  gender);
                                            }
                                          } on FormatException catch (error) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content:
                                                          Text(error.message)));
                                            }
                                          } catch (_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Excel 导入失败，请确认文件格式')));
                                            }
                                          } finally {
                                            if (context.mounted &&
                                                importing != null) {
                                              setState(() => importing = null);
                                            }
                                          }
                                        }
                                      : null,
                                  icon: importing == 'excel'
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.upload_file_outlined,
                                          size: 17),
                                  label: Text(importing == 'excel'
                                      ? '处理中'
                                      : '导入 Excel'))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: importing == null
                                      ? () async {
                                          setState(() => importing = 'image');
                                          try {
                                            final levels =
                                                await pickCharacterImageLevels(
                                                    store, gender);
                                            if (levels == null) return;
                                            setState(() {
                                              if (character == null) {
                                                importedLevels.clear();
                                              }
                                              importedLevels.addAll(levels);
                                              importing = null;
                                            });
                                            if (context.mounted) {
                                              await showCharacterDraftPreview(
                                                  context,
                                                  store,
                                                  importedLevels,
                                                  initialSkillLevel,
                                                  gender);
                                            }
                                          } catch (error) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(error
                                                          .toString()
                                                          .replaceFirst(
                                                              'FormatException: ',
                                                              ''))));
                                            }
                                          } finally {
                                            if (context.mounted &&
                                                importing != null) {
                                              setState(() => importing = null);
                                            }
                                          }
                                        }
                                      : null,
                                  icon: importing == 'image'
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.image_outlined,
                                          size: 17),
                                  label: Text(
                                      importing == 'image' ? '处理中' : '导入图片')))
                        ]),
                        const SizedBox(height: 10),
                        SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                                onPressed: importing == null
                                    ? () => showCharacterDraftPreview(
                                        context,
                                        store,
                                        importedLevels,
                                        initialSkillLevel,
                                        gender)
                                    : null,
                                icon: const Icon(Icons.preview_outlined,
                                    size: 17),
                                label: const Text('预览技能与属性'))),
                        const SizedBox(height: 12),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('精神值和耐力值会根据技能重数自动计算，无需手动录入。',
                                style: TextStyle(color: muted, fontSize: 12))),
                        if (character != null) ...[
                          const SizedBox(height: 18),
                          SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(
                                          color: Colors.redAccent)),
                                  onPressed: store.characters.length <= 1
                                      ? null
                                      : () async {
                                          final removed =
                                              await showDeleteCharacterDialog(
                                                  context, store, character);
                                          if (removed && context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                  icon: const Icon(Icons.delete_outline,
                                      size: 17),
                                  label: const Text('删除角色')))
                        ]
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: importing == null
                            ? () {
                                final parsedSwapPoints =
                                    int.tryParse(swapPoints.text);
                                if (parsedSwapPoints == null ||
                                    parsedSwapPoints < 0) {
                                  setState(
                                      () => swapPointsError = '请输入大于等于 0 的整数');
                                  return;
                                }
                                if (character == null) {
                                  store.addCharacter(
                                      name: name.text,
                                      gender: gender,
                                      school: school,
                                      mind: mind,
                                      position: position,
                                      swapPoints: parsedSwapPoints,
                                      weeklyCompleted: weeklyCompleted,
                                      initialSkillLevel: initialSkillLevel,
                                      skillLevelsByName: importedLevels);
                                } else {
                                  store.updateCharacter(character,
                                      name: name.text,
                                      gender: gender,
                                      school: school,
                                      mind: mind,
                                      position: position,
                                      swapPoints: parsedSwapPoints,
                                      weeklyCompleted: weeklyCompleted,
                                      skillLevelsByName: importedLevels);
                                }
                                Navigator.pop(context);
                              }
                            : null,
                        child: const Text('保存'))
                  ])));
  // Wait for the dialog route's exit animation before releasing controllers.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  name.dispose();
  swapPoints.dispose();
}

Future<CharacterExcelData?> pickCharacterExcelData(int maxSkillRank) async {
  final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: false);
  if (picked == null) return null;
  final file = picked.files.single;
  final path = file.path;
  if (path == null) throw const FormatException('无法读取 Excel 文件');
  final source = File(path);
  final size = await source.length();
  if (size > 20 * 1024 * 1024) {
    throw const FormatException('Excel 文件过大，请选择小于 20 MB 的角色技能表');
  }
  final bytes = await source.readAsBytes();
  return Isolate.run(
          () => CharacterExcelParser.parse(bytes, maxSkillRank: maxSkillRank))
      .timeout(const Duration(seconds: 20),
          onTimeout: () => throw const FormatException('Excel 解析超时，请检查文件是否损坏'));
}

Future<Map<String, int>?> pickCharacterImageLevels(
    SkillStore store, String gender) async {
  final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp']);
  if (picked == null) return null;
  final path = picked.files.single.path;
  if (path == null) throw const FormatException('无法读取图片');
  if (!Platform.isMacOS && !Platform.isWindows) {
    throw const FormatException('当前图片识别支持 macOS 和 Windows');
  }
  String ocrPath = path;
  Directory? temporaryDirectory;
  final imageSize = await File(path).length();
  if (imageSize > 25 * 1024 * 1024) {
    throw const FormatException('图片文件过大，请选择小于 25 MB 的截图');
  }
  // Windows uses its native decoder directly. Decoding and resizing a large
  // screenshot in Dart can temporarily allocate hundreds of MB and previously
  // caused the desktop process to become unresponsive or exit.
  if (Platform.isMacOS) {
    try {
      final prepared = await Isolate.run(() => _prepareOcrImage(path));
      if (prepared != null) {
        ocrPath = prepared;
        temporaryDirectory = File(prepared).parent;
      }
    } catch (_) {
      // Native OCR can still try the original image when preprocessing fails.
    }
  }
  const channel = MethodChannel('baizhan_skill/ocr');
  final List<dynamic> raw;
  try {
    raw = await channel.invokeListMethod<dynamic>('recognizeText', {
          'path': ocrPath
        }).timeout(const Duration(seconds: 45),
            onTimeout: () => throw const FormatException(
                '图片识别超时，请裁剪图片后重试，并确认系统已安装简体中文 OCR')) ??
        const [];
  } finally {
    if (temporaryDirectory != null) {
      try {
        await temporaryDirectory.delete(recursive: true);
      } catch (_) {}
    }
  }
  return parseCharacterImageOcr(raw, store, gender);
}

String? _prepareOcrImage(String path) {
  final source = img.decodeImage(File(path).readAsBytesSync());
  if (source == null) return null;
  final minimumWidthScale = source.width < 900 ? 900 / source.width : 1.0;
  final maximumSizeScale = 2400 / math.max(source.width, source.height);
  final scale = math.min(minimumWidthScale, maximumSizeScale);
  var prepared = (scale - 1).abs() > 0.05
      ? img.copyResize(source,
          width: (source.width * scale).round(),
          height: (source.height * scale).round(),
          interpolation: img.Interpolation.cubic)
      : source;
  prepared = img.adjustColor(prepared, contrast: 1.35, saturation: 0.35);
  final directory = Directory.systemTemp.createTempSync('baizhan_skill_ocr_');
  final output = '${directory.path}/prepared.png';
  File(output).writeAsBytesSync(img.encodePng(prepared));
  return output;
}

Map<String, int> parseCharacterImageOcr(
    List<dynamic> raw, SkillStore store, String gender) {
  final rankHeaders = {
    '十重': 10,
    '九重': 9,
    '八重': 8,
    '七重': 7,
    '六重': 6,
    '五重': 5,
    '四重': 4,
    '三重': 3,
    '二重': 2,
    '一重': 1
  };
  final knownSkills = store.bosses.expand((boss) => boss.skills).toList();
  final levels = <String, int>{};
  // The game's skill overview is ordered from ten ranks downward. The top
  // heading is often clipped by the currency bar, so treat the first block as
  // ten ranks even when OCR misses that heading.
  var currentRank = 10;
  String normalize(String value) =>
      value.replaceAll(RegExp(r'[^\u3400-\u9fffA-Za-z0-9]'), '');
  int editDistance(String left, String right) {
    var previous = List<int>.generate(right.length + 1, (index) => index);
    for (var i = 0; i < left.length; i++) {
      final current = <int>[i + 1];
      for (var j = 0; j < right.length; j++) {
        current.add(math.min(math.min(current[j] + 1, previous[j + 1] + 1),
            previous[j] + (left.codeUnitAt(i) == right.codeUnitAt(j) ? 0 : 1)));
      }
      previous = current;
    }
    return previous.last;
  }

  bool approximatelyContains(String text, String name) {
    if (text.contains(name)) return true;
    if (name.length < 3 || text.length < name.length) return false;
    final allowedErrors = name.length >= 6 ? 2 : 1;
    for (var start = 0; start <= text.length - name.length; start++) {
      if (editDistance(text.substring(start, start + name.length), name) <=
          allowedErrors) {
        return true;
      }
    }
    return text.length >= 3 &&
        text.length < name.length &&
        editDistance(text, name) <= 1;
  }

  for (final item in raw) {
    if (item is! Map) continue;
    final text = item['text']?.toString() ?? '';
    final normalizedText = normalize(text);
    final header = rankHeaders.entries
        .where((entry) => normalizedText.contains(entry.key))
        .firstOrNull;
    if (header != null) {
      currentRank = header.value;
      continue;
    }
    for (final skill in knownSkills) {
      final skillName = skillNameForGender(skill, gender);
      final normalizedName = normalize(skillName);
      if (approximatelyContains(normalizedText, normalizedName)) {
        levels[skill.name] = currentRank;
      }
    }
  }
  if (levels.isEmpty) {
    throw const FormatException('没有从图片中识别到现有技能，请确认图片清晰且包含重数标题');
  }
  return levels;
}

Future<void> showCharacterDraftPreview(BuildContext context, SkillStore store,
    Map<String, int> overrides, int defaultLevel, String gender) async {
  bool? strategyDescending;
  final expandedBossIds = <String>{};
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
            int levelFor(Skill skill) => (overrides[skill.name] ?? defaultLevel)
                .clamp(1, store.maxSkillRank)
                .toInt();
            BossCollectionProgress progressFor(Boss boss) =>
                bossCollectionProgressForLevels(
                    boss, gender, levelFor, store.maxSkillRank);
            int rankFor(Boss boss) => progressFor(boss).completedRank;
            final bosses = [...store.bosses];
            if (strategyDescending != null) {
              final originalOrder = <String, int>{
                for (var index = 0; index < bosses.length; index++)
                  bosses[index].id: index
              };
              bosses.sort((left, right) {
                final leftProgress = progressFor(left);
                final rightProgress = progressFor(right);
                var comparison = leftProgress.strategyRank
                    .compareTo(rightProgress.strategyRank);
                if (comparison == 0) {
                  comparison = leftProgress.collectionRatio
                      .compareTo(rightProgress.collectionRatio);
                }
                if (comparison == 0) {
                  comparison = (originalOrder[left.id] ?? 0)
                      .compareTo(originalOrder[right.id] ?? 0);
                }
                return strategyDescending! ? -comparison : comparison;
              });
            }
            const multipliers = [0, 1, 2, 3, 4, 5, 7, 10, 15, 22.5, 33.75];
            final allLevels = store.bosses
                .expand((boss) => boss.skills)
                .where((skill) => skillAppliesToGender(skill, gender))
                .map(levelFor)
                .toList();
            double threshold = 0;
            const bonuses = [
              0,
              100,
              200,
              300,
              400,
              2000,
              6000,
              8000,
              10000,
              12000,
              14000
            ];
            for (var rank = 1; rank <= 10; rank++) {
              if (allLevels.where((level) => level >= rank).length > 2) {
                threshold += bonuses[rank];
              }
            }
            double stat(bool spirit) =>
                10000 +
                threshold +
                store.bosses.fold<double>(0, (sum, boss) {
                  final base = bossStatForGender(boss, gender, spirit);
                  return sum + base * multipliers[rankFor(boss)];
                });
            return AlertDialog(
                title: const Text('角色技能预览'),
                content: SizedBox(
                    width: 620,
                    height: 620,
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: MetricCard(
                                width: double.infinity,
                                label: '精神值',
                                value: formatNumber(stat(true)),
                                accent: teal,
                                icon: Icons.bolt)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: MetricCard(
                                width: double.infinity,
                                label: '耐力值',
                                value: formatNumber(stat(false)),
                                accent: const Color(0xff69a991),
                                icon: Icons.shield_outlined))
                      ]),
                      const SizedBox(height: 12),
                      Expanded(
                          child: LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                          width: math.max(
                                              560, constraints.maxWidth),
                                          height: constraints.maxHeight,
                                          child: ListView(children: [
                                            Container(
                                                height: 40,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14),
                                                color: const Color(0xfff7f9f8),
                                                child: Row(children: [
                                                  const Expanded(
                                                      flex: 4,
                                                      child: Text('首领 / 技能',
                                                          style: TextStyle(
                                                              color: muted,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700))),
                                                  Expanded(
                                                      flex: 2,
                                                      child: InkWell(
                                                          onTap: () => setState(() =>
                                                              strategyDescending =
                                                                  !(strategyDescending ??
                                                                      false)),
                                                          child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                const Text(
                                                                    '攻略进度',
                                                                    style: TextStyle(
                                                                        color:
                                                                            muted,
                                                                        fontSize:
                                                                            11,
                                                                        fontWeight:
                                                                            FontWeight.w700)),
                                                                const SizedBox(
                                                                    width: 2),
                                                                Icon(
                                                                    strategyDescending ==
                                                                            null
                                                                        ? Icons
                                                                            .unfold_more
                                                                        : strategyDescending!
                                                                            ? Icons
                                                                                .arrow_downward
                                                                            : Icons
                                                                                .arrow_upward,
                                                                    size: 13,
                                                                    color:
                                                                        muted)
                                                              ]))),
                                                  const Expanded(
                                                      flex: 2,
                                                      child: Text('收集进度',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              color: muted,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700))),
                                                  const Expanded(
                                                      flex: 2,
                                                      child: Text('精神',
                                                          textAlign:
                                                              TextAlign.right,
                                                          style: TextStyle(
                                                              color: muted,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700))),
                                                  const Expanded(
                                                      flex: 2,
                                                      child: Text('耐力',
                                                          textAlign:
                                                              TextAlign.right,
                                                          style: TextStyle(
                                                              color: muted,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700)))
                                                ])),
                                            for (final boss in bosses) ...[
                                              Builder(builder: (context) {
                                                final progress =
                                                    progressFor(boss);
                                                final multiplier = multipliers[
                                                    progress.completedRank];
                                                return InkWell(
                                                    onTap: () => setState(() {
                                                          if (!expandedBossIds
                                                              .add(boss.id)) {
                                                            expandedBossIds
                                                                .remove(
                                                                    boss.id);
                                                          }
                                                        }),
                                                    child: _AllSkillsTableRow(
                                                        name: bossNameForGender(
                                                            boss, gender),
                                                        rank: progress
                                                            .strategyRank,
                                                        rankText: chineseRankLabel(
                                                            progress
                                                                .strategyRank),
                                                        collection:
                                                            '${progress.collectedSkills}/${progress.totalSkills}',
                                                        spirit:
                                                            '+${formatNumber(bossStatForGender(boss, gender, true) * multiplier)}',
                                                        stamina:
                                                            '+${formatNumber(bossStatForGender(boss, gender, false) * multiplier)}',
                                                        bossRow: true,
                                                        expanded:
                                                            expandedBossIds
                                                                .contains(
                                                                    boss.id)));
                                              }),
                                              if (expandedBossIds
                                                  .contains(boss.id))
                                                for (final skill in boss.skills
                                                    .where((skill) =>
                                                        skillAppliesToGender(
                                                            skill, gender)))
                                                  _DraftPreviewSkillRow(
                                                      skill: skill,
                                                      gender: gender,
                                                      maxSkillRank:
                                                          store.maxSkillRank,
                                                      value: levelFor(skill),
                                                      onChanged: (value) =>
                                                          setState(() =>
                                                              overrides[skill
                                                                      .name] =
                                                                  value))
                                            ]
                                          ])))))
                    ])),
                actions: [
                  FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭预览'))
                ]);
          }));
}

class _DraftPreviewSkillRow extends StatelessWidget {
  const _DraftPreviewSkillRow(
      {required this.skill,
      required this.gender,
      required this.maxSkillRank,
      required this.value,
      required this.onChanged});

  final Skill skill;
  final String gender;
  final int maxSkillRank;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration:
          const BoxDecoration(border: Border(top: BorderSide(color: line))),
      child: Row(children: [
        Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(skillNameForGender(skill, gender),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: skill.tradable ? purple : ink, fontSize: 12)))),
        Expanded(
            flex: 2,
            child: Center(
                child: _FilterDropdown<int>(
                    value: value,
                    values: List.generate(
                        maxSkillRank, (index) => maxSkillRank - index),
                    itemLabel: (rank) => '$rank 重',
                    width: 82,
                    onChanged: (rank) {
                      if (rank != null) onChanged(rank);
                    }))),
        const Expanded(flex: 6, child: SizedBox())
      ]));
}

Future<bool> showDeleteCharacterDialog(
    BuildContext context, SkillStore store, CharacterData character) async {
  return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('删除角色'),
                  content: Text('确定删除「${character.name}」吗？该角色的技能重数也会一并删除。'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消')),
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        onPressed: () {
                          store.removeCharacter(character);
                          Navigator.pop(context, true);
                        },
                        child: const Text('删除'))
                  ])) ??
      false;
}
