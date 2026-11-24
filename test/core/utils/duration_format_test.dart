import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/utils/duration_format.dart';

void main() {
  test('formats minutes and seconds', () {
    expect(formatDuration(const Duration(seconds: 7)), '0:07');
    expect(formatDuration(const Duration(minutes: 3, seconds: 7)), '3:07');
  });

  test('includes hours when needed', () {
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 5)),
      '1:02:05',
    );
  });
}
