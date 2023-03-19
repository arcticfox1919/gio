import 'package:gio/src/gio_context.dart';
import 'package:gio/src/interceptor/connect_interceptor.dart';

import 'interceptor/interceptor.dart';
import 'interceptor/log_interceptor.dart';
import 'interceptor/mock_interceptor.dart';

class GioProxy {
  final String host;
  final String port;

  GioProxy(this.host, this.port);
}

class GioOption {
  final String basePath;
  final bool enableLog;
  final Map<String, dynamic>? headers;
  final List<Interceptor> globalInterceptors;
  final GioProxy? proxy;
  final GioContext? context;
  final GioLogInterceptor? logInterceptor;
  final GioConnectInterceptor? connectInterceptor;
  final GioMockInterceptor? mockInterceptor;

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
  });

  GioOption copyWith({
    String? basePath,
    bool enableLog = true,
    Map<String, dynamic>? headers,
    List<Interceptor>? globalInterceptors,
    GioProxy? proxy,
    GioContext? context,
    GioLogInterceptor? logInterceptor,
    GioConnectInterceptor? connectInterceptor,
    GioMockInterceptor? mockInterceptor,
  }) {
    return GioOption(
      basePath: basePath ?? this.basePath,
      enableLog: this.enableLog,
      headers: headers ?? this.headers,
      globalInterceptors: globalInterceptors ?? this.globalInterceptors,
      proxy: proxy ?? this.proxy,
      context: context ?? this.context,
      logInterceptor: this.logInterceptor,
      connectInterceptor: this.connectInterceptor,
      mockInterceptor: this.mockInterceptor,
    );
  }
}
