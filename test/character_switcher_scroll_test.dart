import 'package:baizhan_skill/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  SkillStore fixture() {
    final store = SkillStore();
    for (var i = 0; i < 10; i++) {
      store.characters.add(CharacterData(
          id: 'c$i', name: '角色$i', gender: '女性', school: '未设置',
          mind: '未设置', position: '输出', levels: const {}));
    }
    store.selectedCharacterId = 'c0';
    return store;
  }

  Future<void> mount(WidgetTester tester, SkillStore store) async {
    await tester.binding.setSurfaceSize(const Size(400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AnimatedBuilder(
        animation: store,
        builder: (_, __) => CharacterSwitcher(store: store)))));
    await tester.pumpAndSettle();
  }

  ScrollPosition position(WidgetTester tester) => tester
      .state<ScrollableState>(find.byType(Scrollable))
      .position;

  testWidgets('clicking a visible or partially visible card never scrolls', (tester) async {
    final store = fixture();
    await mount(tester, store);
    final before = position(tester).pixels;
    await tester.tap(find.text('角色1'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(store.selectedCharacterId, 'c1');
    expect(position(tester).pixels, before);
    // The third card is clipped by the right edge, but can still be clicked.
    await tester.tapAt(const Offset(375, 35));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(store.selectedCharacterId, 'c2');
    expect(position(tester).pixels, before);
  });

  testWidgets('external selection reveals only offscreen cards', (tester) async {
    final store = fixture();
    await mount(tester, store);
    store.selectCharacter('c1');
    await tester.pumpAndSettle();
    expect(position(tester).pixels, 0);
    store.selectCharacter('c7');
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(ListView));
    final card = tester.getRect(find.ancestor(
        of: find.text('角色7'), matching: find.byType(AnimatedContainer)));
    expect(card.right, closeTo(viewport.right, .1));
    expect(card.left, greaterThanOrEqualTo(viewport.left));
    final before = position(tester).pixels;
    store.selectCharacter('c6');
    await tester.pumpAndSettle();
    expect(position(tester).pixels, before);
    store.selectCharacter('c0');
    await tester.pumpAndSettle();
    expect(position(tester).pixels, 0);
  });

  testWidgets('returning to the page reveals the selected character', (tester) async {
    final store = fixture();
    await mount(tester, store);
    await tester.pumpWidget(const SizedBox());
    store.selectCharacter('c8');
    await mount(tester, store);
    final viewport = tester.getRect(find.byType(ListView));
    final card = tester.getRect(find.ancestor(
        of: find.text('角色8'), matching: find.byType(AnimatedContainer)));
    expect(card.left, greaterThanOrEqualTo(viewport.left));
    expect(card.right, lessThanOrEqualTo(viewport.right));
    expect(position(tester).pixels, greaterThan(0));
  });
}
