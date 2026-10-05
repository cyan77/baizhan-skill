/// Keeps result identities fixed while the underlying values remain editable.
/// Only changing the filter key or explicitly clearing it applies predicates again.
class FilterSnapshot<Id> {
  Object? _key;
  Set<Id>? _ids;

  Set<Id> resolve(Object key, Iterable<Id> Function() apply) {
    if (_ids == null || key != _key) {
      _key = key;
      _ids = Set.unmodifiable(apply());
    }
    return _ids!;
  }

  void clear() {
    _key = null;
    _ids = null;
  }
}
