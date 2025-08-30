import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../gio_client.dart';

/// Progress information for upload/download operations
class TransferProgress {
  /// Current number of bytes transferred
  final int current;

  /// Total number of bytes to transfer (may be null for chunked encoding)
  final int? total;

  /// Progress percentage (0.0 to 1.0), null if total is unknown
  double? get percentage => total != null ? current / total! : null;

  /// Whether the transfer is completed
  final bool isCompleted;

  /// Transfer speed in bytes per second (calculated over recent time window)
  final double? speed;

  /// Estimated remaining time in seconds (null if total is unknown)
  final Duration? estimatedTimeRemaining;

  const TransferProgress({
    required this.current,
    this.total,
    this.isCompleted = false,
    this.speed,
    this.estimatedTimeRemaining,
  });

  @override
  String toString() {
    final percent = percentage != null
        ? '${(percentage! * 100).toStringAsFixed(1)}%'
        : 'unknown';
    final speedStr =
        speed != null ? '${(speed! / 1024).toStringAsFixed(1)} KB/s' : '';
    return 'TransferProgress(current: $current, total: $total, progress: $percent, speed: $speedStr)';
  }
}

/// Callback function for upload/download progress
typedef ProgressCallback = void Function(TransferProgress progress);

/// Callback function for receiving downloaded data chunks
typedef DataChunkCallback = void Function(Uint8List chunk);

/// Extension methods to add upload/download capabilities directly to Gio
extension GioTransferMethods on Gio {
  // === Upload Methods ===

