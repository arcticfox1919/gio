import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../gio_interface.dart';

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

  const TransferProgress({
    required this.current,
    this.total,
    this.isCompleted = false,
  });

  @override
  String toString() {
    final percent = percentage != null
        ? '${(percentage! * 100).toStringAsFixed(1)}%'
        : 'unknown';
    return 'TransferProgress(current: $current, total: $total, progress: $percent)';
  }
}

/// Callback function for upload/download progress
typedef ProgressCallback = void Function(TransferProgress progress);

/// Callback function for receiving downloaded data chunks
typedef DataChunkCallback = void Function(Uint8List chunk);

/// Extension methods to add upload/download capabilities directly to Gio
extension GioTransferMethods on Gio {
  // === Upload Methods ===

  /// Upload a file using multipart/form-data format with progress tracking
  ///
  /// This method creates a standard HTTP multipart/form-data request, which is
  /// the most widely supported format for file uploads on web servers. The file
  /// is uploaded as a multipart form field, allowing you to include additional
  /// form fields alongside the file data.
  ///
  /// **Parameters:**
  /// - [file]: The file to upload from local filesystem
  /// - [url]: Target upload endpoint URL
  /// - [fieldName]: Form field name for the file (default: 'file')
  /// - [onProgress]: Optional callback for upload progress updates
  /// - [headers]: Additional HTTP headers to include in request
  /// - [fields]: Additional form fields to send with the file
  ///
  /// **Returns:** HTTP response from the server
  ///
  /// **Note:** For raw binary uploads without multipart encoding, use [uploadBytes] instead.
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

  /// Upload raw binary data using streaming request with progress tracking
  ///
  /// This method uploads binary data directly as the HTTP request body without
  /// any multipart encoding. The data is sent as-is in chunks, providing maximum
  /// transfer efficiency with zero protocol overhead.
  ///
  /// **Parameters:**
  /// - [data]: Binary data to upload as Uint8List
  /// - [url]: Target upload endpoint URL
  /// - [onProgress]: Optional callback for upload progress updates
  /// - [headers]: Additional HTTP headers to include
  /// - [contentType]: MIME type of the data (e.g., 'image/jpeg', 'application/pdf')
  ///
  /// **Returns:** HTTP response from the server
  ///
  /// **Note:** For standard file uploads compatible with web forms, use [uploadFile] instead.
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

  /// Upload data from a stream source with progress tracking
  ///
  /// This method accepts a pre-existing data stream and uploads it with progress
  /// monitoring. It's designed for scenarios where data is already available as
  /// a stream or needs to be generated/transformed on-the-fly during upload.
  ///
  /// **Parameters:**
  /// - [dataStream]: Source stream providing data chunks as `List<int>`
  /// - [url]: Target upload endpoint URL
  /// - [contentLength]: Total bytes to be uploaded (required for progress calculation)
  /// - [onProgress]: Optional callback for upload progress updates
  /// - [headers]: Additional HTTP headers to include
  ///
  /// **Returns:** HTTP response from the server
  ///
  /// **Important:** The [contentLength] must be accurate for proper progress tracking.
  ///
  /// **Note:** For simple file or byte array uploads, use [uploadFile] or [uploadBytes] instead.
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

  /// Download a file directly to filesystem with progress tracking and resume support
  ///
  /// This method downloads content from a URL and saves it directly to a local file,
  /// providing real-time progress updates and optional resume capability for interrupted
  /// downloads. It's the most convenient method for simple file downloads.
  ///
  /// **Parameters:**
  /// - [url]: Source URL to download from
  /// - [savePath]: Local filesystem path where file will be saved
  /// - [onProgress]: Optional callback for download progress updates
  /// - [headers]: Additional HTTP headers (e.g., authentication, user-agent)
  /// - [resumeFrom]: Byte offset to resume download from (for partial downloads)
  ///
  /// **Returns:** File object pointing to the downloaded file
  ///
  /// **Resume Usage:**
  /// To resume a partial download, pass the size of existing partial file:
  /// ```dart
  /// final partialFile = File('/downloads/movie.mp4');
  /// final resumeFrom = await partialFile.exists() ? await partialFile.length() : null;
  /// await gio.downloadFile(url, '/downloads/movie.mp4', resumeFrom: resumeFrom);
  /// ```
  ///
  /// **Note:** For in-memory downloads or custom processing, use [downloadBytes] or [downloadWithChunkCallback].
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

  /// Download content to any IOSink destination with progress tracking
  ///
  /// This method provides maximum flexibility for download destinations by accepting
  /// any IOSink implementation. It's ideal for custom processing pipelines, network
  /// forwarding, or when you need fine-grained control over the download destination.
  ///
  /// **Flexibility:**
  /// - **File Output**: Use File.openWrite() for filesystem storage
  /// - **Network Forward**: Stream to another HTTP connection
  /// - **Compression**: Pipe through GZip or other compression sinks
  /// - **Transformation**: Apply real-time data processing
  /// - **Multiple Outputs**: Use BroadcastSink for fan-out scenarios
  ///
  /// **Parameters:**
  /// - [url]: Source URL to download from
  /// - [sink]: IOSink destination for downloaded data
  /// - [onProgress]: Optional callback for download progress updates
  /// - [headers]: Additional HTTP headers for the request
  /// - [resumeFrom]: Byte offset for partial download resume
  ///
  /// **Important:**
  /// - Caller must manage sink lifecycle (open/close)
  /// - Sink errors are not automatically handled
  /// - For resume functionality, ensure sink is positioned correctly
  ///
  /// **Note:** For simple file downloads, [downloadFile] provides automatic file management.
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

