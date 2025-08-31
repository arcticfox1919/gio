import 'package:gio/gio.dart';

void main() async {
  Gio.option = GioOption(enableLog: true);
  Gio gio = Gio();
  try {
    var resp = await gio.get("https://httpbin.org/get");
    print(resp.body);
  } finally {
    gio.close();
  }
}
