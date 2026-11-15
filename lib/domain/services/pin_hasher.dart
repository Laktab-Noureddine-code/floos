import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PIN hashing (PBKDF2-HMAC-SHA256, 100k iterations, random salt) and lockout
/// policy (APP_PROMPT §6.2, §14). Stored only in secure storage.
abstract final class PinHasher {
  static const iterations = 100000;
  static const freeAttempts = 5;
  static const delayStepSeconds = 30;

  static final RegExp _valid = RegExp(r'^\d{4,6}$');

  static bool isValidPin(String pin) => _valid.hasMatch(pin);

  /// Returns `pbkdf2$iterations$saltB64$hashB64`.
  static String hash(String pin, {List<int>? salt, int rounds = iterations}) {
    final s = salt ?? List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final dk = pbkdf2(utf8.encode(pin), s, rounds, 32);
    return 'pbkdf2\$$rounds\$${base64Encode(s)}\$${base64Encode(dk)}';
  }

  static bool verify(String pin, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final rounds = int.tryParse(parts[1]) ?? iterations;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final dk = pbkdf2(utf8.encode(pin), salt, rounds, expected.length);
    var diff = 0;
    for (var i = 0; i < dk.length; i++) {
      diff |= dk[i] ^ expected[i];
    }
    return diff == 0;
  }

  /// Lockout delay after [failedAttempts]: none for the first 5, then
  /// 30 s × attempts.
  static Duration delayFor(int failedAttempts) => failedAttempts < freeAttempts
      ? Duration.zero
      : Duration(seconds: delayStepSeconds * failedAttempts);

  /// PBKDF2-HMAC-SHA256.
  static List<int> pbkdf2(List<int> password, List<int> salt, int rounds, int length) {
    final hmac = Hmac(sha256, password);
    final out = <int>[];
    var block = 1;
    while (out.length < length) {
      final b = [...salt, (block >> 24) & 0xff, (block >> 16) & 0xff, (block >> 8) & 0xff, block & 0xff];
      var u = hmac.convert(b).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < rounds; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.addAll(t);
      block++;
    }
    return out.sublist(0, length);
  }
}
