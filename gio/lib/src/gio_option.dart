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
  String basePath;
  final bool enableLog;
  final Map<String, dynamic>? headers;
  final List<Interceptor> globalInterceptors;
  final GioProxy? proxy;
  final GioLogInterceptor? logInterceptor;
  final GioConnectInterceptor? connectInterceptor;
  final GioMockInterceptor? mockInterceptor;

  GioOption({
    required this.basePath,
    this.enableLog = false,
    this.headers,
    this.proxy,
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
      logInterceptor: this.logInterceptor,
      connectInterceptor: this.connectInterceptor,
      mockInterceptor: this.mockInterceptor,
    );
  }
}
