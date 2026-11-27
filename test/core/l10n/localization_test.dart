import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:melodix/core/errors/error_messages.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/preferences/app_language.dart';

import '../../features/player/player_fixtures.dart';
import '../../support/l10n_support.dart';

import 'package:melodix/features/player/data/background/session_states.dart';

/// The `{name}` placeholders of a text (and `{}`, the plural's count).
Set<String> _placeholders(Object text) => {
  for (final form in text is Map ? text.values : [text])
    for (final m in RegExp(r'\{(\w*)\}').allMatches(form as String))
      m.group(1)!,
};

void main() {
  const texts = AppLocalizations();
  tearDown(() => useLanguage('en'));

  group('the translation files', () {
    final en = readTranslations('en'), ar = readTranslations('ar');

    test('every text is in both languages, and in the code', () {
      expect(ar.keys.toSet(), en.keys.toSet());
      expect(AppLocalizations.keys.toSet(), en.keys.toSet());
    });

    test('same placeholders and shape (plain or plural) in both', () {
      for (final key in en.keys) {
        expect(ar[key] is Map, en[key] is Map, reason: '$key: plural?');
        expect(_placeholders(ar[key]!), _placeholders(en[key]!), reason: key);
        if (en[key] is Map) {
          expect((ar[key] as Map).containsKey('other'), isTrue, reason: key);
        }
      }
    });
  });

  group('Arabic', () {
    setUp(() => useLanguage('ar'));

    test('plurals: one, two, a few, many, a hundred', () {
      expect(texts.songsCount(1), 'أغنية واحدة');
      expect(texts.songsCount(2), 'أغنيتان');
      expect(texts.songsCount(3), '3 أغانٍ');
      expect(texts.songsCount(11), '11 أغنية');
      expect(texts.songsCount(100), '100 أغنية');
      expect(texts.addedSongsToPlaylist(4, 'Mix'), 'أُضيفت 4 أغانٍ إلى «Mix»');
    });

    test('texts made of parts, and numbers', () {
      expect(texts.sleepTimerMinutes(90), '1 س 30 د');
      expect(texts.minimumLengthValue(0), 'أي طول');
      expect(texts.videoPosition(2, 9), '2 من 9');
      expect(texts.playlistNameSuggestions, hasLength(5));
      expect(texts.speedValue(1.5), '1.5×');
    });

    test('failures from the data layer are translated; others kept', () {
      expect(texts.failure(ErrorMessages.videosSync), texts.errorVideosSync);
      expect(texts.failure('Server says no'), 'Server says no');
    });

    test('the notification speaks the app language', () {
      final item = songMediaItem(
        playerSong(1, title: ' '),
        duration: const Duration(minutes: 3),
      );
      expect(item.title, 'أغنية غير معروفة');
    });
  });

  test('English reads as before', () {
    expect(english.songsCount(0), '0 songs');
    expect(english.songsCount(1), '1 song');
    expect(english.songsCount(3), '3 songs');
    expect(english.backSeconds(10), 'Back 10 seconds');
    expect(
      english.scanResult(added: 3, removed: 1),
      'Found 3 new songs · 1 song removed',
    );
    expect(english.failure(ErrorMessages.write), 'Could not save your change');
  });

  group('AppLanguageCubit', () {
    setUp(() => HydratedBloc.storage = MemoryStorage());

    test('follows the phone when it can, else English', () {
      expect(
        AppLanguageCubit(deviceLocale: () => const Locale('ar', 'EG'))
            .resolvedLocale,
        const Locale('ar'),
      );
      expect(
        AppLanguageCubit(deviceLocale: () => const Locale('fr')).resolvedLocale,
        const Locale('en'),
      );
    });

    test('a chosen language wins, and is kept for the next launch', () {
      final cubit = AppLanguageCubit(deviceLocale: () => const Locale('en'))
        ..choose(AppLanguage.arabic);
      expect(cubit.resolvedLocale, const Locale('ar'));

      final nextLaunch = AppLanguageCubit();
      expect(nextLaunch.state, AppLanguage.arabic);
      expect(nextLaunch.fromJson(const {'language': 'klingon'}), isNull);
    });
  });

  testWidgets('a screen without the app around it still reads English', (
    tester,
  ) async {
    late String text;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          text = context.l10n.settings;
          return const SizedBox();
        },
      ),
    );
    expect(text, 'Settings');
  });
}
