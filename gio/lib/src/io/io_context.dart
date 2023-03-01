import 'dart:io';

import '../gio_context.dart';

GioContext? createGioContext() => IOContext();

class IOContext implements GioContext {

  @override
  get context => SecurityContext.defaultContext;

  @override
  bool get allowLegacyUnsafeRenegotiation =>
      context.allowLegacyUnsafeRenegotiation;

  @override
  void setAlpnProtocols(List<String> protocols, bool isServer) {
    context.setAlpnProtocols(protocols, isServer);
  }

  @override
  void setClientAuthorities(String file, {String? password}) {
    context.setClientAuthorities(file, password: password);
  }

  @override
  void setClientAuthoritiesBytes(List<int> authCertBytes, {String? password}) {
    context.setClientAuthoritiesBytes(authCertBytes, password: password);
  }

  @override
  void setTrustedCertificates(String file, {String? password}) {
    context.setTrustedCertificates(file, password: password);
  }

  @override
  void setTrustedCertificatesBytes(List<int> certBytes, {String? password}) {
    context.setTrustedCertificatesBytes(certBytes, password: password);
  }

  @override
  void useCertificateChain(String file, {String? password}) {
    context.useCertificateChain(file, password: password);
  }

  @override
  void useCertificateChainBytes(List<int> chainBytes, {String? password}) {
    context.useCertificateChainBytes(chainBytes, password: password);
  }

  @override
  void usePrivateKey(String file, {String? password}) {
    context.usePrivateKey(file, password: password);
  }

  @override
  void usePrivateKeyBytes(List<int> keyBytes, {String? password}) {
    context.usePrivateKeyBytes(keyBytes, password: password);
  }

  @override
  set allowLegacyUnsafeRenegotiation(bool b) {
    context.allowLegacyUnsafeRenegotiation = b;
  }
}
