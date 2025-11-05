import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:repeat_flutter/common/string_util.dart';
import 'path.dart';

class SelfSsl {
  static final String certFile = 'cert.pem';
  static final String keyFile = 'key.pem';

  static Future<void> tryGenerateSelfSignedCert(
    String rootPath,
    Future<int> Function() getGenerateSslTime,
    Future<void> Function(int) setGenerateSslTime,
  ) async {
    final certPath = rootPath.joinPath(certFile);
    final keyPath = rootPath.joinPath(keyFile);

    final exists = File(certPath).existsSync();
    bool needGenerate = false;

    if (exists) {
      final generateSslTime = await getGenerateSslTime();

      final last = DateTime.fromMillisecondsSinceEpoch(generateSslTime);
      final now = DateTime.now();

      final isExpired = now.difference(last).inDays >= 30;

      if (isExpired) {
        File(certPath).deleteSync();
        File(keyPath).deleteSync();
        needGenerate = true;
      }
    } else {
      needGenerate = true;
    }

    if (needGenerate) {
      await generateSelfSignedCert(rootPath);

      final now = DateTime.now();
      await setGenerateSslTime(now.millisecondsSinceEpoch);
    }
  }

  static Future<void> generateSelfSignedCert(String rootPath) async {
    final pair = CryptoUtils.generateRSAKeyPair();
    final privateKey = pair.privateKey as RSAPrivateKey;
    final publicKey = pair.publicKey as RSAPublicKey;
    final subject = {
      'CN': 'CN-${StringUtil.generateRandomString(6)}',
      'O': 'O-${StringUtil.generateRandomString(6)}',
      'L': 'L-${StringUtil.generateRandomString(6)}',
      'ST': 'ST-${StringUtil.generateRandomString(6)}',
      'C': 'C-${StringUtil.generateRandomString(6)}',
    };

    final csr = X509Utils.generateRsaCsrPem(subject, privateKey, publicKey);

    final certPem = X509Utils.generateSelfSignedCertificate(
      privateKey,
      csr,
      3650,
    );

    final keyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

    await File(rootPath.joinPath(certFile)).writeAsString(certPem);
    await File(rootPath.joinPath(keyFile)).writeAsString(keyPem);
  }

  static SecurityContext generateSecurityContext(String rootPath) {
    final context = SecurityContext();

    context.useCertificateChain(rootPath.joinPath(certFile));
    context.usePrivateKey(rootPath.joinPath(keyFile));
    return context;
  }
}
