class AppStrings {
  AppStrings._();

  static const String appName = 'Melodix';

  // Onboarding
  static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingStart = 'Start listening';
  static const String onboardingMusicTitle =
      'All your music,\nbeautifully organised';
  static const String onboardingMusicBody =
      'Melodix finds the songs on your phone and sorts them into albums, '
      'artists and playlists. Favourites, shuffle, and controls right on '
      'your lock screen.';
  static const String onboardingVideoTitle = 'Videos that\nkeep up with you';
  static const String onboardingVideoBody =
      'Pick up where you left off, skip with a double-tap, and keep watching '
      'in a floating window while you use other apps.';
  static const String onboardingSubtitlesTitle = 'Subtitles,\neven offline';
  static const String onboardingSubtitlesBody =
      'Add .srt or .vtt files, or find them online once. They stay on your '
      'phone, ready without internet.';
  static const String onboardingThemeTitle = 'Choose your look';
  static const String onboardingThemeBody =
      'Dark, light, or follow your phone. You can change it any time in '
      'Settings.';
  static const String onboardingAuto = 'Auto';
  static const String onboardingOffline = 'Offline';
  static const String onboardingCaption1 = 'Hello, and welcome!';
  static const String onboardingCaption2 = 'Captions in your language';
  static const String onboardingCaption3 = 'Saved on your phone';

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
  static String backSeconds(int seconds) => 'Back $seconds seconds';
  static String forwardSeconds(int seconds) => 'Forward $seconds seconds';
  static const String videoSettings = 'Video player';

  // Subtitles
  static const String subtitles = 'Subtitles';
  static const String subtitlesOff = 'Off';
  static const String subtitlesNone =
      'No subtitles for this video yet. Add a file or search online.';
  static const String subtitlesAddFromDevice = 'Add from device';
  static const String subtitlesAddFromDeviceHint = 'An .srt or .vtt file';
  static const String subtitlesSearchOnline = 'Search online';
  static const String subtitlesSearchOnlineHint =
      'OpenSubtitles · kept for offline use';
  static const String subtitlesSearchHint = 'Name, file name or IMDb ID';
  static const String subtitlesSearch = 'Search';
  static const String subtitlesAnyLanguage = 'Any language';
  static const String subtitlesNoResults =
      'Nothing found. Try another name or language.';
  static const String subtitlesDownload = 'Download';
  static const String subtitlesSaved = 'Saved';
  static const String subtitlesFitsFile = 'Fits this file';
  static const String subtitlesHearingImpaired = 'SDH';
  static const String subtitlesTryAgain = 'Try again';
  static String subtitlesRetryIn(int seconds) => 'Try again in ${seconds}s.';
  static String subtitlesQuotaResets(String time) => 'Resets in $time.';
  static String subtitlesDownloads(int count) =>
      count == 1 ? '1 download' : '$count downloads';
  static const String subtitlesFromDevice = 'On this device';
  static const String subtitlesImported = 'Added';
  static const String subtitlesDownloaded = 'Downloaded';
  static String subtitlesDownloadsLeft(int count) =>
      count == 1 ? '1 download left today.' : '$count downloads left today.';
  // The video in the notification and on the lock screen.
  static const String mediaVideoSubtitle = 'Video · Melodix';
  static const String mediaRewind = 'Back';
  static const String mediaForward = 'Forward';
  static const String videoSkip = 'Skip length';
  static const String videoSkipHint =
      'How far the skip buttons and double-taps jump';
  static String videoSkipSeconds(int seconds) => '${seconds}s';
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
  static const String settingsTagline = 'Make Melodix yours';
  static const String settingsFooter = 'Your music, your way';

  // Lyrics
  static const String lyrics = 'Lyrics';
  static const String showLyrics = 'Show lyrics';
  static const String showCover = 'Show cover';
  static const String lyricsSearching = 'Looking for lyrics online…';
  static const String lyricsNone = 'No lyrics on your phone for this song';
  static const String lyricsNotFound = 'No lyrics found online either';
  static const String lyricsFailed =
      "Couldn't reach the lyrics service. Check your connection.";
  static const String lyricsSearchOnline = 'Search online';
  static const String lyricsSearchHint =
      "Sends the song's title and artist to LRCLIB. Lyrics found are kept "
      'on your phone.';
  static const String lyricsFromFile = 'Lyrics from the song file';
  static const String lyricsFromLrc = 'Lyrics from an .lrc file';
  static const String lyricsFromOnline = 'Lyrics from LRCLIB';
  static const String lyricsRemove = 'Wrong song? Remove';

