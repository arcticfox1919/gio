import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';

import 'package:http/http.dart' as http;
import 'interceptor.dart';

/// HTTP logging interceptor for Gio.
///
/// Design goals:
/// - Safe for streaming: does not consume request body of [http.StreamedRequest];
///   for [http.StreamedResponse] it transparently forwards chunks to the
///   downstream while sampling only the first [maxLogBodyBytes] for preview.
/// - Sensible defaults for large/binary content: skips body logging for
///   attachments, obvious non-text content-types, or responses larger than
///   [downloadSizeThreshold].
/// - Pluggable logging backend: when [useLogging] is true, messages are emitted
///   through `package:logging`. Callers can subscribe to `Logger.root.onRecord`
///   to collect and persist logs (files, analytics, remote sinks). When
///   [useLogging] is false, messages are printed to stdout.
///
/// Typical usage:
///
/// ```dart
/// Logger.root.level = Level.INFO;
/// Logger.root.onRecord.listen((rec) {
///   // Persist rec to file or forward to APM
/// });
///
/// Gio.option = GioOption(
///   enableLog: true, // create default GioLogInterceptor
///   logInterceptor: GioLogInterceptor(
///     useLogging: true,
///     loggerName: 'gio',
///     maxLogBodyBytes: 16 * 1024,
///     downloadSizeThreshold: 1024 * 1024,
///   ),
/// );
/// ```
class GioLogInterceptor {
  final int maxLogBodyBytes;
  final int downloadSizeThreshold;
  final bool useLogging;
  final String loggerName;
  final Level logLevel;
  final bool alsoPrintToStdout;
  final Logger? _logger;

  GioLogInterceptor({
    this.maxLogBodyBytes = 16 * 1024, // 16KB
    this.downloadSizeThreshold = 1024 * 1024, // 1MB
    this.useLogging = false,
    this.loggerName = 'gio',
    this.logLevel = Level.INFO,
    this.alsoPrintToStdout = false,
  }) : _logger = useLogging ? Logger(loggerName) : null;

