import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

/// A JSON codec with optional background processing capability
///
/// This codec provides JSON encoding/decoding with the ability to offload heavy
/// JSON operations to a background isolate, preventing UI thread blocking in Flutter apps.
/// Features include:
/// - Automatic fallback to main thread for lightweight operations
/// - Background isolate for heavy JSON processing to maintain UI responsiveness
/// - Intelligent resource management with automatic cleanup after idle periods
class GioJsonCodec {
  static GioJsonCodec? _instance;

  factory GioJsonCodec() {
    return _instance ??= GioJsonCodec._();
  }

  GioJsonCodec._();

  _JsonWorker? _worker;
  Timer? _idleTimer;

  /// Idle timeout duration (default 60 seconds)
  var _idleTimeout = const Duration(seconds: 60);

  /// Get the current idle timeout duration
  Duration get idleTimeout => _idleTimeout;

  /// Set the idle timeout duration
  ///
  /// When the worker is idle for this duration, it will be automatically destroyed
  /// to free up resources. The worker will be recreated when needed again.
  set idleTimeout(Duration duration) {
    _idleTimeout = duration;
    // If timer is active, reset it with the new duration
    if (_idleTimer != null) {
      _resetIdleTimer();
    }
  }

  /// Ensure Worker is initialized
  Future<_JsonWorker> _ensureWorker() async {
    if (_worker != null && !_worker!._closed) {
      _resetIdleTimer();
      return _worker!;
    }

    _worker = await _JsonWorker.spawn();
    _resetIdleTimer();
    return _worker!;
  }

  /// Reset idle timer
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _destroyWorker);
  }

  /// Destroy Worker
  void _destroyWorker() {
    _worker?.close();
    _worker = null;
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// JSON encoding
  ///
  /// Performs JSON encoding in background Isolate to avoid blocking UI thread
  ///
  /// [data] Data object to encode
  /// [parallel] Whether to use parallel processing, defaults to false for main thread processing
  /// Returns encoded JSON string
  Future<String> encode(dynamic data, {bool parallel = false}) async {
    if (!parallel) {
      return jsonEncode(data);
    }

    try {
      final worker = await _ensureWorker();
      final result = await worker.encode(data);
      _resetIdleTimer();
      return result;
    } catch (e) {
      return jsonEncode(data);
    }
  }

  /// JSON decoding
  ///
  /// Performs JSON decoding in background Isolate to avoid blocking UI thread
  ///
  /// [jsonString] JSON string to decode
  /// [parallel] Whether to use parallel processing, defaults to false for main thread processing
  /// Returns decoded data object
  Future<dynamic> decode(String jsonString, {bool parallel = false}) async {
    if (!parallel) {
      return jsonDecode(jsonString);
    }

    try {
      final worker = await _ensureWorker();
      final result = await worker.decode(jsonString);
      _resetIdleTimer();
      return result;
    } catch (e) {
      return jsonDecode(jsonString);
    }
  }

  /// Immediately destroy Worker (for cleanup when application closes)
  void dispose() {
    _destroyWorker();
  }
}

/// JSON encoding/decoding task types
enum _JsonTaskType { encode, decode }

/// Worker control command types
enum _WorkerCommand { shutdown }

/// JSON processing Worker implementation based on official Dart Isolate examples
class _JsonWorker {
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  /// Execute JSON encoding
  Future<String> encode(dynamic data) async {
    if (_closed) throw StateError('Worker is closed');

    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, _JsonTaskType.encode, data));

    final result = await completer.future;
    if (result is String) {
      return result;
    }
    throw StateError('Expected String result, got ${result.runtimeType}');
  }

  /// Execute JSON decoding
  Future<dynamic> decode(String jsonString) async {
    if (_closed) throw StateError('Worker is closed');

    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, _JsonTaskType.decode, jsonString));

    return await completer.future;
  }

  /// Create new JSON Worker
  static Future<_JsonWorker> spawn() async {
    // Create receive port and add initial message handler
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();

    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    // Start Isolate
    try {
      await Isolate.spawn(_startRemoteIsolate, initPort.sendPort);
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;
    return _JsonWorker._(receivePort, sendPort);
  }

  _JsonWorker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  /// Handle responses from Isolate
  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id);

    if (completer == null) return;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (_closed && _activeRequests.isEmpty) {
      _responses.close();
    }
  }

  /// Handle commands sent to the Isolate
  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) {
    receivePort.listen((message) {
      // Handle control commands
      if (message is _WorkerCommand) {
        switch (message) {
          case _WorkerCommand.shutdown:
            receivePort.close();
            return;
        }
      }

      // Handle JSON tasks
      final (int id, _JsonTaskType taskType, dynamic data) =
          message as (int, _JsonTaskType, dynamic);

      try {
        Object? result;
        switch (taskType) {
          case _JsonTaskType.encode:
            result = jsonEncode(data);
            break;
          case _JsonTaskType.decode:
            result = jsonDecode(data);
            break;
        }
        sendPort.send((id, result));
      } catch (e, s) {
        sendPort.send((id, RemoteError(e.toString(), s.toString())));
      }
    });
  }

  /// Start remote Isolate
  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  /// Close the Worker
  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send(_WorkerCommand.shutdown);
      if (_activeRequests.isEmpty) {
        _responses.close();
      }
    }
  }
}
