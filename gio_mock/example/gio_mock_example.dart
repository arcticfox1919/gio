import 'package:gio/gio.dart';
import 'package:gio_mock/src/gio_mock_server.dart';

import 'mymock_channel.dart';

void main() async {
  Gio.option = GioOption(
      enableLog: false,
      basePath: 'https://www.gio.com',
      mockInterceptor: GioMockServer(MyMockChannel()));
  Gio gio = Gio();
  var resp = await gio.get("/hello");

  print(resp.body);
  gio.close();
}
