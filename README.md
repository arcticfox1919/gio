# Gio

This is a powerful http request library from Dart. It has a chain call interceptor, through which we can implement many functions.

For example, it provides an interceptor to mock the back-end response. This allows us to quickly build and debug the UI without relying on the progress of the back-end programmer.

## Usage

### Quick Start

```yaml
dependencies:
  gio: latest
```

```dart
import 'dart:convert';

import 'package:gio/gio.dart' as gio;

void main() async {
  var resp =
      await gio.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
  print(resp.body);

  /// GET http://example.com?a=1&b=2
  resp = await gio.get("http://example.com", queryParameters: {"a": "1", "b": "2"});
  print(resp.request?.url);


  /// POST Form Data
  var data = {"username": "Bob", "passwd": "123456"};
  var header = {"content-type":"application/x-www-form-urlencoded"};
  resp = await gio.post("http://example.com", headers: header,body: data);
  print(resp.body);

  /// POST JSON Data
  /// Note: if JSON data is passed, 
  /// then body should be a string type
  var data2 = {"name": "Bob", "age": "22"};
  var header2 = {"content-type":"application/json"};
  resp = await gio.post("http://example.com", headers: header,body: jsonEncode(data));
  print(resp.body);
}
```

You can also use Gio like the following, where you can reuse this connection before it is closed:
```dart
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
```


### Global Configuration

We can use `GioOption` to set a global base url:
```dart
import 'package:gio/gio.dart' as gio;

void main() async{
  gio.Gio.option = gio.GioOption(
      basePath: 'https://giomock.io',
      enableLog: true
  );

  // equivalent to https://giomock.io/greet
  var resp = await gio.get("/greet", queryParameters: {'name': 'Bob'});
  print(resp.body);
}
```
Set `enableLog` to `true` to enable the global log for easy tracking of requests.

Note here that if you have `basePath` configured in `GioOption` but you are not applying this `basePath` in some request, then you need to override this parameter in the request as follows:

```dart
import 'package:gio/gio.dart';

void main() async {
  Gio.option = GioOption(
      basePath: 'https://giomock.io',
      enableLog: true
  );

  // Set the `baseUrl` of `Gio` to an empty string
  // to override the global configuration
  Gio gio = Gio(baseUrl: '');
  try{
    var resp = await gio.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
    print(resp.body);
  }finally{
    gio.close();
  }
}
```

### Interceptor
An interceptor type, i.e., a function or closure that matches the following signature:

```dart
typedef Interceptor = Future<StreamedResponse> Function(Chain chain);
```

Gio interceptors are divided into three types

- global interceptor
- local interceptor
- default interceptor

Note that among these three types of interceptors, the local interceptor is called first, followed by the global interceptor, and finally the default interceptor.

#### Global Interceptor
Global interceptors are valid globally, set with `GioOption`:

```dart
void main() async {
  // declare an interceptor
  checkHeader(gio.Chain chain) {
    var auth = chain.request.headers['Authorization'];
    // When the condition is met, continue to execute the next interceptor, 
    // otherwise, interrupt the request
    if (auth != null && auth.isNotEmpty) {
      return chain.proceed(chain.request);
    }
    throw Exception('Invalid request, does not contain Authorization!');
  }

  // the parameter is a list, multiple interceptors can be set
  gio.Gio.option = gio.GioOption(
      basePath: 'http://worldtimeapi.org', 
      globalInterceptors: [checkHeader]);

  try {
    var resp = await gio.get("/api/timezone/Asia/Shanghai");
    print(resp.body);
  } catch (e) {
    print(e);
  }
}
```

```shell
Exception: Invalid request, does not contain Authorization!

Process finished with exit code 0
```

#### Local interceptor
Local interceptors can also add multiple:
```dart
import 'package:gio/gio.dart';

void main() async {
  Gio gio = Gio();

  // Intercept the request and modify the request header
  gio.addInterceptor((chain) {
    if (chain.request.method == "POST") {
      chain.request.headers["content-type"] = "application/json";
    }
    return chain.proceed(chain.request);
  });

  // Intercept the response and do some business processing here
  gio.addInterceptor((chain) async {
    var res = await chain.proceed(chain.request);
    if (res.statusCode != 200) {
      throw Exception(
          "The request is unsuccessful, the status code is ${res.statusCode}");
    }
    return res;
  });

  try {
    var resp =
    await gio.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
    print(resp.body);
  } catch (e) {
    print(e);
  } finally {
    gio.close();
  }
}
```

We can also put the interceptor logic into a class instead of a closure, which can better organize our code.

Here we implement an example of canceling the request, when the user leaves the view, the result of the request may no longer be needed:

`cancel_interceptor.dart`

