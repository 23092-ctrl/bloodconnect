import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const _authBox = 'auth';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_authBox);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final box = Hive.box(_authBox);
    await Future.wait([
      box.put(_accessTokenKey, accessToken),
      box.put(_refreshTokenKey, refreshToken),
    ]);
  }

  static String? get accessToken => Hive.box(_authBox).get(_accessTokenKey);
  static String? get refreshToken => Hive.box(_authBox).get(_refreshTokenKey);

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await Hive.box(_authBox).put(_userKey, user);
  }

  static Map<String, dynamic>? get user {
    final raw = Hive.box(_authBox).get(_userKey);
    return raw != null ? Map<String, dynamic>.from(raw) : null;
  }

  static bool get isAuthenticated => accessToken != null;

  static Future<void> clear() async {
    await Hive.box(_authBox).clear();
  }
}
