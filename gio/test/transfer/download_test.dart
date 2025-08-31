import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:gio/gio.dart' as gio;

void main() {
  group('Download Interface Tests', () {
    late gio.Gio gioClient;

    setUp(() {
      gioClient = gio.Gio();
    });

    tearDown(() {
      gioClient.close();
    });

    group('downloadFile', () {
      test('should download small file successfully', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_small.bin');

        if (await testFile.exists()) {
          await testFile.delete();
        }

        try {
          final result = await gioClient.downloadFile(
            'https://httpbin.org/bytes/512',
            testFile.path,
          );

          expect(await result.exists(), isTrue);
          expect(await result.length(), equals(512));
        } finally {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('should download large file with progress tracking', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_large.bin');
        final progressUpdates = <gio.TransferProgress>[];

        if (await testFile.exists()) {
          await testFile.delete();
        }

        try {
          await gioClient.downloadFile(
            'https://httpbin.org/bytes/16384',
            testFile.path,
            onProgress: (progress) {
              progressUpdates.add(progress);
              print(
                  'Progress: ${progress.current}/${progress.total} (${(progress.percentage! * 100).toStringAsFixed(2)}%)');
            },
          );

          expect(await testFile.exists(), isTrue);
          expect(await testFile.length(), equals(16384));
          expect(progressUpdates.isNotEmpty, isTrue);
          expect(progressUpdates.last.isCompleted, isTrue);
          expect(progressUpdates.last.current, equals(16384));

          // Verify no duplicate progress values
          for (int i = 1; i < progressUpdates.length; i++) {
            final prev = progressUpdates[i - 1];
            final curr = progressUpdates[i];
            expect(curr.current >= prev.current, isTrue);
          }
        } finally {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('should handle custom headers in download', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_headers.json');

        if (await testFile.exists()) {
          await testFile.delete();
        }

        try {
          await gioClient.downloadFile(
            'https://httpbin.org/headers',
            testFile.path,
            headers: {
              'User-Agent': 'Gio-Download-Test',
              'X-Custom-Header': 'test-download',
            },
          );

          expect(await testFile.exists(), isTrue);
          final content = await testFile.readAsString();
          expect(content.contains('Gio-Download-Test'), isTrue);
          expect(content.contains('X-Custom-Header'), isTrue);
        } finally {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('should handle 404 error gracefully', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_404.bin');

        try {
          await gioClient.downloadFile(
              'https://httpbin.org/status/404', testFile.path);
          fail('Expected exception for 404 error');
        } catch (e) {
          expect(e, isA<Exception>());
        }

        // Clean up any created file
        if (await testFile.exists()) {
          await testFile.delete();
        }
      });
    });

    group('downloadBytes', () {
      test('should download small data into memory', () async {
        final bytes =
            await gioClient.downloadBytes('https://httpbin.org/bytes/256');

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(256));
      });

      test('should download with progress callback', () async {
        final progressUpdates = <gio.TransferProgress>[];

        final bytes = await gioClient.downloadBytes(
          'https://httpbin.org/bytes/2048',
          onProgress: (progress) {
            progressUpdates.add(progress);
            print('Memory download: ${progress.current}/${progress.total}');
          },
        );

        expect(bytes.length, equals(2048));
        expect(progressUpdates.isNotEmpty, isTrue);
        expect(progressUpdates.last.isCompleted, isTrue);
      });

      test('should respect maxSize limit', () async {
        expect(
          () => gioClient.downloadBytes(
            'https://httpbin.org/bytes/2048',
            maxSize: 1000,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty response', () async {
        final bytes =
            await gioClient.downloadBytes('https://httpbin.org/bytes/0');
        expect(bytes.length, equals(0));
      });
    });

    group('downloadWithChunkCallback', () {
      test('should process chunks during download', () async {
        final chunks = <List<int>>[];
        var totalReceived = 0;

        await gioClient.downloadWithChunkCallback(
          'https://httpbin.org/bytes/1024',
          onChunk: (chunk) {
            chunks.add(List.from(chunk));
            totalReceived += chunk.length;
            print(
                'Received chunk: ${chunk.length} bytes, total: $totalReceived');
          },
          onProgress: (progress) {
            print('Chunk progress: ${progress.current}/${progress.total}');
          },
        );

        expect(chunks.isNotEmpty, isTrue);
        expect(totalReceived, equals(1024));

        // Verify total bytes from all chunks
        final totalFromChunks =
            chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
        expect(totalFromChunks, equals(1024));
      });

      test('should handle large download with chunking', () async {
        final chunks = <List<int>>[];
        final progressUpdates = <gio.TransferProgress>[];

        await gioClient.downloadWithChunkCallback(
          'https://httpbin.org/bytes/4096',
          onChunk: (chunk) {
            chunks.add(List.from(chunk));
          },
          onProgress: (progress) {
            progressUpdates.add(progress);
          },
        );

        expect(chunks.isNotEmpty, isTrue);
        expect(progressUpdates.isNotEmpty, isTrue);
        expect(progressUpdates.last.isCompleted, isTrue);

        final totalBytes =
            chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
        expect(totalBytes, equals(4096));
      });
    });

    group('downloadToSink', () {
      test('should download to IOSink', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_sink.bin');

        if (await testFile.exists()) {
          await testFile.delete();
        }

        try {
          final sink = testFile.openWrite();

          await gioClient.downloadToSink(
            'https://httpbin.org/bytes/1536',
            sink,
            onProgress: (progress) {
              print('Sink download: ${progress.current}/${progress.total}');
            },
          );

          await sink.close();

          expect(await testFile.exists(), isTrue);
          expect(await testFile.length(), equals(1536));
        } finally {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      test('should handle sink errors', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_sink_error.bin');

        if (await testFile.exists()) {
          await testFile.delete();
        }

        final sink = testFile.openWrite();
        await sink.close(); // Close sink before use to cause error

        try {
          await gioClient.downloadToSink(
            'https://httpbin.org/bytes/512',
            sink,
          );
          fail('Expected exception for closed sink');
        } catch (e) {
          expect(e, isA<StateError>());
        }
      });
    });

    group('HTTP Response Tests', () {
      test('should handle different content types', () async {
        // Test JSON response
        final jsonBytes =
            await gioClient.downloadBytes('https://httpbin.org/json');
        final jsonStr = String.fromCharCodes(jsonBytes);
        expect(jsonStr.contains('slideshow'), isTrue);

        // Test HTML response
        final htmlBytes =
            await gioClient.downloadBytes('https://httpbin.org/html');
        final htmlStr = String.fromCharCodes(htmlBytes);
        expect(htmlStr.contains('<html>'), isTrue);
      });

      test('should handle redirects', () async {
        final bytes =
            await gioClient.downloadBytes('https://httpbin.org/redirect/2');
        expect(bytes.isNotEmpty, isTrue);
      });

      test('should handle gzip compression', () async {
        final bytes = await gioClient.downloadBytes('https://httpbin.org/gzip');
        final content = String.fromCharCodes(bytes);
        expect(content.contains('gzipped'), isTrue);
      });
    });

    group('Progress Optimization Tests', () {
      test('should not report excessive progress updates', () async {
        final progressUpdates = <gio.TransferProgress>[];

        await gioClient.downloadBytes(
          'https://httpbin.org/bytes/8192',
          onProgress: (progress) {
            progressUpdates.add(progress);
          },
        );

        // Should have reasonable number of progress updates (not too many)
        expect(progressUpdates.length, lessThan(100));
        expect(progressUpdates.length, greaterThan(1));

        // Check for meaningful progress increments
        for (int i = 1; i < progressUpdates.length - 1; i++) {
          final prev = progressUpdates[i - 1];
          final curr = progressUpdates[i];

          // Progress should increase or it should be the completion
          expect(curr.current > prev.current || curr.isCompleted, isTrue);
        }
      });

      test('should handle very small downloads efficiently', () async {
        final progressUpdates = <gio.TransferProgress>[];

        await gioClient.downloadBytes(
          'https://httpbin.org/bytes/64',
          onProgress: (progress) {
            progressUpdates.add(progress);
          },
        );

        // For very small downloads, should still report completion
        expect(progressUpdates.isNotEmpty, isTrue);
        expect(progressUpdates.last.isCompleted, isTrue);
        expect(progressUpdates.last.current, equals(64));
      });
    });

    group('Error Handling', () {
      test('should handle various HTTP error codes', () async {
        final errorCodes = [400, 401, 403, 404, 500, 502, 503];

        for (final code in errorCodes) {
          try {
            await gioClient.downloadBytes('https://httpbin.org/status/$code');
            fail('Should throw exception for HTTP $code');
          } catch (e) {
            expect(e, isA<Exception>(),
                reason: 'Should throw exception for HTTP $code');
          }
        }
      });

      test('should handle invalid URLs', () async {
        try {
          await gioClient.downloadBytes(
              'https://invalid-domain-that-does-not-exist.com/data');
          fail('Should throw exception for invalid domain');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });
  });
}
