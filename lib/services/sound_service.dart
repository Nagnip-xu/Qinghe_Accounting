import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static const _soundEnabledKey = 'sound_enabled';

  // 检查声音是否启用
  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  // 设置声音是否启用
  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  // 播放成功提示音
  static Future<void> playSuccessSound() async {
    final isEnabled = await isSoundEnabled();
    if (!isEnabled) return;

    // 在此处添加实际的声音播放逻辑
    // 在真实场景中，应该使用audioplayers、just_audio等包来播放音效
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // 播放错误提示音
  static Future<void> playErrorSound() async {
    final isEnabled = await isSoundEnabled();
    if (!isEnabled) return;

    // 在此处添加实际的声音播放逻辑
    // 在真实场景中，应该使用audioplayers、just_audio等包来播放音效
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // 播放点击提示音
  static Future<void> playClickSound() async {
    final isEnabled = await isSoundEnabled();
    if (!isEnabled) return;

    // 在此处添加实际的声音播放逻辑
    // 在真实场景中，应该使用audioplayers、just_audio等包来播放音效
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
