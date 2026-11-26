import 'package:melodix/features/video/domain/repositories/video_media_repository.dart';

/// What the video player should open for a video (a `content://` URI on
/// Android: works under scoped storage, no copy of the file).
class GetVideoPlaybackUriUseCase {
  const GetVideoPlaybackUriUseCase(this.repository);

  final VideoMediaRepository repository;

  Future<Uri?> call(String videoId) => repository.playbackUri(videoId);
}
