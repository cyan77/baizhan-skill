import 'dart:math';
import 'package:baizhan_skill/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('optimized attributes match reference after rank and gender edits', () {
    final random = Random(77);
    final store = SkillStore();
    for (var b = 0; b < 34; b++) {
      store.bosses.add(Boss(id: '$b', name: b == 0 ? '杜姬欣' : '首领$b',
          type: '精英', spirit: 240, stamina: 560,
          skills: List.generate(5, (s) => Skill(id: '$b-$s',
              name: s == 0 ? '蛮熊碎颅击' : '技能$s'))));
    }
    final character = CharacterData(id: 'target', name: '角色', gender: '女性',
        school: '万花', mind: '花间游', position: '输出', levels: {});
    // Put the target last to exercise lookup costs on a large roster.
    for (var c = 0; c < 200; c++) {
      store.characters.add(CharacterData(id: 'other$c', name: '其他$c',
          gender: '女性', school: '万花', mind: '花间游', position: '输出', levels: {}));
    }
    store.characters.add(character);

    double reference(bool spirit) {
      final levels = <int>[];
      var total = 10000.0;
      for (final boss in store.bosses) {
        final ranks = boss.skills
            .where((s) => skillAppliesToGender(s, character.gender))
            .map((s) => store.level(character.id, s.id)).toList();
        levels.addAll(ranks);
        final rank = ranks.isEmpty || ranks.any((r) => r < 1)
            ? 0 : ranks.reduce(min);
        total += bossStatForGender(boss, character.gender, spirit) *
            (rank == 0 ? 0 : store.statRules.rankMultipliers[rank] ?? 0);
      }
      for (var r = 1; r <= store.maxSkillRank; r++) {
        if (levels.where((level) => level >= r).length > 2) {
          total += store.statRules.threeSkillBonuses[r] ?? 0;
        }
      }
      return total;
    }

    for (var sample = 0; sample < 100; sample++) {
      store.maxSkillRank = sample.isEven ? 10 : 15;
      store.statRules.ensureThrough(store.maxSkillRank);
      character.gender = sample.isEven ? '女性' : '男性';
      for (final boss in store.bosses) {
        for (final skill in boss.skills) {
          character.levels[skill.id] = sample < 3
              ? 0 : random.nextInt(store.maxSkillRank + 1);
        }
      }
      if (sample == 1) {
        character.levels['0-1'] = 10;
        character.levels['0-2'] = 10;
      } else if (sample == 2) {
        character.levels['0-1'] = 10;
        character.levels['0-2'] = 10;
        character.levels['0-3'] = 10;
      }
      expect(store.stat(character.id, true), closeTo(reference(true), 0.000001));
      expect(store.stat(character.id, false), closeTo(reference(false), 0.000001));
    }
    for (var i = 0; i < 50; i++) {
      reference(true);
      store.stat(character.id, true);
    }
    final before = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) { reference(true); }
    before.stop();
    final after = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) { store.stat(character.id, true); }
    after.stop();
    print('Attribute benchmark: reference ${before.elapsedMicroseconds}us, optimized ${after.elapsedMicroseconds}us');
    store.dispose();
  });
}
