
import 'package:gio_mock/gio_mock.dart';
import 'package:gio_mock/src/http/response_x.dart';

class MyMockChannel extends MockChannel{

  @override
  void entryPoint() {
    get("/greet",(MockRequest request){
      return ResponseX.ok("hello,${request.query['name']}");
    });

    post("/login",(MockRequest request){
      return ResponseX.ok(request.bodyFields);
    });

    post("/list",(MockRequest request){
      return ResponseX.ok(request.body);
    });
  }
}