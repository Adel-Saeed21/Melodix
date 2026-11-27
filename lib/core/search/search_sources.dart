import 'package:material_ui/material_ui.dart';

/// A group of search results (e.g. "Videos") from a part of the app the
/// library search doesn't know about.
class SearchSection {
  const SearchSection({
    required this.title,
    required this.count,
    required this.itemBuilder,
  });

  final String title;

  /// How many results there are ("Show all 12").
  final int count;

  /// Builds result [index] (only the ones shown are ever built).
  final Widget Function(BuildContext context, int index) itemBuilder;
}

/// Something the search can also look in. It notifies when its data
/// changes, so open results update.
abstract interface class SearchSource implements Listenable {
  /// The results for [query] (trimmed, not empty), or null for none. Runs
  /// as the user types: must be quick (in memory). [context] gives the
  /// texts in the app's language (e.g. the section's title).
  SearchSection? search(BuildContext context, String query);

  /// The `OpenedFromSearch.kind` this source records when one of its
  /// results is opened (e.g. 'video').
  String get openedKind;

  /// A row for item [id], opened from search earlier (the search history
  /// shows it); null if it's gone. Opening it again should record it again.
  Widget? openedTile(BuildContext context, String id);
}

/// Makes [sources] available to the search below it. Lets a screen that
/// puts features together (the home screen) add, say, videos to the music
/// search, without the music library depending on videos.
class SearchSources extends InheritedWidget {
  const SearchSources({super.key, required this.sources, required super.child});

  final List<SearchSource> sources;

  /// The sources above [context]; none if there's no [SearchSources].
  static List<SearchSource> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SearchSources>()?.sources ??
      const [];

  @override
  bool updateShouldNotify(SearchSources old) => old.sources != sources;
}
