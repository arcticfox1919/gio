

import 'dart:async';
import 'package:gio/gio.dart';
import 'mock_request.dart';

typedef Handler = FutureOr<Response> Function(MockRequest request);