import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/isar_database.dart';

bool _initialized = false;

/// Path of the Isar native library bundled with isar_community_flutter_libs
/// for this machine, or null if there isn't one (tests using real Isar are
/// then skipped).
String? isarLibraryPath() {
  if (!Platform.isLinux || Abi.current() != Abi.linuxX64) return null;
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  final packages = (jsonDecode(config.readAsStringSync())['packages'] as List)
      .cast<Map<String, Object?>>();
  final package = packages.firstWhere(
    (p) => p['name'] == 'isar_community_flutter_libs',
    orElse: () => const {},
  );
  final root = package['rootUri'] as String?;
  if (root == null) return null;
  final rootUri = Uri.parse(root);
  final dir = rootUri.isAbsolute
      ? Directory.fromUri(rootUri)
      : Directory.fromUri(config.parent.uri.resolveUri(rootUri));
  final lib = File('${dir.path}/linux/libisar.so');
  return lib.existsSync() ? lib.path : null;
}

/// Opens a fresh Isar database (all app schemas) in a temp folder.
Future<Isar> openTestIsar() async {
  if (!_initialized) {
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): isarLibraryPath()!},
    );
    _initialized = true;
  }
  final dir = await Directory.systemTemp.createTemp('melodix_isar_');
  return Isar.open(
    IsarDatabase.schemas,
    directory: dir.path,
    name: 'test_${DateTime.now().microsecondsSinceEpoch}',
    inspector: false,
  );
}

/// Closes [isar] and deletes its files.
Future<void> closeTestIsar(Isar isar) async {
  await isar.close(deleteFromDisk: true);
}
