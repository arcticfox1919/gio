import 'package:http/http.dart' as http;
import 'gio_json_codec.dart';

/// JSON processing extension methods for Response
///
/// Adds convenient JSON decoding functionality to http.Response with background isolate support
extension JsonResponseExtension on http.Response {
  /// Decode response body to JSON object
  ///
  /// **Usage Examples:**
  /// ```dart
  /// final response = await gio.get('https://api.example.com/data');
  /// final jsonData = await response.toJson();
  /// print(jsonData['name']);
  ///
  /// // Use parallel processing for large JSON (avoid blocking UI)
  /// final jsonData = await response.toJson(parallel: true);
  /// ```
  ///
  /// **Performance Characteristics:**
  /// - Small JSON: Main thread processing is faster
  /// - Large JSON: Parallel processing avoids UI blocking
  ///
  /// [parallel] Whether to use parallel processing, defaults to false
  /// Returns decoded JSON object (Map or List)
  Future<dynamic> toJson({bool parallel = false}) async {
    return await GioJsonCodec().decode(body, parallel: parallel);
  }

  /// Decode response body to JSON and convert to custom object
  ///
  /// Provides a way to decode JSON and transform it into custom Dart objects
  /// using a user-provided converter function.
  ///
  /// **Usage Examples:**
  /// ```dart
  /// // Convert to User object
  /// final response = await gio.get('https://api.example.com/user/123');
  /// final user = await response.toJsonAs<User>(
  ///   (json) => User.fromJson(json as Map<String, dynamic>)
  /// );
  ///
  /// // Use parallel processing for large JSON
  /// final user = await response.toJsonAs<User>(
  ///   (json) => User.fromJson(json as Map<String, dynamic>),
  ///   parallel: true
  /// );
  /// ```
  ///
  /// [converter] Function to convert decoded JSON to target type
  /// [parallel] Whether to use parallel processing, defaults to false
  /// [T] Target object type
  /// Returns converted object of type T
  Future<T> toJsonAs<T>(T Function(dynamic json) converter,
      {bool parallel = false}) async {
    final json = await toJson(parallel: parallel);
    return converter(json);
  }

  /// Check if response contains valid JSON content
  ///
  /// Checks if Content-Type header indicates this is a JSON response
  ///
  /// **Check Rules:**
  /// - Content-Type contains 'application/json'
  /// - Content-Type contains 'text/json'
  /// - Content-Type contains '+json' suffix
  ///
  /// Returns true if this is a JSON response
  bool get isJsonResponse {
    String? contentType;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') {
        contentType = entry.value.toLowerCase();
        break;
      }
    }

    if (contentType == null) return false;

    return contentType.contains('application/json') ||
        contentType.contains('text/json') ||
        contentType.contains('+json');
  }
}
