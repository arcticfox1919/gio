import 'package:gio/gio.dart';

void main() async {
  Gio.option = GioOption(basePath: 'https://giomock.io', enableLog: true);

  // Set the `baseUrl` of `Gio` to an empty string
  // to override the global configuration
  Gio gio = Gio(baseUrl: '');
  try {
    var resp =
        await gio.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
    print(resp.body);
  } finally {
    gio.close();
  }
}