  /// Download content into memory as byte array with progress tracking
  ///
  /// This method downloads content and returns it as a Uint8List in memory. It's
  /// perfect for small to medium-sized files that need to be processed immediately
  /// or when working with APIs that expect byte data.
  ///
  /// **Parameters:**
  /// - [url]: Source URL to download from
  /// - [onProgress]: Optional callback for download progress updates
  /// - [headers]: Additional HTTP headers for the request
  /// - [maxSize]: Maximum allowed download size in bytes (safety limit)
  ///
  /// **Returns:** Complete file content as Uint8List
  ///
  /// **For Large Files:**
  /// Consider using [downloadFile] for direct disk storage or
  /// [downloadWithChunkCallback] for streaming processing to avoid high memory usage.
  ///
  /// **Safety:**
  /// The [maxSize] parameter helps prevent accidental large downloads that could
  /// cause out-of-memory errors.
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

  /// Download with real-time chunk processing callback
  ///
  /// This method enables processing of downloaded data as it arrives, without
  /// accumulating it in memory. Each chunk is immediately passed to the callback
  /// function, making it ideal for streaming scenarios, real-time processing,
  /// or when working with very large files.
  ///
  /// **Parameters:**
  /// - [url]: Source URL to download from
  /// - [onChunk]: Required callback function receiving each data chunk
  /// - [onProgress]: Optional callback for download progress updates
  /// - [headers]: Additional HTTP headers for the request
  ///
  /// **Memory Characteristics:**
  /// - Constant memory usage regardless of file size
  /// - Immediate data availability for processing
  /// - No accumulation or final memory allocation
  /// - Minimal per-chunk memory overhead for type conversion
  /// - Optimal for streaming scenarios
  ///
  /// **Note:** For simple downloads, use [downloadFile] or [downloadBytes] instead.
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
    double lastReportedPercentage = 0.0;

    return originalStream.map<List<int>>((chunk) {
      transferredBytes += chunk.length;

      // Only report progress if it changed meaningfully
      final currentPercentage = transferredBytes / totalSize;
      final isCompleted = transferredBytes >= totalSize;

      // Report progress if:
      // 1. Percentage changed by at least 1%
      // 2. Or transfer is completed
      if (isCompleted ||
          (currentPercentage - lastReportedPercentage).abs() >= 0.01) {
        final progress = TransferProgress(
          current: transferredBytes,
          total: totalSize,
          isCompleted: isCompleted,
        );

        onProgress(progress);
        lastReportedPercentage = currentPercentage;
      }

      return chunk;
    });
  }

  /// Convert bytes to stream
  Stream<List<int>> _bytesToStream(Uint8List data) async* {
    const chunkSize = 64 * 1024; // 64KB chunks
    int offset = 0;

    while (offset < data.length) {
      final end = (offset + chunkSize).clamp(0, data.length);
      // Use buffer.asUint8List() to create a view without copying
      yield Uint8List.view(
          data.buffer, data.offsetInBytes + offset, end - offset);
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
    int lastReportedBytes = initialProgress;
    double lastReportedPercentage = 0.0;

    await for (final chunk in stream) {
      downloadedBytes += chunk.length;

      // Write chunk to sink
      sink.add(chunk);

      // Calculate progress - only report if progress changed meaningfully
      if (onProgress != null) {
        final currentPercentage =
            totalSize != null ? downloadedBytes / totalSize : 0.0;
        final isCompleted = totalSize != null && downloadedBytes >= totalSize;

        // Report progress if:
        // 1. Percentage changed by at least 1%
        // 2. Or download is completed
        // 3. Or bytes changed significantly (for cases without total size)
        if (isCompleted ||
            (currentPercentage - lastReportedPercentage).abs() >= 0.01 ||
            (totalSize == null && downloadedBytes != lastReportedBytes)) {
          final progress = TransferProgress(
            current: downloadedBytes,
            total: totalSize,
            isCompleted: isCompleted,
          );

          onProgress(progress);
          lastReportedBytes = downloadedBytes;
          lastReportedPercentage = currentPercentage;
        }
      }
    }

    // Only send final progress if we haven't already reported completion
    if (onProgress != null &&
        totalSize != null &&
        lastReportedBytes < totalSize) {
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
    // Store original chunk directly for memory efficiency
    // The chunks will be processed later in downloadBytes
    _chunks.add(chunk);
  }
}

/// Sink that calls a callback for each chunk
class _CallbackSink implements _DataSink {
  final DataChunkCallback _callback;

  _CallbackSink(this._callback);

  @override
  void add(List<int> chunk) {
    // Pass chunk directly if it's already a Uint8List, otherwise convert
    if (chunk is Uint8List) {
      _callback(chunk);
    } else {
      _callback(Uint8List.fromList(chunk));
    }
  }
}

/// Extension to IOSink to make it work with _DataSink
extension _IOSinkDataSink on IOSink {
  _DataSink get _asDataSink => _IODataSink(this);
}
