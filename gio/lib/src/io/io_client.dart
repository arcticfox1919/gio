// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:gio/src/gio_client.dart';
import 'package:gio/src/gio_config.dart';
import 'package:gio/src/http_delegator.dart';
import 'package:gio/src/io/io_delegator.dart';

class GIO extends Gio{

  final HttpClient client;

  GIO(this.client);


  @override
  HttpDelegator createDelegator(GioConfig config) => IODelegator(client: client);
}