  Future<http.StreamedResponse> call(Chain chain) async {
    final request = chain.request;
    final requestTime = DateTime.now().millisecondsSinceEpoch;
    _logRequest(request);
    try {
      final response = await chain.proceed(request);
      // For downloads or binary content: only log headers/metadata to avoid buffering large files
      if (_shouldOmitBodyLogging(response)) {
        await _logResponseHeadOnly(response, requestTime);
        return response;
      }

      // Pass-through streaming + sample only the first N bytes to limit memory usage
      var captured = 0;
      final preview = <int>[];
      final controller = StreamController<List<int>>(sync: true);
      response.stream.listen(
        (chunk) {
          if (captured < maxLogBodyBytes) {
            final remain = maxLogBodyBytes - captured;
            if (remain > 0) {
              if (chunk.length <= remain) {
                preview.addAll(chunk);
                captured += chunk.length;
              } else {
                preview.addAll(chunk.sublist(0, remain));
                captured += remain;
              }
            }
          }
          controller.add(chunk);
        },
        onError: controller.addError,
        onDone: () async {
          await _logBufferedResponse(response, preview, requestTime,
              truncated: _isTruncated(response, captured));
          await controller.close();
        },
        cancelOnError: false,
      );

      return http.StreamedResponse(
        controller.stream,
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      _logUnknownError(e, request, requestTime);
      rethrow;
    }
  }

  void _logRequest(http.BaseRequest request) async {
    final sb = StringBuffer();
    final method = request.method.toUpperCase();
    final query = request.url.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final url = '${request.url}${query.isNotEmpty ? '?$query' : ''}';
    sb.writeln('--> $method $url');

    if (request is http.Request) {
      if (request.body.isNotEmpty) {
        final body = request.body;
        if (body.length > maxLogBodyBytes) {
          sb.writeln(body.substring(0, maxLogBodyBytes));
          sb.writeln('... <truncated>');
        } else {
          sb.writeln(body);
        }
      }
    } else if (request is http.StreamedRequest) {
      // Do not consume the StreamedRequest body to avoid affecting subsequent sending
      final len = request.contentLength;
      if (len != null && len > 0) {
        sb.writeln('<streamed body: $len bytes>');
      }
    }

    sb.write('--> END $method');
    logPrint(sb.toString());
  }

  Future<void> _logBufferedResponse(
      http.StreamedResponse response, List<int> bodyBytes, int requestTime,
      {bool truncated = false}) async {
    final url = response.request?.url;
    final sb = StringBuffer();
    sb.writeln(
        '<-- [${response.statusCode}][${DateTime.now().millisecondsSinceEpoch - requestTime}ms] $url ');

    if (bodyBytes.isNotEmpty && _isTextLike(response.headers)) {
      sb.writeln(utf8.decode(bodyBytes, allowMalformed: true));
      if (truncated) sb.writeln('... <truncated>');
    } else if (bodyBytes.isNotEmpty) {
      sb.writeln('<binary ${bodyBytes.length} bytes>');
    }
    sb.write('<-- END HTTP');
    logPrint(sb.toString());
  }

  Future<void> _logResponseHeadOnly(
      http.StreamedResponse response, int requestTime) async {
    final url = response.request?.url;
    final sb = StringBuffer();
    sb.writeln(
        '<-- [${response.statusCode}][${DateTime.now().millisecondsSinceEpoch - requestTime}ms] $url ');
    final ct = response.headers['content-type'] ?? '';
    final cl = response.contentLength;
    final cd = response.headers['content-disposition'] ?? '';
    sb.writeln('content-type: $ct');
    if (cl != null) sb.writeln('content-length: $cl');
    if (cd.isNotEmpty) sb.writeln('content-disposition: $cd');
    sb.writeln('<body omitted>');
    sb.write('<-- END HTTP');
    logPrint(sb.toString());
  }

  bool _isTextLike(Map<String, String> headers) {
    final contentType = (headers['content-type'] ?? '').toLowerCase();
    if (contentType.isEmpty) return false;
    return contentType.startsWith('text/') ||
        contentType.contains('application/json') ||
        contentType.contains('application/xml') ||
        contentType.contains('application/javascript') ||
        contentType.contains('application/x-www-form-urlencoded');
  }

  bool _hasAttachment(Map<String, String> headers) {
    final cd = headers['content-disposition']?.toLowerCase() ?? '';
    return cd.contains('attachment') || cd.contains('filename=');
  }

  bool _shouldOmitBodyLogging(http.StreamedResponse response) {
    final headers = response.headers;
    if (_hasAttachment(headers)) return true;
    final contentLength = response.contentLength;
    if (contentLength != null && contentLength > downloadSizeThreshold) {
      return true;
    }
    // Do not log body for obvious non-text content types
    final contentType = (headers['content-type'] ?? '').toLowerCase();
    if (contentType.isNotEmpty) {
      if (!(contentType.startsWith('text/') ||
          contentType.contains('application/json') ||
          contentType.contains('application/xml') ||
          contentType.contains('application/javascript'))) {
        return true;
      }
    }
    return false;
  }

  bool _isTruncated(http.StreamedResponse response, int captured) {
    final cl = response.contentLength;
    if (cl != null) return captured < cl;
    return captured >= maxLogBodyBytes;
  }

  void _logUnknownError(
      Object error, http.BaseRequest request, int requestTime) {
    final sb = StringBuffer();
    sb.writeln(
        '<-- [error][${DateTime.now().millisecondsSinceEpoch - requestTime}ms] ${request.url} ');
    sb.writeln(error.toString());
    sb.write('<-- END HTTP');
    logPrint(sb.toString());
  }

  void logPrint(String? message) {
    final text = message ?? 'null';
    if (useLogging) {
      // Logger is created on construction when enabled; just reuse it here
      _logger!.log(logLevel, text);
      if (alsoPrintToStdout) {
        _print(text);
      }
    } else {
      _print(text);
    }
  }
}

const _maxLen = 128;
void _print(String? msg) {
  String data = msg ?? 'null';
  if (data.length <= _maxLen) {
    print(data);
    return;
  }
  while (data.isNotEmpty) {
    if (data.length > _maxLen) {
      print(data.substring(0, _maxLen));
      data = data.substring(_maxLen, data.length);
    } else {
      print(data);
      data = '';
    }
  }
}
