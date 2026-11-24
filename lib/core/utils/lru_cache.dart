import 'dart:collection';

/// A small in-memory cache that drops the least recently used entry once it
/// holds [capacity] entries. Null values can be cached (e.g. "no artwork").
class LruCache<K, V> {
  LruCache({required this.capacity}) : assert(capacity > 0);

  final int capacity;
  final LinkedHashMap<K, V> _entries = LinkedHashMap();

  int get length => _entries.length;

  bool containsKey(K key) => _entries.containsKey(key);

  /// The cached value (marking it as recently used), or null if absent.
  /// Use [containsKey] to tell a cached null from a missing entry.
  V? get(K key) {
    if (!_entries.containsKey(key)) return null;
    final value = _entries.remove(key) as V; // re-insert: most recent last
    _entries[key] = value;
    return value;
  }

  void put(K key, V value) {
    _entries
      ..remove(key)
      ..[key] = value;
    if (_entries.length > capacity) _entries.remove(_entries.keys.first);
  }
}
