// The app's texts, typed: `context.l10n.songs`, `context.l10n.songsCount(3)`.
//
// Backed by easy_localization: the words live in assets/translations
// (en.json, ar.json); each member here reads its key in the language in
// use. A typo in a member's name doesn't compile (a raw `'songs'.tr()`
// would only show the key at runtime).
//
// Adding a text: put it in both JSON files, then add its member here and
// its key to [AppLocalizations.keys] (a test checks they all match).
// Plurals ({"one": …, "other": …}) take the count as `{}`; other values
// are named: `{name}`.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations();

  /// The languages the app speaks (English is the fallback).
  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  /// Every key, as in the JSON files.
  static const List<String> keys = [
    'appName',
    'onboardingSkip',
    'onboardingNext',
    'onboardingStart',
    'onboardingMusicTitle',
    'onboardingMusicBody',
    'onboardingVideoTitle',
    'onboardingVideoBody',
    'onboardingSubtitlesTitle',
    'onboardingSubtitlesBody',
    'onboardingThemeTitle',
    'onboardingThemeBody',
    'onboardingAuto',
    'onboardingOffline',
    'onboardingCaption1',
    'onboardingCaption2',
    'onboardingCaption3',
    'music',
    'video',
    'settings',
    'continueWatching',
    'selectVideos',
    'layout',
    'theme',
    'themeLight',
    'themeDark',
    'themeSystem',
    'accentColour',
    'selectionBarHint',
    'miniPlayerStyle',
    'miniPlayerClassic',
    'miniPlayerClassicHint',
    'miniPlayerCapsule',
    'miniPlayerCapsuleHint',
    'miniPlayerMinimal',
    'miniPlayerMinimalHint',
    'selectionBarStyle',
    'selectionBarBottom',
    'selectionBarSide',
    'videoOptions',
    'deleteVideosMessage',
    'videosNotDeleted',
    'allVideos',
    'scanVideos',
    'videosUpToDate',
    'videoScanFailed',
    'videoPermissionTitle',
    'videoPermissionMessage',
    'videoPermissionBlockedMessage',
    'videoMissing',
    'videoUnplayable',
    'nextVideo',
    'previousVideo',
    'playbackSpeed',
    'rotateScreen',
    'minimize',
    'upNext',
    'nowPlayingVideo',
    'fillScreen',
    'fitScreen',
    'lockControls',
    'unlockControls',
    'controlsLocked',
    'videoSettings',
    'subtitles',
    'subtitlesOff',
    'subtitlesNone',
    'subtitlesAddFromDevice',
    'subtitlesAddFromDeviceHint',
    'subtitlesSearchOnline',
    'subtitlesSearchOnlineHint',
    'subtitlesSearchHint',
    'subtitlesSearch',
    'subtitlesAnyLanguage',
    'subtitlesNoResults',
    'subtitlesDownload',
    'subtitlesSaved',
    'subtitlesFitsFile',
    'subtitlesHearingImpaired',
    'subtitlesTryAgain',
    'subtitlesFromDevice',
    'subtitlesImported',
    'subtitlesDownloaded',
    'mediaVideoSubtitle',
    'listenAsAudio',
    'playAsAudio',
    'watchVideo',
    'audioOnlyMode',
    'mediaVideoAudioSubtitle',
    'mediaRewind',
    'mediaForward',
    'videoSkip',
    'videoSkipHint',
    'closeVideo',
    'replay',
    'noVideosTitle',
    'noVideosSubtitle',
    'appearance',
    'settingsTagline',
    'settingsFooter',
    'lyrics',
    'showLyrics',
    'showCover',
    'lyricsSearching',
    'lyricsNone',
    'lyricsNotFound',
    'lyricsFailed',
    'lyricsSearchOnline',
    'lyricsSearchHint',
    'lyricsFromFile',
    'lyricsFromLrc',
    'lyricsFromOnline',
    'lyricsRemove',
    'sleepTimer',
    'sleepTimerHint',
    'sleepTimerEndOfSong',
    'sleepTimerOff',
    'sleepTimerAddFive',
    'sleepTimerStopsAtEnd',
    'playback',
    'speed',
    'speedHint',
    'skipSilence',
    'skipSilenceHint',
    'equalizer',
    'equalizerHint',
    'equalizerOn',
    'equalizerUnsupported',
    'equalizerPresets',
    'equalizerBars',
    'coverColours',
    'coverColoursHint',
    'nowPlayingBackground',
    'backgroundPlain',
    'backgroundCover',
    'backgroundGlow',
    'subtitleStyle',
    'subtitleSize',
    'subtitleLook',
    'subtitleColour',
    'subtitleSmall',
    'subtitleMedium',
    'subtitleLarge',
    'subtitleHuge',
    'subtitleBox',
    'subtitleOutline',
    'subtitleWhite',
    'subtitleYellow',
    'subtitleAccent',
    'subtitlePreview',
    'yourMelodix',
    'yourMelodixHint',
    'statsListened',
    'statsPlays',
    'statsSongs',
    'statsFavourites',
    'statsTopSongs',
    'statsTopArtists',
    'statsEmpty',
    'statsTopArtistLabel',
    'libraryFilters',
    'libraryFiltersHint',
    'minimumLength',
    'minimumLengthHint',
    'folders',
    'foldersHint',
    'noFolders',
    'appIcon',
    'appIconHint',
    'appIconClassic',
    'appIconChanged',
    'appIconFailed',
    'systemModeText',
    'songs',
    'albums',
    'artists',
    'artist',
    'allowMusicAccessTitle',
    'allowMusicAccessSubtitle',
    'musicAccessBlockedSubtitle',
    'allowAccess',
    'openSettings',
    'scanningLibraryTitle',
    'scanningLibrarySubtitle',
    'noMusicTitle',
    'noMusicSubtitle',
    'libraryErrorTitle',
    'tryAgain',
    'noAlbums',
    'noArtists',
    'songOptions',
    'playNext',
    'addToQueue',
    'queueShort',
    'deleteFromPhone',
    'addToFavourites',
    'removeFromFavourites',
    'addToPlaylist',
    'goToAlbum',
    'goToArtist',
    'addedToFavourites',
    'removedFromFavourites',
    'albumNotFound',
    'artistNotFound',
    'undo',
    'newPlaylist',
    'playlistName',
    'playlistNameRequired',
    'create',
    'cancel',
    'noPlaylistsYet',
    'library',
    'playlists',
    'playlist',
    'playlistOptions',
    'createPlaylistHint',
    'rename',
    'renamePlaylist',
    'save',
    'delete',
    'deletePlaylist',
    'playlistDeleted',
    'playlistsLoadFailed',
    'playlistRenamed',
    'playlistAddedToFavourites',
    'playlistRemovedFromFavourites',
    'removeFromPlaylist',
    'emptyPlaylistTitle',
    'emptyPlaylistSubtitle',
    'newPlaylistSubtitle',
    'renamePlaylistSubtitle',
    'playlistNameHint',
    'clearName',
    'dragToReorder',
    'reorderFailed',
    'changeNotSaved',
    'search',
    'closeSearch',
    'searchHint',
    'searchPromptTitle',
    'searchPromptSubtitle',
    'noResultsSubtitle',
    'recentSearches',
    'openedFromSearch',
    'clearSearchHistory',
    'removeRecentSearch',
    'sortBy',
    'recentlyAdded',
    'aToZ',
    'mostPlayed',
    'selectSongs',
    'cancelSelection',
    'selectAll',
    'deselectAll',
    'playlistShort',
    'favourite',
    'unfavourite',
    'nothingDeleted',
    'deleteSongsMessage',
    'play',
    'pause',
    'next',
    'previous',
    'shuffle',
    'turnShuffleOn',
    'turnShuffleOff',
    'unknownSong',
    'cantPlaySong',
    'favourites',
    'recent',
    'recentlyPlayed',
    'scan',
    'scanning',
    'scanDone',
    'findNewMusic',
    'lastPlayed',
    'libraryUpToDate',
    'videos',
    'noFavouriteVideosTitle',
    'noFavouriteVideosSubtitle',
    'yourFavourites',
    'noFavouritesTitle',
    'noFavouritesSubtitle',
    'playAll',
    'shufflePlay',
    'noRecentTitle',
    'noRecentSubtitle',
    'clearHistory',
    'clearHistoryConfirm',
    'clear',
    'historyCleared',
    'repeatOff',
    'repeatAll',
    'repeatOne',
    'openPlayer',
    'closePlayer',
    'nowPlaying',
    'secondsShort',
    'queue',
    'openQueue',
    'playingFrom',
    'searchResults',
    'language',
    'languageSystem',
    'languageSystemNow',
    'languageEnglish',
    'languageArabic',
    'anyLength',
    'playlistSuggestionChill',
    'playlistSuggestionWorkout',
    'playlistSuggestionRoadTrip',
    'playlistSuggestionFocus',
    'playlistSuggestionLateNight',
    'errorLibrarySync',
    'errorLibraryRead',
    'errorWrite',
    'errorSongsDelete',
    'errorLibraryPermission',
    'errorVideosSync',
    'errorVideosDelete',
    'errorVideosPermission',
    'deleteVideosTitle',
    'videosDeleted',
    'newVideosFound',
    'videosAdded',
    'videosRemoved',
    'backSeconds',
    'forwardSeconds',
    'subtitlesRetryIn',
    'subtitlesQuotaResets',
    'subtitlesDownloads',
    'subtitlesDownloadsLeft',
    'videoPosition',
    'secondsValue',
    'minutesValue',
    'hoursValue',
    'hoursMinutesValue',
    'seekForward',
    'seekBack',
    'sleepTimerLeft',
    'statsTimes',
    'folderSongs',
    'appIconNamed',
    'songsCount',
    'albumsCount',
    'playsNext',
    'addedToQueue',
    'addedToPlaylist',
    'alreadyInPlaylist',
    'playlistCreated',
    'removedFromPlaylist',
    'deletePlaylistConfirm',
    'noResultsFor',
    'showAll',
    'playsCount',
    'selectedCount',
    'addedSongsToFavourites',
    'removedSongsFromFavourites',
    'addedSongsToPlaylist',
    'deletedSongs',
    'deleteSongsTitle',
    'scanningPercent',
    'scanFoundSongs',
    'scanRemovedSongs',
    'videosCount',
    'resumeAt',
    'timeLeft',
  ];

  String get appName => tr('appName');
  String get onboardingSkip => tr('onboardingSkip');
  String get onboardingNext => tr('onboardingNext');
  String get onboardingStart => tr('onboardingStart');
  String get onboardingMusicTitle => tr('onboardingMusicTitle');
  String get onboardingMusicBody => tr('onboardingMusicBody');
  String get onboardingVideoTitle => tr('onboardingVideoTitle');
  String get onboardingVideoBody => tr('onboardingVideoBody');
  String get onboardingSubtitlesTitle => tr('onboardingSubtitlesTitle');
  String get onboardingSubtitlesBody => tr('onboardingSubtitlesBody');
  String get onboardingThemeTitle => tr('onboardingThemeTitle');
  String get onboardingThemeBody => tr('onboardingThemeBody');
  String get onboardingAuto => tr('onboardingAuto');
  String get onboardingOffline => tr('onboardingOffline');
  String get onboardingCaption1 => tr('onboardingCaption1');
  String get onboardingCaption2 => tr('onboardingCaption2');
  String get onboardingCaption3 => tr('onboardingCaption3');
  String get music => tr('music');
  String get video => tr('video');
  String get settings => tr('settings');
  String get continueWatching => tr('continueWatching');
  String get selectVideos => tr('selectVideos');
  String get layout => tr('layout');
  String get theme => tr('theme');
  String get themeLight => tr('themeLight');
  String get themeDark => tr('themeDark');
  String get themeSystem => tr('themeSystem');
  String get accentColour => tr('accentColour');
  String get selectionBarHint => tr('selectionBarHint');
  String get miniPlayerStyle => tr('miniPlayerStyle');
  String get miniPlayerClassic => tr('miniPlayerClassic');
  String get miniPlayerClassicHint => tr('miniPlayerClassicHint');
  String get miniPlayerCapsule => tr('miniPlayerCapsule');
  String get miniPlayerCapsuleHint => tr('miniPlayerCapsuleHint');
  String get miniPlayerMinimal => tr('miniPlayerMinimal');
  String get miniPlayerMinimalHint => tr('miniPlayerMinimalHint');
  String get selectionBarStyle => tr('selectionBarStyle');
  String get selectionBarBottom => tr('selectionBarBottom');
  String get selectionBarSide => tr('selectionBarSide');
  String get videoOptions => tr('videoOptions');
  String get deleteVideosMessage => tr('deleteVideosMessage');
  String get videosNotDeleted => tr('videosNotDeleted');
  String get allVideos => tr('allVideos');
  String get scanVideos => tr('scanVideos');
  String get videosUpToDate => tr('videosUpToDate');
  String get videoScanFailed => tr('videoScanFailed');
  String get videoPermissionTitle => tr('videoPermissionTitle');
  String get videoPermissionMessage => tr('videoPermissionMessage');
  String get videoPermissionBlockedMessage =>
      tr('videoPermissionBlockedMessage');
  String get videoMissing => tr('videoMissing');
  String get videoUnplayable => tr('videoUnplayable');
  String get nextVideo => tr('nextVideo');
  String get previousVideo => tr('previousVideo');
  String get playbackSpeed => tr('playbackSpeed');
  String get rotateScreen => tr('rotateScreen');
  String get minimize => tr('minimize');
  String get upNext => tr('upNext');
  String get nowPlayingVideo => tr('nowPlayingVideo');
  String get fillScreen => tr('fillScreen');
  String get fitScreen => tr('fitScreen');
  String get lockControls => tr('lockControls');
  String get unlockControls => tr('unlockControls');
  String get controlsLocked => tr('controlsLocked');
  String get videoSettings => tr('videoSettings');
  String get subtitles => tr('subtitles');
  String get subtitlesOff => tr('subtitlesOff');
  String get subtitlesNone => tr('subtitlesNone');
  String get subtitlesAddFromDevice => tr('subtitlesAddFromDevice');
  String get subtitlesAddFromDeviceHint => tr('subtitlesAddFromDeviceHint');
  String get subtitlesSearchOnline => tr('subtitlesSearchOnline');
  String get subtitlesSearchOnlineHint => tr('subtitlesSearchOnlineHint');
  String get subtitlesSearchHint => tr('subtitlesSearchHint');
  String get subtitlesSearch => tr('subtitlesSearch');
  String get subtitlesAnyLanguage => tr('subtitlesAnyLanguage');
  String get subtitlesNoResults => tr('subtitlesNoResults');
  String get subtitlesDownload => tr('subtitlesDownload');
  String get subtitlesSaved => tr('subtitlesSaved');
  String get subtitlesFitsFile => tr('subtitlesFitsFile');
  String get subtitlesHearingImpaired => tr('subtitlesHearingImpaired');
  String get subtitlesTryAgain => tr('subtitlesTryAgain');
  String get subtitlesFromDevice => tr('subtitlesFromDevice');
  String get subtitlesImported => tr('subtitlesImported');
  String get subtitlesDownloaded => tr('subtitlesDownloaded');
  String get mediaVideoSubtitle => tr('mediaVideoSubtitle');
  String get listenAsAudio => tr('listenAsAudio');
  String get playAsAudio => tr('playAsAudio');
  String get watchVideo => tr('watchVideo');
  String get audioOnlyMode => tr('audioOnlyMode');
  String get mediaVideoAudioSubtitle => tr('mediaVideoAudioSubtitle');
  String get mediaRewind => tr('mediaRewind');
  String get mediaForward => tr('mediaForward');
  String get videoSkip => tr('videoSkip');
  String get videoSkipHint => tr('videoSkipHint');
  String get closeVideo => tr('closeVideo');
  String get replay => tr('replay');
  String get noVideosTitle => tr('noVideosTitle');
  String get noVideosSubtitle => tr('noVideosSubtitle');
  String get appearance => tr('appearance');
  String get settingsTagline => tr('settingsTagline');
  String get settingsFooter => tr('settingsFooter');
  String get lyrics => tr('lyrics');
  String get showLyrics => tr('showLyrics');
  String get showCover => tr('showCover');
  String get lyricsSearching => tr('lyricsSearching');
  String get lyricsNone => tr('lyricsNone');
  String get lyricsNotFound => tr('lyricsNotFound');
  String get lyricsFailed => tr('lyricsFailed');
  String get lyricsSearchOnline => tr('lyricsSearchOnline');
  String get lyricsSearchHint => tr('lyricsSearchHint');
  String get lyricsFromFile => tr('lyricsFromFile');
  String get lyricsFromLrc => tr('lyricsFromLrc');
  String get lyricsFromOnline => tr('lyricsFromOnline');
  String get lyricsRemove => tr('lyricsRemove');
  String get sleepTimer => tr('sleepTimer');
  String get sleepTimerHint => tr('sleepTimerHint');
  String get sleepTimerEndOfSong => tr('sleepTimerEndOfSong');
  String get sleepTimerOff => tr('sleepTimerOff');
  String get sleepTimerAddFive => tr('sleepTimerAddFive');
  String get sleepTimerStopsAtEnd => tr('sleepTimerStopsAtEnd');
  String get playback => tr('playback');
  String get speed => tr('speed');
  String get speedHint => tr('speedHint');
  String get skipSilence => tr('skipSilence');
  String get skipSilenceHint => tr('skipSilenceHint');
  String get equalizer => tr('equalizer');
  String get equalizerHint => tr('equalizerHint');
  String get equalizerOn => tr('equalizerOn');
  String get equalizerUnsupported => tr('equalizerUnsupported');
  String get equalizerPresets => tr('equalizerPresets');
  String get equalizerBars => tr('equalizerBars');
  String get coverColours => tr('coverColours');
  String get coverColoursHint => tr('coverColoursHint');
  String get nowPlayingBackground => tr('nowPlayingBackground');
  String get backgroundPlain => tr('backgroundPlain');
  String get backgroundCover => tr('backgroundCover');
  String get backgroundGlow => tr('backgroundGlow');
  String get subtitleStyle => tr('subtitleStyle');
  String get subtitleSize => tr('subtitleSize');
  String get subtitleLook => tr('subtitleLook');
  String get subtitleColour => tr('subtitleColour');
  String get subtitleSmall => tr('subtitleSmall');
  String get subtitleMedium => tr('subtitleMedium');
  String get subtitleLarge => tr('subtitleLarge');
  String get subtitleHuge => tr('subtitleHuge');
  String get subtitleBox => tr('subtitleBox');
  String get subtitleOutline => tr('subtitleOutline');
  String get subtitleWhite => tr('subtitleWhite');
  String get subtitleYellow => tr('subtitleYellow');
  String get subtitleAccent => tr('subtitleAccent');
  String get subtitlePreview => tr('subtitlePreview');
  String get yourMelodix => tr('yourMelodix');
  String get yourMelodixHint => tr('yourMelodixHint');
  String get statsListened => tr('statsListened');
  String get statsPlays => tr('statsPlays');
  String get statsSongs => tr('statsSongs');
  String get statsFavourites => tr('statsFavourites');
  String get statsTopSongs => tr('statsTopSongs');
  String get statsTopArtists => tr('statsTopArtists');
  String get statsEmpty => tr('statsEmpty');
  String get statsTopArtistLabel => tr('statsTopArtistLabel');
  String get libraryFilters => tr('libraryFilters');
  String get libraryFiltersHint => tr('libraryFiltersHint');
  String get minimumLength => tr('minimumLength');
  String get minimumLengthHint => tr('minimumLengthHint');
  String get folders => tr('folders');
  String get foldersHint => tr('foldersHint');
  String get noFolders => tr('noFolders');
  String get appIcon => tr('appIcon');
  String get appIconHint => tr('appIconHint');
  String get appIconClassic => tr('appIconClassic');
  String get appIconChanged => tr('appIconChanged');
  String get appIconFailed => tr('appIconFailed');
  String get systemModeText => tr('systemModeText');
  String get songs => tr('songs');
  String get albums => tr('albums');
  String get artists => tr('artists');
  String get artist => tr('artist');
  String get allowMusicAccessTitle => tr('allowMusicAccessTitle');
  String get allowMusicAccessSubtitle => tr('allowMusicAccessSubtitle');
  String get musicAccessBlockedSubtitle => tr('musicAccessBlockedSubtitle');
  String get allowAccess => tr('allowAccess');
  String get openSettings => tr('openSettings');
  String get scanningLibraryTitle => tr('scanningLibraryTitle');
  String get scanningLibrarySubtitle => tr('scanningLibrarySubtitle');
  String get noMusicTitle => tr('noMusicTitle');
  String get noMusicSubtitle => tr('noMusicSubtitle');
  String get libraryErrorTitle => tr('libraryErrorTitle');
  String get tryAgain => tr('tryAgain');
  String get noAlbums => tr('noAlbums');
  String get noArtists => tr('noArtists');
  String get songOptions => tr('songOptions');
  String get playNext => tr('playNext');
  String get addToQueue => tr('addToQueue');
  String get queueShort => tr('queueShort');
  String get deleteFromPhone => tr('deleteFromPhone');
  String get addToFavourites => tr('addToFavourites');
  String get removeFromFavourites => tr('removeFromFavourites');
  String get addToPlaylist => tr('addToPlaylist');
  String get goToAlbum => tr('goToAlbum');
  String get goToArtist => tr('goToArtist');
  String get addedToFavourites => tr('addedToFavourites');
  String get removedFromFavourites => tr('removedFromFavourites');
  String get albumNotFound => tr('albumNotFound');
  String get artistNotFound => tr('artistNotFound');
  String get undo => tr('undo');
  String get newPlaylist => tr('newPlaylist');
  String get playlistName => tr('playlistName');
  String get playlistNameRequired => tr('playlistNameRequired');
  String get create => tr('create');
  String get cancel => tr('cancel');
  String get noPlaylistsYet => tr('noPlaylistsYet');
  String get library => tr('library');
  String get playlists => tr('playlists');
  String get playlist => tr('playlist');
  String get playlistOptions => tr('playlistOptions');
  String get createPlaylistHint => tr('createPlaylistHint');
  String get rename => tr('rename');
  String get renamePlaylist => tr('renamePlaylist');
  String get save => tr('save');
  String get delete => tr('delete');
  String get deletePlaylist => tr('deletePlaylist');
  String get playlistDeleted => tr('playlistDeleted');
  String get playlistsLoadFailed => tr('playlistsLoadFailed');
  String get playlistRenamed => tr('playlistRenamed');
  String get playlistAddedToFavourites => tr('playlistAddedToFavourites');
  String get playlistRemovedFromFavourites =>
      tr('playlistRemovedFromFavourites');
  String get removeFromPlaylist => tr('removeFromPlaylist');
  String get emptyPlaylistTitle => tr('emptyPlaylistTitle');
  String get emptyPlaylistSubtitle => tr('emptyPlaylistSubtitle');
  String get newPlaylistSubtitle => tr('newPlaylistSubtitle');
  String get renamePlaylistSubtitle => tr('renamePlaylistSubtitle');
  String get playlistNameHint => tr('playlistNameHint');
  String get clearName => tr('clearName');
  String get dragToReorder => tr('dragToReorder');
  String get reorderFailed => tr('reorderFailed');
  String get changeNotSaved => tr('changeNotSaved');
  String get search => tr('search');
  String get closeSearch => tr('closeSearch');
  String get searchHint => tr('searchHint');
  String get searchPromptTitle => tr('searchPromptTitle');
  String get searchPromptSubtitle => tr('searchPromptSubtitle');
  String get noResultsSubtitle => tr('noResultsSubtitle');
  String get recentSearches => tr('recentSearches');
  String get openedFromSearch => tr('openedFromSearch');
  String get clearSearchHistory => tr('clearSearchHistory');
  String get removeRecentSearch => tr('removeRecentSearch');
  String get sortBy => tr('sortBy');
  String get recentlyAdded => tr('recentlyAdded');
  String get aToZ => tr('aToZ');
  String get mostPlayed => tr('mostPlayed');
  String get selectSongs => tr('selectSongs');
  String get cancelSelection => tr('cancelSelection');
  String get selectAll => tr('selectAll');
  String get deselectAll => tr('deselectAll');
  String get playlistShort => tr('playlistShort');
  String get favourite => tr('favourite');
  String get unfavourite => tr('unfavourite');
  String get nothingDeleted => tr('nothingDeleted');
  String get deleteSongsMessage => tr('deleteSongsMessage');
  String get play => tr('play');
  String get pause => tr('pause');
  String get next => tr('next');
  String get previous => tr('previous');
  String get shuffle => tr('shuffle');
  String get turnShuffleOn => tr('turnShuffleOn');
  String get turnShuffleOff => tr('turnShuffleOff');
  String get unknownSong => tr('unknownSong');
  String get cantPlaySong => tr('cantPlaySong');
  String get favourites => tr('favourites');
  String get recent => tr('recent');
  String get recentlyPlayed => tr('recentlyPlayed');
  String get scan => tr('scan');
  String get scanning => tr('scanning');
  String get scanDone => tr('scanDone');
  String get findNewMusic => tr('findNewMusic');
  String get lastPlayed => tr('lastPlayed');
  String get libraryUpToDate => tr('libraryUpToDate');
  String get videos => tr('videos');
  String get noFavouriteVideosTitle => tr('noFavouriteVideosTitle');
  String get noFavouriteVideosSubtitle => tr('noFavouriteVideosSubtitle');
  String get yourFavourites => tr('yourFavourites');
  String get noFavouritesTitle => tr('noFavouritesTitle');
  String get noFavouritesSubtitle => tr('noFavouritesSubtitle');
  String get playAll => tr('playAll');
  String get shufflePlay => tr('shufflePlay');
  String get noRecentTitle => tr('noRecentTitle');
  String get noRecentSubtitle => tr('noRecentSubtitle');
  String get clearHistory => tr('clearHistory');
  String get clearHistoryConfirm => tr('clearHistoryConfirm');
  String get clear => tr('clear');
  String get historyCleared => tr('historyCleared');
  String get repeatOff => tr('repeatOff');
  String get repeatAll => tr('repeatAll');
  String get repeatOne => tr('repeatOne');
  String get openPlayer => tr('openPlayer');
  String get closePlayer => tr('closePlayer');
  String get nowPlaying => tr('nowPlaying');
  String get secondsShort => tr('secondsShort');
  String get queue => tr('queue');
  String get openQueue => tr('openQueue');
  String get playingFrom => tr('playingFrom');
  String get searchResults => tr('searchResults');
  String get language => tr('language');
  String get languageSystem => tr('languageSystem');
  String languageSystemNow(String language) =>
      tr('languageSystemNow', namedArgs: {'language': language});
  String get languageEnglish => tr('languageEnglish');
  String get languageArabic => tr('languageArabic');
  String get anyLength => tr('anyLength');
  String get playlistSuggestionChill => tr('playlistSuggestionChill');
  String get playlistSuggestionWorkout => tr('playlistSuggestionWorkout');
  String get playlistSuggestionRoadTrip => tr('playlistSuggestionRoadTrip');
  String get playlistSuggestionFocus => tr('playlistSuggestionFocus');
  String get playlistSuggestionLateNight => tr('playlistSuggestionLateNight');
  String get errorLibrarySync => tr('errorLibrarySync');
  String get errorLibraryRead => tr('errorLibraryRead');
  String get errorWrite => tr('errorWrite');
  String get errorSongsDelete => tr('errorSongsDelete');
  String get errorLibraryPermission => tr('errorLibraryPermission');
  String get errorVideosSync => tr('errorVideosSync');
  String get errorVideosDelete => tr('errorVideosDelete');
  String get errorVideosPermission => tr('errorVideosPermission');
  String deleteVideosTitle(int count) => plural('deleteVideosTitle', count);
  String videosDeleted(int count) => plural('videosDeleted', count);
  String newVideosFound(int count) => plural('newVideosFound', count);
  String videosAdded(int count) => plural('videosAdded', count);
  String videosRemoved(int count) => plural('videosRemoved', count);
  String backSeconds(int seconds) => plural('backSeconds', seconds);
  String forwardSeconds(int seconds) => plural('forwardSeconds', seconds);
  String subtitlesRetryIn(int seconds) =>
      tr('subtitlesRetryIn', namedArgs: {'seconds': '$seconds'});
  String subtitlesQuotaResets(String time) =>
      tr('subtitlesQuotaResets', namedArgs: {'time': time});
  String subtitlesDownloads(int count) => plural('subtitlesDownloads', count);
  String subtitlesDownloadsLeft(int count) =>
      plural('subtitlesDownloadsLeft', count);
  String videoPosition(int number, int count) =>
      tr('videoPosition', namedArgs: {'number': '$number', 'count': '$count'});
  String secondsValue(int seconds) =>
      tr('secondsValue', namedArgs: {'seconds': '$seconds'});
  String minutesValue(int minutes) =>
      tr('minutesValue', namedArgs: {'minutes': '$minutes'});
  String hoursValue(int hours) =>
      tr('hoursValue', namedArgs: {'hours': '$hours'});
  String hoursMinutesValue(int hours, int minutes) => tr(
    'hoursMinutesValue',
    namedArgs: {'hours': '$hours', 'minutes': '$minutes'},
  );
  String seekForward(int seconds) =>
      tr('seekForward', namedArgs: {'seconds': '$seconds'});
  String seekBack(int seconds) =>
      tr('seekBack', namedArgs: {'seconds': '$seconds'});
  String sleepTimerLeft(String time) =>
      tr('sleepTimerLeft', namedArgs: {'time': time});
  String statsTimes(int plays) => plural('statsTimes', plays);
  String folderSongs(int count) => plural('folderSongs', count);
  String appIconNamed(String name) =>
      tr('appIconNamed', namedArgs: {'name': name});
  String songsCount(int count) => plural('songsCount', count);
  String albumsCount(int count) => plural('albumsCount', count);
  String playsNext(int count) => plural('playsNext', count);
  String addedToQueue(int count) => plural('addedToQueue', count);
  String addedToPlaylist(String name) =>
      tr('addedToPlaylist', namedArgs: {'name': name});
  String alreadyInPlaylist(String name) =>
      tr('alreadyInPlaylist', namedArgs: {'name': name});
  String playlistCreated(String name) =>
      tr('playlistCreated', namedArgs: {'name': name});
  String removedFromPlaylist(String name) =>
      tr('removedFromPlaylist', namedArgs: {'name': name});
  String deletePlaylistConfirm(String name) =>
      tr('deletePlaylistConfirm', namedArgs: {'name': name});
  String noResultsFor(String query) =>
      tr('noResultsFor', namedArgs: {'query': query});
  String showAll(int count) => tr('showAll', namedArgs: {'count': '$count'});
  String playsCount(int count) => plural('playsCount', count);
  String selectedCount(int count) =>
      tr('selectedCount', namedArgs: {'count': '$count'});
  String addedSongsToFavourites(int count) =>
      plural('addedSongsToFavourites', count);
  String removedSongsFromFavourites(int count) =>
      plural('removedSongsFromFavourites', count);
  String addedSongsToPlaylist(int count, String name) =>
      plural('addedSongsToPlaylist', count, namedArgs: {'name': name});
  String deletedSongs(int count) => plural('deletedSongs', count);
  String deleteSongsTitle(int count) => plural('deleteSongsTitle', count);
  String scanningPercent(int percent) =>
      tr('scanningPercent', namedArgs: {'percent': '$percent'});
  String scanFoundSongs(int count) => plural('scanFoundSongs', count);
  String scanRemovedSongs(int count) => plural('scanRemovedSongs', count);
  String videosCount(int count) => plural('videosCount', count);
  String resumeAt(String time) => tr('resumeAt', namedArgs: {'time': time});
  String timeLeft(String time) => tr('timeLeft', namedArgs: {'time': time});
}
