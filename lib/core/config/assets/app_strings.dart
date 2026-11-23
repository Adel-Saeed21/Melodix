class AppStrings {
  AppStrings._();

  static const String enjoyListeningToMusic = 'Enjoy listening to music';
  static const String getStartSecondText =
      "Lorem ipsum dolor sit amet,\n consectetur adipiscing elit. Sagittis enim\n purus sed phasellus. Cursus ornare id\n scelerisque aliquam.";
  static const String getStartButtonText = 'Get Started';
  static const String containueButtonText = 'Continue';
  static const String chooseModeText = 'Choose Mode';
  static const String lightModeText = 'Light Mode';
  static const String darkModeText = 'Dark Mode';

  // Main navigation
  static const String music = 'Music';
  static const String video = 'Video';
  static const String settings = 'Settings';

  // Video
  static const String noVideosTitle = 'No videos yet';
  static const String noVideosSubtitle =
      'Videos stored on your device will appear here.';

  // Settings
  static const String appearance = 'Appearance';
  static const String systemModeText = 'System';

  // Music library
  static const String songs = 'Songs';
  static const String albums = 'Albums';
  static const String artists = 'Artists';
  static const String artist = 'Artist';
  static const String allowMusicAccessTitle = 'Allow access to your music';
  static const String allowMusicAccessSubtitle =
      'Melodix plays the music stored on your device. Allow access to see '
      'your library.';
  static const String musicAccessBlockedSubtitle =
      'Access to music is turned off. Enable "Music and audio" for Melodix '
      'in your device settings.';
  static const String allowAccess = 'Allow access';
  static const String openSettings = 'Open settings';
  static const String scanningLibraryTitle = 'Scanning your music…';
  static const String scanningLibrarySubtitle =
      'This only takes a moment the first time.';
  static const String noMusicTitle = 'No music found';
  static const String noMusicSubtitle =
      'Add songs to your device, then pull down to refresh.';
  static const String libraryErrorTitle = 'Something went wrong';
  static const String tryAgain = 'Try again';
  static const String noAlbums = 'No albums yet';
  static const String noArtists = 'No artists yet';

  static String songsCount(int count) => count == 1 ? '1 song' : '$count songs';
  static String albumsCount(int count) =>
      count == 1 ? '1 album' : '$count albums';

  // Song options menu
  static const String songOptions = 'Song options';
  static const String playNext = 'Play next';
  static const String addToQueue = 'Add to queue';
  static const String addToFavourites = 'Add to favourites';
  static const String removeFromFavourites = 'Remove from favourites';
  static const String addToPlaylist = 'Add to playlist';
  static const String goToAlbum = 'Go to album';
  static const String goToArtist = 'Go to artist';
  static const String hideFromLibrary = 'Hide from library';
  static const String addedToFavourites = 'Added to favourites';
  static const String removedFromFavourites = 'Removed from favourites';
  static const String hiddenFromLibrary = 'Hidden from library';
  static const String restoredToLibrary = 'Back in your library';
  static const String songNotFound = 'This song is no longer in your library';
  static const String undo = 'Undo';
  static const String newPlaylist = 'New playlist';
  static const String playlistName = 'Playlist name';
  static const String playlistNameRequired = 'Enter a name';
  static const String create = 'Create';
  static const String cancel = 'Cancel';
  static const String noPlaylistsYet = 'No playlists yet';

  static String addedToPlaylist(String name) => 'Added to "$name"';
  static String alreadyInPlaylist(String name) => 'Already in "$name"';

  // Hidden songs
  static const String library = 'Library';
  static const String hiddenSongs = 'Hidden songs';
  static const String hiddenSongsSubtitle = 'Songs you hid from your library';
  static const String noHiddenSongs = 'No hidden songs';
  static const String noHiddenSongsSubtitle =
      'Songs you hide from the ⋮ menu appear here.';
  static const String unhide = 'Unhide';

  // Playlists
  static const String playlists = 'Playlists';
  static const String playlist = 'Playlist';
  static const String playlistOptions = 'Playlist options';
  static const String createPlaylistHint =
      'Create a playlist to keep songs you love together.';
  static const String rename = 'Rename';
  static const String renamePlaylist = 'Rename playlist';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String deletePlaylist = 'Delete playlist';
  static const String playlistDeleted = 'Playlist deleted';
  static const String playlistRenamed = 'Playlist renamed';
  static const String playlistAddedToFavourites =
      'Playlist added to favourites';
  static const String playlistRemovedFromFavourites =
      'Playlist removed from favourites';
  static const String removeFromPlaylist = 'Remove from playlist';
  static const String emptyPlaylistTitle = 'This playlist is empty';
  static const String emptyPlaylistSubtitle =
      'Use "Add to playlist" in a song\'s ⋮ menu to add songs.';

  static String playlistCreated(String name) => 'Created "$name"';
  static String removedFromPlaylist(String name) => 'Removed from "$name"';
  static String deletePlaylistConfirm(String name) =>
      'Delete "$name"? The songs stay in your library.';

  // Playlist name sheet
  static const String newPlaylistSubtitle = 'Give your playlist a name';
  static const String renamePlaylistSubtitle = 'Choose a new name';
  static const String playlistNameHint = 'My playlist';
  static const String clearName = 'Clear name';
  static const List<String> playlistNameSuggestions = [
    'Chill vibes',
    'Workout',
    'Road trip',
    'Focus',
    'Late night',
  ];

  // Playlist reordering
  static const String dragToReorder = 'Drag to reorder';
  static const String reorderFailed = "Couldn't save the new order";

  // Search
  static const String search = 'Search';
  static const String closeSearch = 'Close search';
  static const String searchHint = 'Songs, artists, albums, playlists';
  static const String searchPromptTitle = 'Find your music';
  static const String searchPromptSubtitle =
      'Search your songs, artists, albums and playlists.';
  static const String noResultsSubtitle =
      'Check the spelling or try another word.';

  static String noResultsFor(String query) => 'No results for "$query"';
  static String showAll(int count) => 'Show all $count';

  // Sorting
  static const String sortBy = 'Sort by';
  static const String recentlyAdded = 'Recently added';
  static const String aToZ = 'A–Z';
  static const String mostPlayed = 'Most played';

  static String playsCount(int count) => count == 1 ? '1 play' : '$count plays';

  // Multi-select
  static const String selectSongs = 'Select songs';
  static const String cancelSelection = 'Cancel selection';
  static const String selectAll = 'Select all';
  static const String deselectAll = 'Deselect all';
  static const String playlistShort = 'Playlist';
  static const String favourite = 'Favourite';
  static const String unfavourite = 'Unfavourite';
  static const String hide = 'Hide';
  static const String nothingDeleted = 'No songs were deleted';
  static const String deleteSongsMessage =
      "They'll be permanently deleted from your phone. This can't be undone.";

  static String selectedCount(int count) => '$count selected';
  static String hiddenSongsCount(int count) =>
      count == 1 ? 'Hidden from library' : '$count songs hidden';
  static String addedSongsToFavourites(int count) =>
      count == 1 ? addedToFavourites : 'Added $count songs to favourites';
  static String removedSongsFromFavourites(int count) => count == 1
      ? removedFromFavourites
      : 'Removed $count songs from favourites';
  static String addedSongsToPlaylist(int count, String name) =>
      'Added ${songsCount(count)} to "$name"';
  static String deletedSongs(int count) =>
      count == 1 ? 'Deleted 1 song' : 'Deleted $count songs';
  static String deleteSongsTitle(int count) =>
      count == 1 ? 'Delete 1 song?' : 'Delete $count songs?';

  // Player
  static const String play = 'Play';
  static const String pause = 'Pause';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String shuffle = 'Shuffle';
  static const String repeatOff = 'Repeat off';
  static const String repeatAll = 'Repeat all';
  static const String repeatOne = 'Repeat one';
  static const String openPlayer = 'Open player';
  static const String closePlayer = 'Close player';
  static const String nowPlaying = 'Now playing';
  static const String secondsShort = 's';

  // Queue
  static const String queue = 'Queue';
  static const String openQueue = 'Open queue';
  static const String playingFrom = 'Playing from';
  static const String searchResults = 'Search results';
}
