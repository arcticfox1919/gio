
import 'package:test/test.dart';
import 'package:gio/gio.dart' as gio;
import 'utils.dart';

void main() {
  group('contentLength', () {
    test('defaults to null', () {
      var request = gio.StreamedRequest('POST', dummyUrl);
      expect(request.contentLength, isNull);
    });

    test('disallows negative values', () {
      var request = gio.StreamedRequest('POST', dummyUrl);
      expect(() => request.contentLength = -1, throwsArgumentError);
    });

    test('is frozen by finalize()', () {
      var request = gio.StreamedRequest('POST', dummyUrl)..finalize();
      expect(() => request.contentLength = 10, throwsStateError);
    });
  });
  group('#method', () {
    test('must be a token', () {
      expect(() => gio.StreamedRequest('SUPER LLAMA', dummyUrl),
          throwsArgumentError);
    });
  });
}
