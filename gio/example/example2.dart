

import 'package:gio/gio.dart';


void main() async{
  Gio gio = Gio();
  try{
    var resp = await gio.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
    print(resp.body);
  }finally{
    gio.close();
  }
}
