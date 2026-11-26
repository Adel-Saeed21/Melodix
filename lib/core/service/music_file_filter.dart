/// Decides which audio files on the device count as music.
///
/// Excludes voice / call recordings, voice notes, ringtones, alarms,
/// notification sounds, podcasts and audiobooks, so only songs reach the
/// library (and therefore playlists, favourites and recents).
class MusicFileFilter {
  MusicFileFilter._();

  /// Bump when the rules below change, so existing libraries are rescanned
  /// with the new rules (it's part of the library change signature).
  static const int rulesVersion = 1;

  /// Shorter files are clips or voice notes, not songs.
  static const Duration minimumDuration = Duration(seconds: 30);

  /// Folder names (lower-case, spaces/underscores/dashes removed) that hold
  /// recordings or system sounds rather than music.
  static const Set<String> excludedFolders = {
    'recordings',
    'recording',
    'recorder',
    'soundrecorder',
    'soundrecordings',
    'voicerecorder',
    'voicerecordings',
    'voicerecords',
    'record',
    'records',
    'callrecord',
    'callrecords',
    'callrecordings',
    'callrecorder',
    'call',
    'whatsappvoicenotes',
    'voicenotes',
    'ringtones',
    'alarms',
    'notifications',
    'podcasts',
    'audiobooks',
  };

  /// Formats used by voice / call recorders, not music.
  static const Set<String> excludedExtensions = {'amr', 'awb', '3gp', '3ga'};

  static bool isMusic({
    required String path,
    required int? durationMs,
    bool? isMusic,
    bool? isAlarm,
    bool? isNotification,
    bool? isRingtone,
    bool? isPodcast,
    bool? isAudioBook,
  }) {
    // The device's own classification. A missing flag (null) isn't a "no".
    if (isMusic == false) return false;
    if (isAlarm == true ||
        isNotification == true ||
        isRingtone == true ||
        isPodcast == true ||
        isAudioBook == true) {
      return false;
    }

    if ((durationMs ?? 0) < minimumDuration.inMilliseconds) return false;

    final lowerPath = path.toLowerCase();
    final dot = lowerPath.lastIndexOf('.');
    if (dot != -1 &&
        excludedExtensions.contains(lowerPath.substring(dot + 1))) {
      return false;
    }

    // Any folder in the path (not the file name itself).
    final segments = lowerPath.split('/');
    for (var i = 0; i < segments.length - 1; i++) {
      final folder = segments[i].replaceAll(RegExp(r'[\s_\-]'), '');
      if (excludedFolders.contains(folder)) return false;
    }
    return true;
  }
}
