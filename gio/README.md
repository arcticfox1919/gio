# Gio

**A powerful HTTP client library for Dart, built on top of `package:http`.**

Gio extends the standard `http` package with advanced features like interceptors, request/response logging, and seamless API mocking capabilities. Designed for modern Dart applications, Gio simplifies HTTP communication while providing enterprise-grade flexibility.

## Features

- **Built on `package:http`** - Reliable foundation with familiar APIs
- **Interceptor Chain** - Transform requests/responses with ease
- **Smart Logging** - Stream-safe logging with configurable output
- **API Mocking** - Build UIs without backend dependencies
- **Global Configuration** - Base URLs, headers, and settings
- **Independent Clients** - Multiple clients with separate configurations
- **Lightweight** - Minimal overhead, maximum functionality
- **Simple API** - Get started in minutes

## Quick Start

Add Gio to your `pubspec.yaml`:

```yaml
dependencies:
  gio: latest
```

### Basic Usage

```dart
import 'package:gio/gio.dart' as gio;

void main() async {
  // Simple GET request
  var response = await gio.get("https://api.example.com/users");
  print(response.body);

  // GET with query parameters
  response = await gio.get(
    "https://api.example.com/search", 
    queryParameters: {"q": "dart", "limit": "10"}
  );

  // POST with form data
  response = await gio.post(
    "https://api.example.com/login",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: {"username": "john", "password": "secret"}
  );

  // POST with JSON data
  response = await gio.post(
    "https://api.example.com/users",
    headers: {"content-type": "application/json"},
    body: jsonEncode({"name": "John Doe", "age": 30})
  );
}
```

### Reusable Client

For multiple requests, create a reusable client:

```dart
import 'package:gio/gio.dart';

void main() async {
  final client = Gio();
  try {
    final response = await client.get("https://api.example.com/data");
    print(response.body);
  } finally {
    client.close(); // Always clean up resources
  }
}
```

### Independent Client Configuration

Use `Gio.withOption()` to create a client with custom configuration independent of global settings:

```dart
import 'package:gio/gio.dart';

void main() async {
  // Create client with custom configuration
  final customClient = Gio.withOption(GioOption(
    basePath: 'https://api.custom.com',
    enableLog: false,
    headers: {'Authorization': 'Bearer token123'},
    connectTimeout: Duration(seconds: 10),
  ));

  // Create another client with different configuration
  final debugClient = Gio.withOption(GioOption(
    basePath: 'https://debug.api.com',
    enableLog: true,
    logInterceptor: GioLogInterceptor(
      useLogging: true,
      maxLogBodyBytes: 2048,
    ),
  ));

  try {
    // Each client uses its own configuration
    final response1 = await customClient.get("/users");
    final response2 = await debugClient.get("/debug/status");
    
    print("Custom API: ${response1.body}");
    print("Debug API: ${response2.body}");
  } finally {
    customClient.close();
    debugClient.close();
  }
}
```

**Benefits of `Gio.withOption()`:**
- **Independent Configuration**: Each client maintains its own settings
- **No Global Interference**: Changes don't affect global `Gio.option`
- **Modular Design**: Different modules can have different HTTP configurations

## Configuration

### Global Settings

Configure base URL, logging, and other global options:

```dart
import 'package:gio/gio.dart' as gio;

void main() async {
  // Configure global options
  gio.Gio.option = gio.GioOption(
    basePath: 'https://api.example.com',
    enableLog: true,
    headers: {'User-Agent': 'MyApp/1.0'},
  );

  // Requests now use the base path
  final response = await gio.get("/users/123"); // → https://api.example.com/users/123
  print(response.body);
}
```

### Custom Logging

Enable structured logging with `package:logging`:

```dart
import 'package:logging/logging.dart';
import 'package:gio/gio.dart';

void main() async {
  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    // Persist to file, send to analytics, etc.
  });

  Gio.option = GioOption(
    logInterceptor: GioLogInterceptor(
      useLogging: true,
      loggerName: 'gio',
      maxLogBodyBytes: 1024,
    ),
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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.