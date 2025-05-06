import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';
import '../widgets/common/toast_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _fingerprintAvailable = false;
  bool _fingerprintEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkFingerprintAvailability();
  }

  // 检查指纹功能是否可用
  Future<void> _checkFingerprintAvailability() async {
    final available = await AuthService.isFingerprintAvailable();
    final enabled = await AuthService.isFingerprintLoginEnabled();

    setState(() {
      _fingerprintAvailable = available;
      _fingerprintEnabled = enabled;
    });

    // 如果指纹登录可用且已启用，自动尝试指纹登录
    if (available && enabled) {
      _authenticateWithFingerprint();
    }
  }

  // 指纹认证登录
  Future<void> _authenticateWithFingerprint() async {
    final authenticated = await AuthService.authenticateWithFingerprint();
    if (authenticated) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 使用默认凭据自动登录
        final success =
            await Provider.of<UserProvider>(
              context,
              listen: false,
            ).fingerprintLogin();

        if (success) {
          // 播放成功音效
          SoundService.playSuccessSound();
          Navigator.of(context).pop(); // 登录成功后返回
        } else {
          // 播放错误音效
          SoundService.playErrorSound();
          ToastMessage.show(
            context,
            '指纹登录失败，请使用用户名密码登录',
            icon: Icons.fingerprint,
            backgroundColor: Colors.red.withOpacity(0.9),
          );
        }
      } catch (e) {
        // 播放错误音效
        SoundService.playErrorSound();
        ToastMessage.show(
          context,
          '指纹登录出错: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 处理登录
  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // 使用Provider登录
      Provider.of<UserProvider>(context, listen: false)
          .login(username, password)
          .then((success) {
            if (success) {
              // 播放成功音效
              SoundService.playSuccessSound();
              Navigator.of(context).pop(); // 登录成功后返回
            } else {
              // 播放错误音效
              SoundService.playErrorSound();
              ToastMessage.show(
                context,
                '登录失败，请检查用户名和密码',
                icon: Icons.person_outline,
                backgroundColor: Colors.red.withOpacity(0.9),
              );
            }
          })
          .catchError((error) {
            // 播放错误音效
            SoundService.playErrorSound();
            ToastMessage.show(
              context,
              '登录失败: $error',
              icon: Icons.error_outline,
              backgroundColor: Colors.red.withOpacity(0.9),
            );
          })
          .whenComplete(() {
            setState(() {
              _isLoading = false;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('登录'), elevation: 0),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo或欢迎文字
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '轻合记账',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '简单易用的记账应用',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 用户名输入框
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  prefixIcon: Icon(
                    Icons.person,
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor:
                      isDarkMode
                          ? AppColors.darkCard
                          : Colors.grey.withOpacity(0.1),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // 密码输入框
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: Icon(
                    Icons.lock,
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor:
                      isDarkMode
                          ? AppColors.darkCard
                          : Colors.grey.withOpacity(0.1),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    return '密码长度至少为6位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              // 登录按钮
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                          : const Text(
                            '登录',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              // 指纹登录按钮 (只有当设备支持指纹识别时显示)
              if (_fingerprintAvailable) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('指纹登录'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isLoading ? null : _authenticateWithFingerprint,
                ),
              ],
              const SizedBox(height: 20),
              // 提示文字
              Text(
                '* 这是一个演示应用，输入任意用户名和密码即可登录',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
