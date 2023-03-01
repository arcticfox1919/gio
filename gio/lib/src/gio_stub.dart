import 'package:http_parser/http_parser.dart';

import 'gio_config.dart';
import 'gio_context.dart';
import 'http_delegator.dart';
import 'multipart_file.dart';

/// Implemented in `browser_delegator.dart` and `io_delegator.dart`.
HttpDelegator createHttpDelegator([GioConfig? config]) => throw UnsupportedError(
    'Cannot create a client without dart:html or dart:io.');


Future<MultipartFile> multipartFileFromPath(String field, String filePath,
    {String? filename, MediaType? contentType}) =>
    throw UnsupportedError(
        'MultipartFile is only supported where dart:io is available.');

GioContext? createGioContext() => throw UnsupportedError(
    'Cannot create a GioContext without dart:io.');