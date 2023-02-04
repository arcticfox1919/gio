import 'dart:async';

import 'base_request.dart';
import 'base_response.dart';
import 'byte_stream.dart';
import 'utils.dart';

/// An HTTP response where the response body is received asynchronously after
/// the headers have been received.
class StreamedResponse extends BaseResponse {
  /// The stream from which the response body data can be read.
  ///
  /// This should always be a single-subscription stream.
  late final ByteStream stream;

  /// Creates a new streaming response.
  ///
  /// [stream] should be a single-subscription stream.
  StreamedResponse(Stream<List<int>> stream, int statusCode,
      {int? contentLength,
      BaseRequest? request,
      Map<String, String> headers = const {},
      bool isRedirect = false,
      bool persistentConnection = true,
      String? reasonPhrase})
      : stream = toByteStream(stream),
        super(statusCode,
            contentLength: contentLength,
            request: request,
            headers: headers,
            isRedirect: isRedirect,
            persistentConnection: persistentConnection,
            reasonPhrase: reasonPhrase);

  StreamedResponse copyWith(Stream<List<int>> stream,
      {int? statusCode,
      int? contentLength,
      BaseRequest? request,
      Map<String, String>? headers,
      bool? isRedirect,
      bool? persistentConnection,
      String? reasonPhrase}) {
    return StreamedResponse(stream, statusCode ?? this.statusCode,
        contentLength: contentLength ?? this.contentLength,
        request: request ?? this.request,
        headers: headers ?? this.headers,
        isRedirect: isRedirect ?? this.isRedirect,
        persistentConnection: persistentConnection ?? this.persistentConnection,
        reasonPhrase: reasonPhrase ?? this.reasonPhrase);
  }
}
