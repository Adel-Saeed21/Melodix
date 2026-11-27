import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The architecture's rules, checked on the source: a change that breaks
/// one fails here, before it spreads.
void main() {
  /// Every Dart file under [dir] (generated files excluded), with its
  /// `package:melodix/…` imports.
  Map<String, List<String>> importsUnder(String dir) => {
    for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart') &&
          !f.path.endsWith('.g.dart') &&
          !f.path.endsWith('.freezed.dart'))
        f.path: [
          for (final m in RegExp(
            r"^import 'package:melodix/([^']+)';",
            multiLine: true,
          ).allMatches(f.readAsStringSync()))
            m.group(1)!,
        ],
  };

  final all = importsUnder('lib');

  /// The feature a lib/ path or an import belongs to (null: not a feature).
  String? featureOf(String path) =>
      RegExp(r'features/([^/]+)/').firstMatch(path)?.group(1);

  /// Files that wire features together (the composition root): allowed to
  /// import what they connect.
  bool isWiring(String path) =>
      path.endsWith('_injection.dart') ||
      path.contains('core/config/dependency_injection/') ||
      path.contains('core/config/routing/');

  test('core never depends on a feature (except the wiring)', () {
    final offenders = [
      for (final MapEntry(key: file, value: imports) in all.entries)
        if (file.startsWith('lib/core/') && !isWiring(file))
          for (final i in imports)
            if (i.startsWith('features/')) '$file -> $i',
    ];
    expect(offenders, isEmpty);
  });

  test('no two features depend on each other', () {
    final uses = <String, Set<String>>{};
    for (final MapEntry(key: file, value: imports) in all.entries) {
      final from = featureOf(file);
      if (from == null || isWiring(file)) continue;
      for (final i in imports) {
        final to = featureOf(i);
        if (to != null && to != from) (uses[from] ??= {}).add(to);
      }
    }
    final loops = {
      for (final MapEntry(key: a, value: targets) in uses.entries)
        for (final b in targets)
          if (uses[b]?.contains(a) ?? false) ([a, b]..sort()).join(' <-> '),
    };
    expect(loops, isEmpty);
  });

  test('domain code is plain Dart: no Flutter, data layer or database', () {
    final offenders = [
      for (final MapEntry(key: file, value: imports) in all.entries)
        if (file.contains('/domain/'))
          for (final i in imports)
            if (i.contains('/data/') ||
                i.startsWith('core/database/') ||
                i.contains('/presentation/'))
              '$file -> $i',
      for (final file in all.keys)
        if (file.contains('/domain/') &&
            File(file)
                .readAsStringSync()
                .contains(RegExp(r"import 'package:(flutter|material_ui)/")))
          '$file -> Flutter',
    ];
    expect(offenders, isEmpty);
  });

  test('screens never reach the data layer or the database', () {
    final offenders = [
      for (final MapEntry(key: file, value: imports) in all.entries)
        if (file.contains('/presentation/'))
          for (final i in imports)
            if (i.contains('/data/') || i.startsWith('core/database/'))
              '$file -> $i',
    ];
    expect(offenders, isEmpty);
  });
}