  /// Upload a file with progress tracking
  ///
  /// Example:
  /// ```dart
  /// final gio = Gio();
  /// await gio.uploadFile(
  ///   File('/path/to/file.jpg'),
  ///   'https://api.example.com/upload',
  ///   onProgress: (progress) {
  ///     print('Upload: ${progress.percentage! * 100}%');
  ///   },
  /// );
  /// ```
  Future<http.Response> uploadFile(
    File file,
    String url, {
    String fieldName = 'file',
    ProgressCallback? onProgress,
    Map<String, String>? headers,
    Map<String, String>? fields,
  }) async {
    final fileSize = await file.length();
    final fileName = file.path.split(Platform.pathSeparator).last;

    // Create multipart request
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (headers != null) {
      request.headers.addAll(headers);
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Create streaming multipart file with progress tracking
    final fileStream = _createProgressStream(
      file.openRead(),
      fileSize,
      onProgress,
    );

    request.files.add(http.MultipartFile(
      fieldName,
      fileStream,
      fileSize,
      filename: fileName,
    ));

    // Send via this gio client
    final streamedResponse = await send(request);
    return http.Response.fromStream(streamedResponse);
  }

  /// Upload raw bytes with progress tracking
  ///
  /// Example:
  /// ```dart
  /// final gio = Gio();
  /// await gio.uploadBytes(
  ///   imageBytes,
  ///   'https://api.example.com/upload',
  ///   contentType: 'image/png',
  ///   onProgress: (progress) => print('Uploaded: ${progress.current} bytes'),
  /// );
  /// ```
  Future<http.Response> uploadBytes(
    Uint8List data,
    String url, {
    ProgressCallback? onProgress,
    Map<String, String>? headers,
    String? contentType,
  }) async {
    final request = http.StreamedRequest('POST', Uri.parse(url));
    request.contentLength = data.length;

    if (headers != null) {
      request.headers.addAll(headers);
    }

    if (contentType != null) {
      request.headers['content-type'] = contentType;
    }

    // Create progress-tracking request
    final progressRequest = _ProgressStreamedRequest(
      request.method,
      request.url,
      _createProgressStream(
        _bytesToStream(data),
        data.length,
        onProgress,
      ),
    );
    progressRequest.headers.addAll(request.headers);
    progressRequest.contentLength = request.contentLength;

    final streamedResponse = await send(progressRequest);
    return http.Response.fromStream(streamedResponse);
  }

  /// Upload from a stream with progress tracking
  ///
  /// Example:
  /// ```dart
  /// final gio = Gio();
  /// await gio.uploadStream(
  ///   dataStream,
  ///   'https://api.example.com/upload',
  ///   1024 * 1024, // 1MB content length
  ///   onProgress: (progress) => print('Progress: ${progress.percentage}'),
  /// );
  /// ```
  Future<http.Response> uploadStream(
    Stream<List<int>> dataStream,
    String url,
    int contentLength, {
    ProgressCallback? onProgress,
    Map<String, String>? headers,
  }) async {
    final request = http.StreamedRequest('POST', Uri.parse(url));
    request.contentLength = contentLength;

    if (headers != null) {
      request.headers.addAll(headers);
    }

    final progressRequest = _ProgressStreamedRequest(
      request.method,
      request.url,
      _createProgressStream(dataStream, contentLength, onProgress),
    );
    progressRequest.headers.addAll(request.headers);
    progressRequest.contentLength = request.contentLength;

    final streamedResponse = await send(progressRequest);
    return http.Response.fromStream(streamedResponse);
  }

  // === Download Methods ===

  /// Download a file with progress tracking
  ///
  /// Example:
  /// ```dart
  /// final gio = Gio();
  /// final file = await gio.downloadFile(
  ///   'https://example.com/large-file.zip',
  ///   '/downloads/file.zip',
  ///   onProgress: (progress) {
  ///     print('Download: ${progress.percentage! * 100}%');
  ///     print('Speed: ${progress.speed! / 1024} KB/s');
  ///   },
  /// );
  /// ```
  Future<File> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onProgress,
    Map<String, String>? headers,
    int? resumeFrom,
  }) async {
    final file = File(savePath);
    final sink = file.openWrite(
        mode: resumeFrom != null ? FileMode.append : FileMode.write);

    try {
      await downloadToSink(
        url,
        sink,
        onProgress: onProgress,
        headers: headers,
        resumeFrom: resumeFrom,
      );
      return file;
    } finally {
      await sink.close();
    }
  }

  /// Download to an IOSink with progress tracking
  ///
  /// Example:
  /// ```dart
  /// final gio = Gio();
  /// final file = File('/downloads/backup.tar.gz');
  /// final sink = file.openWrite();
  /// try {
  ///   await gio.downloadToSink(
  ///     'https://backups.example.com/latest.tar.gz',
  ///     sink,
  ///     onProgress: (progress) => print('Progress: ${progress.percentage}'),
  ///   );
  /// } finally {
  ///   await sink.close();
  /// }
  /// ```
  Future<void> downloadToSink(
    String url,
    IOSink sink, {
    ProgressCallback? onProgress,
    Map<String, String>? headers,
    int? resumeFrom,
  }) async {
    final requestHeaders = <String, String>{};
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    // Add range header for resume support
    if (resumeFrom != null && resumeFrom > 0) {
      requestHeaders['range'] = 'bytes=$resumeFrom-';
    }

    final response = await send(
      http.Request('GET', Uri.parse(url))..headers.addAll(requestHeaders),
    );

    if (response.statusCode >= 400) {
      throw Exception('Download failed with status ${response.statusCode}');
    }

    final contentLength = response.contentLength;
    final totalSize =
        contentLength != null ? contentLength + (resumeFrom ?? 0) : null;

    await _processDownloadStream(
      response.stream,
      sink._asDataSink,
      totalSize,
      onProgress,
      initialProgress: resumeFrom ?? 0,
    );
  }

  /// Download to memory as bytes with progress tracking
  ///
  /// Example:
  /// ```dart
  /// final gio = Gio();
  /// final imageData = await gio.downloadBytes(
  ///   'https://example.com/image.jpg',
  ///   maxSize: 10 * 1024 * 1024, // 10MB limit
  ///   onProgress: (progress) => updateProgressBar(progress),
  /// );
  /// ```
  Future<Uint8List> downloadBytes(
    String url, {
    ProgressCallback? onProgress,
    Map<String, String>? headers,
    int? maxSize,
  }) async {
    final response = await send(
      http.Request('GET', Uri.parse(url))..headers.addAll(headers ?? {}),
    );

    if (response.statusCode >= 400) {
      throw Exception('Download failed with status ${response.statusCode}');
    }

    final contentLength = response.contentLength;
    if (maxSize != null && contentLength != null && contentLength > maxSize) {
      throw Exception(
          'Download size ($contentLength bytes) exceeds limit ($maxSize bytes)');
    }

    final chunks = <List<int>>[];
    await _processDownloadStream(
      response.stream,
      _ListSink(chunks),
      contentLength,
      onProgress,
    );

    // Efficiently combine all chunks
    final totalBytes = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final result = Uint8List(totalBytes);
    int offset = 0;
    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }

  /// Download with chunk-by-chunk processing
  ///
  /// Example:
  /// ```dart
  /// final gio = Gio();
  /// await gio.downloadWithChunkCallback(
  ///   'https://example.com/video.mp4',
  ///   onChunk: (chunk) {
  ///     // Process chunk immediately (e.g., decode, transform, save)
  ///     videoProcessor.processChunk(chunk);
  ///   },
  ///   onProgress: (progress) => updateVideoDownloadUI(progress),
  /// );
  /// ```
  Future<void> downloadWithChunkCallback(
    String url, {
    required DataChunkCallback onChunk,
    ProgressCallback? onProgress,
    Map<String, String>? headers,
  }) async {
    final response = await send(
      http.Request('GET', Uri.parse(url))..headers.addAll(headers ?? {}),
    );

    if (response.statusCode >= 400) {
      throw Exception('Download failed with status ${response.statusCode}');
    }

    await _processDownloadStream(
      response.stream,
      _CallbackSink(onChunk),
      response.contentLength,
      onProgress,
    );
  }

  // === Private Helper Methods ===

  /// Create a progress-tracking stream wrapper
  Stream<List<int>> _createProgressStream(
    Stream<List<int>> originalStream,
    int totalSize,
    ProgressCallback? onProgress,
  ) {
    if (onProgress == null) return originalStream;

    int transferredBytes = 0;
    DateTime? startTime;
    DateTime? lastProgressTime;
    int lastProgressBytes = 0;
    const speedCalculationWindow = Duration(seconds: 1);

    return originalStream.map<List<int>>((chunk) {
      startTime ??= DateTime.now();
      transferredBytes += chunk.length;

      final now = DateTime.now();
      double? speed;
      Duration? estimatedTimeRemaining;

      final currentProgressTime = lastProgressTime;
      if (currentProgressTime != null) {
        final timeDiff = now.difference(currentProgressTime);
        if (timeDiff >= speedCalculationWindow) {
          final bytesDiff = transferredBytes - lastProgressBytes;
          speed =
              bytesDiff / timeDiff.inMilliseconds * 1000; // bytes per second

          if (speed > 0) {
            final remainingBytes = totalSize - transferredBytes;
            estimatedTimeRemaining = Duration(
              seconds: (remainingBytes / speed).round(),
            );
          }

          lastProgressTime = now;
          lastProgressBytes = transferredBytes;
        }
      } else {
        lastProgressTime = now;
        lastProgressBytes = transferredBytes;
      }

      final progress = TransferProgress(
        current: transferredBytes,
        total: totalSize,
        isCompleted: transferredBytes >= totalSize,
        speed: speed,
        estimatedTimeRemaining: estimatedTimeRemaining,
      );

      onProgress(progress);
      return chunk;
    });
  }

  /// Convert bytes to stream
  Stream<List<int>> _bytesToStream(Uint8List data) async* {
    const chunkSize = 64 * 1024; // 64KB chunks
    int offset = 0;

    while (offset < data.length) {
      final end = (offset + chunkSize).clamp(0, data.length);
      yield data.sublist(offset, end);
      offset = end;

      // Allow other operations to run
      await Future.delayed(Duration.zero);
    }
  }

  /// Process download stream with progress tracking
  Future<void> _processDownloadStream(
    Stream<List<int>> stream,
    _DataSink sink,
    int? totalSize,
    ProgressCallback? onProgress, {
    int initialProgress = 0,
  }) async {
    int downloadedBytes = initialProgress;
    DateTime? startTime;
    DateTime? lastProgressTime;
    int lastProgressBytes = initialProgress;
    const speedCalculationWindow = Duration(seconds: 1);

    await for (final chunk in stream) {
      startTime ??= DateTime.now();
      downloadedBytes += chunk.length;

      // Write chunk to sink
      sink.add(chunk);

      // Calculate progress
      if (onProgress != null) {
        final now = DateTime.now();
        double? speed;
        Duration? estimatedTimeRemaining;

        final currentProgressTime = lastProgressTime;
        if (currentProgressTime != null) {
          final timeDiff = now.difference(currentProgressTime);
          if (timeDiff >= speedCalculationWindow) {
            final bytesDiff = downloadedBytes - lastProgressBytes;
            speed =
                bytesDiff / timeDiff.inMilliseconds * 1000; // bytes per second

            if (speed > 0 && totalSize != null) {
              final remainingBytes = totalSize - downloadedBytes;
              estimatedTimeRemaining = Duration(
                seconds: (remainingBytes / speed).round(),
              );
            }

            lastProgressTime = now;
            lastProgressBytes = downloadedBytes;
          }
        } else {
          lastProgressTime = now;
          lastProgressBytes = downloadedBytes;
        }

        final progress = TransferProgress(
          current: downloadedBytes,
          total: totalSize,
          isCompleted: totalSize != null && downloadedBytes >= totalSize,
          speed: speed,
          estimatedTimeRemaining: estimatedTimeRemaining,
        );

        onProgress(progress);
      }
    }

    // Ensure final progress callback
    if (onProgress != null && totalSize != null) {
      onProgress(TransferProgress(
        current: downloadedBytes,
        total: totalSize,
        isCompleted: true,
      ));
    }
  }
}

