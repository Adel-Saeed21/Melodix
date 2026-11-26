import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/video/domain/repositories/video_media_repository.dart';
import 'package:melodix/features/video/domain/usecases/get_video_thumbnail_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockMedia extends Mock implements VideoMediaRepository {}

void main() {
  test('screens asking for nearby sizes share one thumbnail', () {
    final media = MockMedia();
    when(() => media.thumbnail(any(), size: any(named: 'size')))
        .thenReturn(null);
    when(() => media.cachedThumbnail(any(), size: any(named: 'size')))
        .thenReturn(null);
    final thumbnails = GetVideoThumbnailUseCase(media);

    // A 104 dp sheet row and a 112 dp list row at 3x: 312 and 336 px.
    thumbnails('a', size: 312);
    thumbnails('a', size: 336);
    thumbnails.cached('a', size: 336);
    verify(() => media.thumbnail('a', size: 384)).called(2);
    verify(() => media.cachedThumbnail('a', size: 384)).called(1);
  });

  test('sizes round up, never past the largest', () {
    expect(GetVideoThumbnailUseCase.standardSize(64), 384);
    expect(GetVideoThumbnailUseCase.standardSize(384), 384);
    expect(GetVideoThumbnailUseCase.standardSize(385), 768);
    expect(GetVideoThumbnailUseCase.standardSize(528), 768); // 176 dp card
    expect(GetVideoThumbnailUseCase.standardSize(1024), 1024);
    expect(GetVideoThumbnailUseCase.standardSize(4000), 1024);
  });
}