```dart
import 'package:gio/gio.dart';

class CancelInterceptor {
  bool _isCancel = false;

  void cancel() {
    _isCancel = true;
  }

  Future<StreamedResponse> call(Chain chain) async {
    if (_isCancel) {
      throw CancelError("User initiated cancellation.");
    }
    var res = await chain.proceed(chain.request);
    if (_isCancel) {
      throw CancelError("User initiated cancellation.");
    }
    return res;
  }
}
```

`main.dart`
```dart
import 'package:gio/gio.dart';

void main(){
  var cancelInterceptor = CancelInterceptor();
  testCancel(cancelInterceptor);
  cancelInterceptor.cancel();
}

Future<void> testCancel(CancelInterceptor cancel) async {
  Gio g = Gio();
  g.addInterceptor(cancel);
  try {
    var res = await g.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
    print(res.body);
  } on CancelError {
    print("request has been canceled");
  } finally {
    g.close();
  }
}
```

##### Group Interceptors

Interceptors allow us to use a uniform way of handling network requests, but sometimes we may need to customize network requests based on modules. Grouped interceptors are used in just such scenarios.

```dart
import 'package:gio/gio.dart' as gio;

void main() async {
  // Setting up group interceptors
  gio.group("module1").addInterceptor(CancelInterceptor());
  gio.group("module2").addInterceptor(ModifyHeaderInterceptor());

  var module1 = gio.GioGroup("module1");
  try{
    var resp = module1.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
    print(resp);
  }catch(e){
    print(e);
  }finally{
    module1.close();
  }

  var module2 = gio.GioGroup("module2");
  try{
    var resp = module2.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
    print(resp);
  }catch(e){
    print(e);
  }finally{
    module2.close();
  }
}
```

#### Default Interceptor
The default interceptor refers to several interceptors included in `GioOption`, they are:

- `GioLogInterceptor`
- `GioConnectInterceptor`
- `GioMockInterceptor`

We can customize these interceptors to replace the default interceptors:

```dart
import 'package:gio/gio.dart';

void main() async {
  Gio.option = GioOption(
    connectInterceptor: MyConnectInterceptor(),
    logInterceptor: MyLogInterceptor()
  );

  Gio gio = Gio();
  try{
    var resp = await gio.get("http://worldtimeapi.org/api/timezone/Asia/Shanghai");
    print(resp.body);
  }finally{
    gio.close();
  }
}

class MyConnectInterceptor extends GioConnectInterceptor{

  @override
  Future<bool> checkConnectivity() {
    // TODO: Check here whether the current network is connected
      throw ConnectiveError(101,"Mobile Network Data disabled !");
      // or
      // throw ConnectiveError(102,"Wifi disabled !");
  }
}

class MyLogInterceptor extends GioLogInterceptor{
  @override
  Future<StreamedResponse> call(Chain chain) async {
    final request = chain.request;
    // _logRequest(request);
    try {
      final response = await chain.proceed(request);
      // _logResponse(response);
      return response;
    } catch (e) {
      // _logUnknownError(e, request);
      rethrow;
    }
  }
}
```
Note that default interceptors are also globally available.

Here, we can implement log tracking in the interceptor and request time-consuming monitoring. You can refer to the source code of [`GioLogInterceptor`](https://github.com/arcticfox1919/gio/blob/main/gio/lib/src/interceptor/log_interceptor.dart).
### Mock Response
Mock Response is a very useful feature when you want to develop the UI first or test and debug the UI without a service backend.

```yaml
dependencies:
  gio: latest
  gio_mock: latest
```

To use the feature of mocking the backend response, you need to set the `mockInterceptor` parameter, as in the example:
```dart
void main() async{
  gio.Gio.option = gio.GioOption(
      basePath: 'https://giomock.io',
      mockInterceptor: GioMockServer(MyMockChannel()));

  var resp = await gio.get("/greet", queryParameters: {'name': 'Bob'});
  print(resp.body);

  var data = {"username": "Bob", "passwd": "123456"};
  var header = {"content-type":"application/x-www-form-urlencoded"};
  resp = await gio.post("/login", headers: header,body: data);
  print(resp.body);

  var data2 = {
    "array":[
      {
        "name":"Go",
        "url":"https://go.dev/",
      },
      {
        "name":"Dart",
        "url":"https://dart.dev/",
      },
    ]
  };
  header = {"content-type":"application/json"};
  resp = await gio.post("/list", headers: header,body: jsonEncode(data2));
  print(resp.body);
}
```
Next you need to create the `MyMockChannel`:

```dart
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
```

We need to register routes in the `entryPoint` method, you can use methods such as `get`/`post` to register routes for HTTP requests.

The second parameter to these methods is a handler for the route response, where you can process the request parameters and return the response.

