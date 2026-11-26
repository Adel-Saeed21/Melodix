/// FNV-1a 64-bit hash. Turns string ids (e.g. photo_manager asset ids) into
/// stable Isar ids, as recommended by the Isar docs.
int fastHash(String value) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < value.length) {
    final codeUnit = value.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
