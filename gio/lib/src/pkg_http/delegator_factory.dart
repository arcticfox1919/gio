import '../http_delegator.dart';
import '../gio_config.dart';

// Conditional factory that creates a package:http-based delegator per platform.
import 'pkg_http_stub.dart'
    if (dart.library.html) 'browser_delegator.dart'
    if (dart.library.io) 'io_delegator.dart';

HttpDelegator createPkgHttpDelegator([GioConfig? config]) =>
    createPkgHttpDelegatorImpl(config);