/// Custom StreamedRequest that accepts a pre-built stream
class _ProgressStreamedRequest extends http.BaseRequest {
  final Stream<List<int>> _stream;

  _ProgressStreamedRequest(
    super.method,
    super.url,
    this._stream,
  );

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_stream);
  }
}

/// Abstract sink for different download destinations
abstract class _DataSink {
  void add(List<int> chunk);
}

/// Sink that writes to an IOSink (file, etc.)
class _IODataSink implements _DataSink {
  final IOSink _sink;

  _IODataSink(this._sink);

  @override
  void add(List<int> chunk) {
    _sink.add(chunk);
  }
}

/// Sink that collects chunks in a list
class _ListSink implements _DataSink {
  final List<List<int>> _chunks;

  _ListSink(this._chunks);

  @override
  void add(List<int> chunk) {
    _chunks.add(List.from(chunk)); // Copy to avoid reference issues
  }
}

/// Sink that calls a callback for each chunk
class _CallbackSink implements _DataSink {
  final DataChunkCallback _callback;

  _CallbackSink(this._callback);

  @override
  void add(List<int> chunk) {
    _callback(Uint8List.fromList(chunk));
  }
}

/// Extension to IOSink to make it work with _DataSink
extension _IOSinkDataSink on IOSink {
  _DataSink get _asDataSink => _IODataSink(this);
}
