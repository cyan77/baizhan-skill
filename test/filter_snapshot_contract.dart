import '../lib/filter_snapshot.dart';

// Runs without Flutter to verify the membership contract independently of UI.
void main() {
  void check(bool condition, String label) {
    if (!condition) throw StateError(label);
  }

  final ranks = {'a': 9, 'b': 10};
  final snapshot = FilterSnapshot<String>();
  var applications = 0;
  Set<String> apply(int max) => snapshot.resolve((max, false), () {
        applications++;
        return ranks.keys.where((id) => ranks[id]! <= max);
      });
  check(
    apply(9).contains('a') && !apply(9).contains('b'),
    'initial rank filter',
  );
  ranks['a'] = 10;
  ranks['b'] = 9;
  check(
    apply(9).contains('a') && !apply(9).contains('b'),
    'edits keep IDs fixed',
  );
  check(applications == 1, 'rebuilds never reapply predicates');
  snapshot.clear();
  check(!apply(9).contains('a') && apply(9).contains('b'), 'explicit reapply');
  check(apply(10).length == 2, 'condition change reapplies');
  check(apply(0).isEmpty, 'empty result');
  ranks['c'] = 0;
  check(apply(0).isEmpty, 'empty snapshot stays empty');
  snapshot.clear();
  check(apply(0).contains('c'), 'reset refreshes empty result');

  final entries = FilterSnapshot<(String, String)>();
  var incomplete = true;
  Set<(String, String)> progress(bool onlyIncomplete) => entries.resolve((
        'boss',
        onlyIncomplete,
      ), () => [if (!onlyIncomplete || incomplete) ('boss', 'character')]);
  check(progress(true).length == 1, 'incomplete pair');
  incomplete = false;
  check(progress(true).length == 1, 'completion retains nested character');
  entries.clear();
  check(progress(true).isEmpty, 'completion removed on explicit reapply');
  check(progress(false).length == 1, 'reset includes completed pairs');
  print('Passed 12 snapshot contract checks.');
}