  // Sleep timer
  static const String sleepTimer = 'Sleep timer';
  static const String sleepTimerHint = 'The music fades out, then stops';
  static const String sleepTimerEndOfSong = 'End of song';
  static const String sleepTimerOff = 'Turn off';
  static const String sleepTimerAddFive = '+5 min';
  static const String sleepTimerStopsAtEnd = 'Stops when this song ends';
  static String sleepTimerMinutes(int minutes) =>
      minutes >= 60 && minutes % 60 == 0
      ? '${minutes ~/ 60} h'
      : minutes > 60
      ? '${minutes ~/ 60} h ${minutes % 60} min'
      : '$minutes min';
  static String sleepTimerLeft(String time) => 'Stops in $time';

  // Playback
  static const String playback = 'Playback';
  static const String speed = 'Speed';
  static const String speedHint = 'Faster or slower, same pitch';
  static String speedValue(double speed) =>
      '${speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 2).replaceFirst(RegExp(r'0$'), '')}×';
  static const String skipSilence = 'Skip silence';
  static const String skipSilenceHint =
      'Jumps over quiet gaps (great for talks and audiobooks)';

  // Equalizer
  static const String equalizer = 'Equalizer';
  static const String equalizerHint = 'Shape the sound with presets or bars';
  static const String equalizerOn = 'Equalizer on';
  static const String equalizerUnsupported =
      "This phone doesn't offer an equalizer to apps.";
  static const String equalizerPresets = 'Presets';
  static const String equalizerBars = 'Drag a bar to make your own';
  static String bandLabel(double hz) => hz >= 1000
      ? '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k'
      : '${hz.round()}';

  // Cover colours
  static const String coverColours = 'From the cover';
  static const String coverColoursHint =
      "The playing song's cover colours the app";

  // Now Playing background
  static const String nowPlayingBackground = 'Now Playing background';
  static const String backgroundPlain = 'Plain';
  static const String backgroundCover = 'Cover';
  static const String backgroundGlow = 'Glow';

  // Subtitle style
  static const String subtitleStyle = 'Subtitles';
  static const String subtitleSize = 'Size';
  static const String subtitleLook = 'Style';
  static const String subtitleColour = 'Colour';
  static const String subtitleSmall = 'Small';
  static const String subtitleMedium = 'Medium';
  static const String subtitleLarge = 'Large';
  static const String subtitleHuge = 'Huge';
  static const String subtitleBox = 'Box';
  static const String subtitleOutline = 'Outline';
  static const String subtitleWhite = 'White';
  static const String subtitleYellow = 'Yellow';
  static const String subtitleAccent = 'Accent';
  static const String subtitlePreview = 'This is how captions look';

  // Listening stats
  static const String yourMelodix = 'Your Melodix';
  static const String yourMelodixHint = 'Your top songs, artists and hours';
  static const String statsListened = 'Listened';
  static const String statsPlays = 'Plays';
  static const String statsSongs = 'Songs';
  static const String statsFavourites = 'Favourites';
  static const String statsTopSongs = 'Top songs';
  static const String statsTopArtists = 'Top artists';
  static const String statsEmpty =
      'Play some music and your stats show up here.';
  static String statsHours(int hours, int minutes) =>
      hours > 0 ? '$hours h $minutes min' : '$minutes min';
  static String statsTimes(int plays) => plays == 1 ? '1 play' : '$plays plays';
  static const String statsTopArtistLabel = 'Your top artist';

  // Library filters
  static const String libraryFilters = 'Music filters';
  static const String libraryFiltersHint = 'Hide short clips and folders';
  static const String minimumLength = 'Shortest song';
  static const String minimumLengthHint =
      'Shorter files (voice notes, clips) stay out of the library';
  static String minimumLengthValue(int seconds) => seconds == 0
      ? 'Any'
      : seconds < 60
      ? '${seconds}s'
      : '${seconds ~/ 60} min';
  static const String folders = 'Folders';
  static const String foldersHint =
      'Turn a folder off to keep its songs out of the library. Nothing is '
      'deleted: turn it back on and they return, playlists and plays '
      'included.';
  static const String noFolders = 'No music folders found yet.';
  static String folderSongs(int count) =>
      count == 1 ? '1 song' : '$count songs';

  // App icon
  static const String appIcon = 'App icon';
  static const String appIconHint = 'Your home screen icon';
  static const String appIconClassic = 'Classic';
  static String appIconNamed(String name) => '$name icon';
  static const String appIconChanged =
      'Icon changed. Your home screen may take a moment to update.';
  static const String appIconFailed = "This phone didn't allow the change";
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
  static const String addedToFavourites = 'Added to favourites';
  static const String removedFromFavourites = 'Removed from favourites';
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

  // Library
  static const String library = 'Library';

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
  static const String recentSearches = 'Recent searches';
  static const String openedFromSearch = 'Opened from search';
  static const String clearSearchHistory = 'Clear';
  static const String removeRecentSearch = 'Remove';

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
  static const String nothingDeleted = 'No songs were deleted';
  static const String deleteSongsMessage =
      "They'll be permanently deleted from your phone. This can't be undone.";

  static String selectedCount(int count) => '$count selected';
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
  static String timeLeft(String time) => '$time left';
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
