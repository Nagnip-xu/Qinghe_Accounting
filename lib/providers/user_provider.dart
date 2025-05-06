import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  User _currentUser = User.guest();
  bool _isLoading = false;
  String? _error;

  final UserService _userService = UserService();

  User get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser.isLoggedIn;

  // 初始化获取用户信息
  Future<void> initialize() async {
    _setLoading(true);

    try {
      _currentUser = await _userService.getCurrentUser();
      _setError(null);
    } catch (e) {
      _setError('获取用户信息失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 登录
  Future<bool> login(String username, String password) async {
    _setLoading(true);

    try {
      // 简单模拟登录，任何用户名和密码都能登录成功
      if (username.isNotEmpty && password.length >= 6) {
        // 创建一个用户对象
        final user = User(
          id: DateTime.now().millisecondsSinceEpoch,
          username: username,
          email: '$username@example.com',
          avatar: '',
          isLoggedIn: true,
        );

        _currentUser = user;
        _setError(null);
        return true;
      } else {
        _setError('用户名或密码错误');
        return false;
      }
    } catch (e) {
      _setError('登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 指纹登录
  Future<bool> fingerprintLogin() async {
    _setLoading(true);

    try {
      // 尝试获取上次登录的用户信息
      final user = await _userService.getCurrentUser();

      // 如果有用户信息并且之前登录过，直接使用该用户信息登录
      if (user.isLoggedIn || user.username.isNotEmpty) {
        _currentUser = user;
        _setError(null);
        return true;
      }

      // 如果没有之前的登录信息，使用默认用户登录
      final defaultUser = User(
        id: DateTime.now().millisecondsSinceEpoch,
        username: 'default_user',
        email: 'default_user@example.com',
        avatar: '',
        isLoggedIn: true,
      );

      _currentUser = defaultUser;
      // 保存用户信息以便下次指纹登录
      await _userService.updateUser(defaultUser);
      _setError(null);
      return true;
    } catch (e) {
      _setError('指纹登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 登出
  Future<bool> logout() async {
    _setLoading(true);

    try {
      final result = await _userService.logout();

      if (result) {
        _currentUser = User.guest();
        _setError(null);
        return true;
      } else {
        _setError('登出失败');
        return false;
      }
    } catch (e) {
      _setError('登出失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 设置错误信息
  void _setError(String? errorMsg) {
    _error = errorMsg;
    notifyListeners();
  }
}
