import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  static const String _userKey = 'user_data';

  // 模拟的用户数据库
  final Map<String, String> _mockUsers = {
    'admin': 'admin123',
    'test': 'test123',
    'user': '123456',
  };

  // 登录
  Future<User?> login(String username, String password) async {
    try {
      // 模拟网络延迟
      await Future.delayed(const Duration(seconds: 1));

      // 检查用户密码
      if (_mockUsers.containsKey(username) &&
          _mockUsers[username] == password) {
        final user = User(
          id: username.hashCode,
          username: username,
          email: '$username@example.com',
          isLoggedIn: true,
        );

        // 保存用户数据
        await _saveUserToLocal(user);
        return user;
      }

      return null; // 登录失败
    } catch (e) {
      print('登录失败: $e');
      return null;
    }
  }

  // 登出
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      return true;
    } catch (e) {
      print('登出失败: $e');
      return false;
    }
  }

  // 获取当前登录用户
  Future<User> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);

      if (userString != null && userString.isNotEmpty) {
        final userData = jsonDecode(userString);
        return User.fromMap(userData);
      }

      return User.guest(); // 没有登录返回访客用户
    } catch (e) {
      print('获取用户信息失败: $e');
      return User.guest();
    }
  }

  // 保存用户数据到本地
  Future<void> _saveUserToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toMap()));
    } catch (e) {
      print('保存用户信息失败: $e');
    }
  }

  // 更新用户信息
  Future<bool> updateUser(User user) async {
    try {
      await _saveUserToLocal(user);
      return true;
    } catch (e) {
      print('更新用户信息失败: $e');
      return false;
    }
  }
}
