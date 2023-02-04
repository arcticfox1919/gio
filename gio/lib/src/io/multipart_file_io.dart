
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../byte_stream.dart';
import '../multipart_file.dart';

Future<MultipartFile> multipartFileFromPath(String field, String filePath,
    {String? filename, MediaType? contentType}) async {
  filename ??= p.basename(filePath);
  var file = File(filePath);
  var length = await file.length();
  var stream = ByteStream(file.openRead());
  return MultipartFile(field, stream, length,
      filename: filename, contentType: contentType);
}
