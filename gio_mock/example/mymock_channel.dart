
import 'package:gio_mock/src/http/response_x.dart';
import 'package:gio_mock/src/mock_channel.dart';

class MyMockChannel extends MockChannel{

  @override
  void entryPoint() {
    get("/hello",(request){
      return ResponseX.ok("hello,GioMock !");
    });
  }

}