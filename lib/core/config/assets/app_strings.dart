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
  static const String continueWatching = 'Continue watching';
  static const String selectVideos = 'Select videos';
  static const String layout = 'Layout';
  static const String theme = 'Theme';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeSystem = 'Same as the phone';
  static const String accentColour = 'Accent colour';
  static const String selectionBarHint = 'Where the actions appear';
  static const String miniPlayerStyle = 'Music bar';
  static const String miniPlayerClassic = 'Classic';
  static const String miniPlayerClassicHint = 'Title, controls and a seek bar';
  static const String miniPlayerCapsule = 'Capsule';
  static const String miniPlayerCapsuleHint =
      'A floating pill with a progress ring';
  static const String miniPlayerMinimal = 'Minimal';
  static const String miniPlayerMinimalHint =
      'A flat bar with a thin progress line';
  static const String selectionBarStyle = 'Selection actions';
  static const String selectionBarBottom = 'Bottom';
  static const String selectionBarSide = 'Right side';
  static const String videoOptions = 'Video options';
  static String deleteVideosTitle(int count) =>
      count == 1 ? 'Delete this video?' : 'Delete $count videos?';
  static const String deleteVideosMessage =
      "They'll be permanently deleted from your phone. This can't be undone.";
  static String videosDeleted(int count) =>
      count == 1 ? 'Deleted 1 video' : 'Deleted $count videos';
  static const String videosNotDeleted = 'Nothing was deleted';
  static const String allVideos = 'All videos';
  static const String scanVideos = 'Scan for videos';
  static const String videosUpToDate = 'Your videos are up to date';
  static String newVideosFound(int count) =>
      count == 1 ? 'Found 1 new video' : 'Found $count new videos';
  static String videoLibraryUpdated(int added, int removed) => [
    if (added > 0) added == 1 ? '1 new video' : '$added new videos',
    if (removed > 0) removed == 1 ? '1 removed' : '$removed removed',
  ].join(' · ');
  static const String videoScanFailed = "Couldn't read your videos";
  static const String videoPermissionTitle = 'Allow access to your videos';
  static const String videoPermissionMessage =
      'Melodix needs access to the videos on your phone to show and play them.';
  static const String videoPermissionBlockedMessage =
      'Access was turned off. Allow it in the app settings to see your videos.';
  static const String videoMissing = 'This video is no longer on your phone';
  static const String videoUnplayable = "This video can't be played";
  static const String nextVideo = 'Next video';
  static const String previousVideo = 'Previous video';
  static const String playbackSpeed = 'Playback speed';
  static const String rotateScreen = 'Rotate';
  static const String minimize = 'Minimize';
  static const String upNext = 'Up next';
  static const String nowPlayingVideo = 'Now playing';
  static const String fillScreen = 'Fill screen';
  static const String fitScreen = 'Fit to screen';
  static const String lockControls = 'Lock';
  static const String unlockControls = 'Unlock';
  static const String controlsLocked = 'Controls locked';
  static const String back10 = 'Back 10 seconds';
  static const String forward10 = 'Forward 10 seconds';
  static String videoPosition(int number, int count) => '$number of $count';
  static const String closeVideo = 'Close video';
  static const String replay = 'Replay';
  static String seekSeconds(int seconds) =>
      seconds > 0 ? '+${seconds}s' : '−${-seconds}s';
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
  static const String queueShort = 'Queue';
  static const String deleteFromPhone = 'Delete from phone';
  static String playsNext(int count) =>
      count == 1 ? 'Plays next' : '$count will play next';
  static String addedToQueue(int count) =>
      count == 1 ? 'Added to queue' : 'Added $count to queue';
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
  static const String albumNotFound = 'This album is no longer in your library';
  static const String artistNotFound =
      'This artist is no longer in your library';
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
  static const String playlistsLoadFailed = 'Could not load your playlists';
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
  static const String changeNotSaved = "Couldn't save your change";

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
  static const String turnShuffleOn = 'Turn shuffle on';
  static const String turnShuffleOff = 'Turn shuffle off';
  static const String unknownSong = 'Unknown song';
  static const String cantPlaySong = "Can't play this song";

  // Library shortcuts (above the tabs)
  static const String favourites = 'Favourites';
  static const String recent = 'Recent';
  static const String recentlyPlayed = 'Recently played';
  static const String scan = 'Scan';
  static const String scanning = 'Scanning…';
  static String scanningPercent(int percent) => 'Scanning… $percent%';
  static const String scanDone = 'Done · 100%';
  static const String findNewMusic = 'Find new music';
  static const String lastPlayed = 'Your history';
  static const String libraryUpToDate = 'Your library is up to date';
  static String scanResult({required int added, required int removed}) => [
    if (added > 0) added == 1 ? 'Found 1 new song' : 'Found $added new songs',
    if (removed > 0) removed == 1 ? '1 song removed' : '$removed songs removed',
  ].join(' · ');

  // Favourites page
  static const String videos = 'Videos';
  static String videosCount(int count) =>
      count == 1 ? '1 video' : '$count videos';
  static const String noFavouriteVideosTitle = 'No favourite videos yet';
  static const String noFavouriteVideosSubtitle =
      'Tap ♥ on any video and it will be waiting for you here.';
  static String resumeAt(String time) => 'Resume at $time';
  static const String yourFavourites = 'Your favourites';
  static const String noFavouritesTitle = 'No favourites yet';
  static const String noFavouritesSubtitle =
      'Tap ♥ on any song and it will be waiting for you here.';
  static const String playAll = 'Play';
  static const String shufflePlay = 'Shuffle';

  // Recently played page
  static const String noRecentTitle = 'Nothing played yet';
  static const String noRecentSubtitle =
      'Songs you play show up here, newest first.';
  static const String clearHistory = 'Clear history';
  static const String clearHistoryConfirm =
      'Forget the songs you played recently? Play counts are kept.';
  static const String clear = 'Clear';
  static const String historyCleared = 'History cleared';
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
