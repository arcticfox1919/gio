import 'gio_stub.dart'
if (dart.library.html) 'web/browser_context.dart'
if (dart.library.io) 'io/io_context.dart';


///
///
///
abstract class GioContext{
  dynamic get context;

  /// Sets the private key for a server certificate or client certificate.
  ///
  /// A secure connection using this SecurityContext will use this key with
  /// the server or client certificate to sign and decrypt messages.
  /// [file] is the path to a PEM or PKCS12 file containing an encrypted
  /// private key, encrypted with [password]. Assuming it is well-formatted, all
  /// other contents of [file] are ignored. An unencrypted file can be used,
  /// but this is not usual.
  ///
  /// NB: This function calls [File.readAsBytesSync], and will block on file IO.
  /// Prefer using [usePrivateKeyBytes].
  ///
  /// iOS note: Only PKCS12 data is supported. It should contain both the private
  /// key and the certificate chain. On iOS one call to [usePrivateKey] with this
  /// data is used instead of two calls to [useCertificateChain] and
  /// [usePrivateKey].
  void usePrivateKey(String file, {String? password});

  /// Sets the private key for a server certificate or client certificate.
  ///
  /// Like [usePrivateKey], but takes the contents of the file as a list
  /// of bytes.
  void usePrivateKeyBytes(List<int> keyBytes, {String? password});

  /// Add a certificate to the set of trusted X509 certificates
  /// used by [SecureSocket] client connections.
  ///
  /// [file] is the path to a PEM or PKCS12 file containing X509 certificates,
  /// usually root certificates from certificate authorities. For PKCS12 files,
  /// [password] is the password for the file. For PEM files, [password] is
  /// ignored. Assuming it is well-formatted, all other contents of [file] are
  /// ignored.
  ///
  /// NB: This function calls [File.readAsBytesSync], and will block on file IO.
  /// Prefer using [setTrustedCertificatesBytes].
  ///
  /// iOS note: On iOS, this call takes only the bytes for a single DER
  /// encoded X509 certificate. It may be called multiple times to add
  /// multiple trusted certificates to the context. A DER encoded certificate
  /// can be obtained from a PEM encoded certificate by using the openssl tool:
  /// ```bash
  /// $ openssl x509 -outform der -in cert.pem -out cert.der
  /// ```
  void setTrustedCertificates(String file, {String? password});

  /// Add a certificate to the set of trusted X509 certificates
  /// used by [SecureSocket] client connections.
  ///
  /// Like [setTrustedCertificates] but takes the contents of the file.
  void setTrustedCertificatesBytes(List<int> certBytes, {String? password});

  /// Sets the chain of X509 certificates served by [SecureServerSocket]
  /// when making secure connections, including the server certificate.
  ///
  /// [file] is a PEM or PKCS12 file containing X509 certificates, starting with
  /// the root authority and intermediate authorities forming the signed
  /// chain to the server certificate, and ending with the server certificate.
  /// The private key for the server certificate is set by [usePrivateKey]. For
  /// PKCS12 files, [password] is the password for the file. For PEM files,
  /// [password] is ignored. Assuming it is well-formatted, all
  /// other contents of [file] are ignored.
  ///
  /// NB: This function calls [File.readAsBytesSync], and will block on file IO.
  /// Prefer using [useCertificateChainBytes].
  ///
  /// iOS note: As noted above, [usePrivateKey] does the job of both
  /// that call and this one. On iOS, this call is a no-op.
  void useCertificateChain(String file, {String? password});

  /// Sets the chain of X509 certificates served by [SecureServerSocket]
  /// when making secure connections, including the server certificate.
  ///
  /// Like [useCertificateChain] but takes the contents of the file.
  void useCertificateChainBytes(List<int> chainBytes, {String? password});

  /// Sets the list of authority names that a [SecureServerSocket] will advertise
  /// as accepted when requesting a client certificate from a connecting
  /// client.
  ///
  /// The [file] is a PEM or PKCS12 file containing the accepted signing
  /// authority certificates - the authority names are extracted from the
  /// certificates. For PKCS12 files, [password] is the password for the file.
  /// For PEM files, [password] is ignored. Assuming it is well-formatted, all
  /// other contents of [file] are ignored.
  ///
  /// NB: This function calls [File.readAsBytesSync], and will block on file IO.
  /// Prefer using [setClientAuthoritiesBytes].
  ///
  /// iOS note: This call is not supported.
  void setClientAuthorities(String file, {String? password});

  /// Sets the list of authority names that a [SecureServerSocket] will advertise
  /// as accepted, when requesting a client certificate from a connecting
  /// client.
  ///
  /// Like [setClientAuthorities] but takes the contents of the file.
  void setClientAuthoritiesBytes(List<int> authCertBytes, {String? password});

  /// Sets the list of application-level protocols supported by a client
  /// connection or server connection. The ALPN (application level protocol
  /// negotiation) extension to TLS allows a client to send a list of
  /// protocols in the TLS client hello message, and the server to pick
  /// one and send the selected one back in its server hello message.
  ///
  /// Separate lists of protocols can be sent for client connections and
  /// for server connections, using the same SecurityContext.  The [isServer]
  /// boolean argument specifies whether to set the list for server connections
  /// or client connections.
  void setAlpnProtocols(List<String> protocols, bool isServer);

  /// If `true`, the [SecurityContext] will allow TLS renegotiation.
  /// Renegotiation is only supported as a client and the HelloRequest must be
  /// received at a quiet point in the application protocol. This is sufficient
  /// to support the legacy use case of requesting a new client certificate
  /// between an HTTP request and response in (unpipelined) HTTP/1.1.
  /// NOTE: Renegotiation is an extremely problematic protocol feature and
  /// should only be used to communicate with legacy servers in environments
  /// where it is known to be safe.
  abstract bool allowLegacyUnsafeRenegotiation;
}

GioContext? get defaultContext => createGioContext();