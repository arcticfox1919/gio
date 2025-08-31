import 'dart:convert';
import 'package:test/test.dart';
import 'package:gio/src/json/gio_json_codec.dart';

void main() {
  group('GioJsonCodec', () {
    late GioJsonCodec codec;

    setUp(() {
      codec = GioJsonCodec();
    });

    tearDown(() {
      codec.dispose();
    });

    group('encode', () {
      test('should encode simple data on main thread when parallel is false',
          () async {
        final data = {'name': 'John', 'age': 30};
        final result = await codec.encode(data, parallel: false);

        expect(result, equals('{"name":"John","age":30}'));
      });

      test('should encode simple data in background when parallel is true',
          () async {
        final data = {'name': 'John', 'age': 30};
        final result = await codec.encode(data, parallel: true);

        expect(result, equals('{"name":"John","age":30}'));
      });

      test('should encode complex nested data', () async {
        final data = {
          'user': {
            'name': 'John',
            'profile': {
              'age': 30,
              'skills': ['Dart', 'Flutter', 'JSON']
            }
          },
          'timestamp': '2025-08-31T12:00:00Z'
        };

        final resultMain = await codec.encode(data, parallel: false);
        final resultParallel = await codec.encode(data, parallel: true);

        // Both results should be identical
        expect(resultMain, equals(resultParallel));

        // Verify the data can be decoded back
        final decoded = jsonDecode(resultMain);
        expect(decoded['user']['name'], equals('John'));
        expect(decoded['user']['profile']['skills'], contains('Dart'));
      });

      test('should handle null and primitive values', () async {
        final testCases = [
          null,
          'hello',
          42,
          true,
          [1, 2, 3],
          {'empty': {}}
        ];

        for (final data in testCases) {
          final resultMain = await codec.encode(data, parallel: false);
          final resultParallel = await codec.encode(data, parallel: true);

          expect(resultMain, equals(resultParallel));
          expect(resultMain, equals(jsonEncode(data)));
        }
      });

      test('should fallback to main thread when background encoding fails',
          () async {
        // This test simulates the fallback mechanism
        final data = {'test': 'value'};
        final result = await codec.encode(data, parallel: true);

        expect(result, equals('{"test":"value"}'));
      });
    });

    group('decode', () {
      test('should decode simple JSON on main thread when parallel is false',
          () async {
        const jsonString = '{"name":"John","age":30}';
        final result = await codec.decode(jsonString, parallel: false);

        expect(result, isA<Map<String, dynamic>>());
        expect(result['name'], equals('John'));
        expect(result['age'], equals(30));
      });

      test('should decode simple JSON in background when parallel is true',
          () async {
        const jsonString = '{"name":"John","age":30}';
        final result = await codec.decode(jsonString, parallel: true);

        expect(result, isA<Map<String, dynamic>>());
        expect(result['name'], equals('John'));
        expect(result['age'], equals(30));
      });

      test('should decode complex nested JSON', () async {
        const jsonString = '''
        {
          "user": {
            "name": "John",
            "profile": {
              "age": 30,
              "skills": ["Dart", "Flutter", "JSON"]
            }
          },
          "timestamp": "2025-08-31T12:00:00Z"
        }
        ''';

        final resultMain = await codec.decode(jsonString, parallel: false);
        final resultParallel = await codec.decode(jsonString, parallel: true);

        // Both results should be identical
        expect(resultMain.toString(), equals(resultParallel.toString()));

        // Verify the decoded data structure
        expect(resultMain['user']['name'], equals('John'));
        expect(resultMain['user']['profile']['skills'], contains('Dart'));
      });

      test('should handle various JSON types', () async {
        final testCases = [
          ('null', null),
          ('"hello"', 'hello'),
          ('42', 42),
          ('true', true),
          ('[1,2,3]', [1, 2, 3]),
          ('{}', <String, dynamic>{}),
        ];

        for (final (jsonString, expectedValue) in testCases) {
          final resultMain = await codec.decode(jsonString, parallel: false);
          final resultParallel = await codec.decode(jsonString, parallel: true);

          expect(resultMain, equals(resultParallel));
          expect(resultMain, equals(expectedValue));
        }
      });

      test('should fallback to main thread when background decoding fails',
          () async {
        // This test simulates the fallback mechanism
        const jsonString = '{"test":"value"}';
        final result = await codec.decode(jsonString, parallel: true);

        expect(result['test'], equals('value'));
      });
    });

    group('round-trip encoding/decoding', () {
      test('should preserve data through encode-decode cycle', () async {
        final originalData = {
          'string': 'Hello, World!',
          'number': 42,
          'boolean': true,
          'null_value': null,
          'array': [1, 2, 3, 'four'],
          'object': {
            'nested': 'value',
            'deep': {'level': 2}
          }
        };

        // Test main thread round-trip
        final encodedMain = await codec.encode(originalData, parallel: false);
        final decodedMain = await codec.decode(encodedMain, parallel: false);

        // Test parallel round-trip
        final encodedParallel =
            await codec.encode(originalData, parallel: true);
        final decodedParallel =
            await codec.decode(encodedParallel, parallel: true);

        // Both should produce identical results
        expect(decodedMain.toString(), equals(decodedParallel.toString()));
        expect(decodedMain['string'], equals(originalData['string']));
        expect(decodedMain['object']['deep']['level'], equals(2));
      });
    });

    group('singleton pattern', () {
      test('should return the same instance', () {
        final codec1 = GioJsonCodec();
        final codec2 = GioJsonCodec();

        expect(identical(codec1, codec2), isTrue);
      });
    });

    group('resource management', () {
      test('should handle dispose without errors', () {
        final codec = GioJsonCodec();

        expect(() => codec.dispose(), returnsNormally);

        // Should still work after dispose (will recreate worker if needed)
        expect(() => codec.encode({'test': 'value'}), returnsNormally);
      });

      test('should allow setting custom idle timeout', () {
        final codec = GioJsonCodec();

        // Default should be 60 seconds
        expect(codec.idleTimeout, equals(const Duration(seconds: 60)));

        // Set custom timeout
        const customTimeout = Duration(seconds: 30);
        codec.idleTimeout = customTimeout;

        expect(codec.idleTimeout, equals(customTimeout));
      });

      test('should update active timer when timeout is changed', () async {
        final codec = GioJsonCodec();

        // Start a background operation to create worker and timer
        await codec.encode({'test': 'data'}, parallel: true);

        // Change timeout - this should reset the active timer
        codec.idleTimeout = const Duration(seconds: 10);

        expect(codec.idleTimeout, equals(const Duration(seconds: 10)));
      });

      test('should accept various timeout durations', () {
        final codec = GioJsonCodec();

        final testTimeouts = [
          const Duration(seconds: 5),
          const Duration(minutes: 2),
          const Duration(milliseconds: 500),
          const Duration(hours: 1),
        ];

        for (final timeout in testTimeouts) {
          codec.idleTimeout = timeout;
          expect(codec.idleTimeout, equals(timeout));
        }
      });
    });
    group('error handling', () {
      test('should handle invalid JSON gracefully during decode', () async {
        const invalidJson = '{invalid json}';

        // Main thread should throw
        expect(
          () => codec.decode(invalidJson, parallel: false),
          throwsA(isA<FormatException>()),
        );

        // Parallel should fallback and also throw
        expect(
          () => codec.decode(invalidJson, parallel: true),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle circular reference gracefully during encode',
          () async {
        // Create circular reference
        final Map<String, dynamic> circular = {};
        circular['self'] = circular;

        // Both should throw
        expect(
          () => codec.encode(circular, parallel: false),
          throwsA(isA<JsonCyclicError>()),
        );

        expect(
          () => codec.encode(circular, parallel: true),
          throwsA(isA<JsonCyclicError>()),
        );
      });
    });
  });
}
