import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _fingerprintLoginKey = 'fingerprint_login_enabled';

  // 检查指纹功能是否可用
  static Future<bool> isFingerprintAvailable() async {
    // 模拟指纹验证功能是否可用
    // 在真实场景中，需要使用local_auth包来检查生物识别可用性
    return true;
  }

  // 检查指纹登录是否已启用
  static Future<bool> isFingerprintLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fingerprintLoginKey) ?? false;
  }

  // 设置指纹登录是否启用
  static Future<void> setFingerprintLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fingerprintLoginKey, enabled);
  }

  // 使用指纹进行认证
  static Future<bool> authenticateWithFingerprint() async {
    // 模拟指纹认证成功
    // 在真实场景中，应该使用local_auth包来实现生物识别认证
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
