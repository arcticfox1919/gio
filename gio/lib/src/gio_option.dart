import 'package:gio/src/gio_context.dart';
import 'package:gio/src/interceptor/connect_interceptor.dart';
import 'package:gio/src/pkg_http/http_delegator.dart';
import 'package:gio/src/gio_config.dart';

import 'interceptor/interceptor.dart';
import 'interceptor/log_interceptor.dart';
import 'interceptor/mock_interceptor.dart';

/// Network proxy settings for the HTTP client.
///
/// Example: `GioProxy('127.0.0.1', '8888')`.
class GioProxy {
  /// Proxy host, IPv4/IPv6/domain supported.
  final String host;

  /// Proxy port as a string (to preserve leading zeros if any).
  final String port;

  GioProxy(this.host, this.port);
}

/// Global configuration for `Gio` clients.
///
/// This object controls base URL, logging, global interceptors, proxy,
/// execution context, and transport factory. Provide it once via
/// `Gio.option = GioOption(...)` or pass specific values per client.
class GioOption {
  /// The base URL prefix used to resolve relative request paths.
  /// Example: `https://api.example.com`.
  final String basePath;

  /// Controls whether a logging interceptor should be added by default.
  ///
  /// Semantics:
  /// - When true, a default [GioLogInterceptor] is added unless a custom
  ///   [logInterceptor] is provided (custom takes precedence).
  /// - When false, no logger is added unless [logInterceptor] is explicitly
  ///   provided.
  final bool enableLog;

  /// Default headers to merge into each request.
  final Map<String, dynamic>? headers;

  /// Interceptors applied to every client instance globally.
  final List<Interceptor> globalInterceptors;

  /// Optional HTTP proxy settings.
  final GioProxy? proxy;

  /// Execution context to carry platform-dependent options (IO/browser).
  final GioContext? context;

  /// Custom log interceptor.
  ///
  /// If this is provided, it will be used regardless of [enableLog].
  /// If this is null and [enableLog] is true, a default `GioLogInterceptor`
  /// will be created and added.
  final GioLogInterceptor? logInterceptor;

  /// Connectivity check interceptor. If null, `DefaultConnectInterceptor` is used.
  final GioConnectInterceptor? connectInterceptor;

  /// Mock interceptor to short-circuit network requests for testing.
  final GioMockInterceptor? mockInterceptor;

  /// Custom delegator factory to build the transport layer
  /// (e.g., package:http, http/3, native IO/XHR).
  final HttpDelegator Function(GioConfig config)? delegatorFactory;

  GioOption({
    this.basePath = '',
    this.enableLog = false,
    this.headers,
    this.proxy,
    this.context,
    this.logInterceptor,
    this.connectInterceptor,
    this.mockInterceptor,
    this.globalInterceptors = const [],
    this.delegatorFactory,
  });

  /// Returns a new [GioOption] with selected fields replaced.
  GioOption copyWith({
    String? basePath,
    bool? enableLog,
    Map<String, dynamic>? headers,
    List<Interceptor>? globalInterceptors,
    GioProxy? proxy,
    GioContext? context,
    GioLogInterceptor? logInterceptor,
    GioConnectInterceptor? connectInterceptor,
    GioMockInterceptor? mockInterceptor,
    HttpDelegator Function(GioConfig config)? delegatorFactory,
  }) {
    return GioOption(
      basePath: basePath ?? this.basePath,
      enableLog: enableLog ?? this.enableLog,
      headers: headers ?? this.headers,
      globalInterceptors: globalInterceptors ?? this.globalInterceptors,
      proxy: proxy ?? this.proxy,
      context: context ?? this.context,
      logInterceptor: logInterceptor ?? this.logInterceptor,
      connectInterceptor: connectInterceptor ?? this.connectInterceptor,
      mockInterceptor: mockInterceptor ?? this.mockInterceptor,
      delegatorFactory: delegatorFactory ?? this.delegatorFactory,
    );
  }
}
