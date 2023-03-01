import 'package:gio/gio.dart' as gio;

void main() async {
  var resp =
      await gio.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
  print(resp.statusCode);
  // print(resp.headers);
  // print(resp.body);
}
