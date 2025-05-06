import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:path/path.dart' as path_lib;
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/theme_provider.dart';
import '../utils/shared_prefs.dart';
import '../services/backup_service.dart';
import '../services/sound_service.dart';
import '../services/auth_service.dart';
import '../widgets/common/toast_message.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 显式声明BuildContext类型变量
  late BuildContext _context;

  // 设置项
  Map<String, bool> _settings = {
    '自动备份': true,
    '暗黑模式': false,
    '声音提醒': true,
    '指纹登录': false,
  };
  String? _lastBackupTime;
  bool _fingerprintAvailable = false;
  bool _isLoading = true;

  // 记录各功能的加载状态
  bool _backupServiceAvailable = true;
  bool _soundServiceAvailable = true;
  bool _authServiceAvailable = true;

  // 备份间隔天数
  int? _backupInterval;

  @override
  void initState() {
    super.initState();
    // 初始化时加载备份间隔
    _loadBackupInterval();
    // 使用超时机制确保页面能够在合理时间内加载完成
    _initializeWithTimeout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _context = context;
  }

  // 使用超时机制的初始化
  Future<void> _initializeWithTimeout() async {
    // 设置3秒超时
    const timeout = Duration(seconds: 3);

    try {
      // 记录初始化启动时间
      final startTime = DateTime.now();

      // 使用Future.wait同时执行多个初始化任务，并且为每个任务添加超时处理
      await Future.wait([
        _loadSettingsWithTimeout(timeout),
        _checkFingerprintWithTimeout(timeout),
        _getBackupTimeWithTimeout(timeout),
      ]);
    } catch (e) {
      debugPrint('设置页面初始化出错: $e');
      // 即使出错也要结束加载状态，显示可用的设置项
    } finally {
      // 无论成功或失败，都要结束加载状态
      if (mounted) {
        setState(() {
          _isLoading = false;

          // 确保暗黑模式设置与当前主题一致
          _settings['暗黑模式'] = Theme.of(_context).brightness == Brightness.dark;
        });
      }
    }
  }

  // 带超时的设置加载
  Future<void> _loadSettingsWithTimeout(Duration timeout) async {
    try {
      final darkMode = Theme.of(_context).brightness == Brightness.dark;
      _settings['暗黑模式'] = darkMode;

      await Future.wait([
        _loadBackupSetting(timeout),
        _loadSoundSetting(timeout),
        _loadFingerprintSetting(timeout),
      ]);
    } catch (e) {
      debugPrint('加载设置超时或出错: $e');
    }
  }

  // 加载备份设置
  Future<void> _loadBackupSetting(Duration timeout) async {
    try {
      final autoBackup = await BackupService.isAutoBackupEnabled().timeout(
        timeout,
        onTimeout: () => true,
      );

      if (mounted) {
        setState(() {
          _settings['自动备份'] = autoBackup;
        });
      }
    } catch (e) {
      debugPrint('加载备份设置失败: $e');
      _backupServiceAvailable = false;
    }
  }

  // 加载声音设置
  Future<void> _loadSoundSetting(Duration timeout) async {
    try {
      final soundAlert = await SoundService.isSoundEnabled().timeout(
        timeout,
        onTimeout: () => true,
      );

      if (mounted) {
        setState(() {
          _settings['声音提醒'] = soundAlert;
        });
      }
    } catch (e) {
      debugPrint('加载声音设置失败: $e');
      _soundServiceAvailable = false;
    }
  }

  // 加载指纹登录设置
  Future<void> _loadFingerprintSetting(Duration timeout) async {
    try {
      final fingerprintLogin = await AuthService.isFingerprintLoginEnabled()
          .timeout(timeout, onTimeout: () => false);

      if (mounted) {
        setState(() {
          _settings['指纹登录'] = fingerprintLogin;
        });
      }
    } catch (e) {
      debugPrint('加载指纹设置失败: $e');
      _authServiceAvailable = false;
    }
  }

  // 带超时的指纹可用性检查
  Future<void> _checkFingerprintWithTimeout(Duration timeout) async {
    try {
      final available = await AuthService.isFingerprintAvailable().timeout(
        timeout,
        onTimeout: () => false,
      );

      if (mounted) {
        setState(() {
          _fingerprintAvailable = available;
        });
      }
    } catch (e) {
      debugPrint('检查指纹可用性失败: $e');
      _authServiceAvailable = false;
    }
  }

  // 带超时的备份时间获取
  Future<void> _getBackupTimeWithTimeout(Duration timeout) async {
    try {
      final lastBackup = await BackupService.getLastBackupTime().timeout(
        timeout,
        onTimeout: () => null,
      );

      if (lastBackup != null && mounted) {
        // 格式化上次备份时间为更友好的显示格式
        final now = DateTime.now();
        final difference = now.difference(lastBackup);

        String formattedTime;
        if (difference.inDays > 0) {
          formattedTime = '${difference.inDays}天前';
        } else if (difference.inHours > 0) {
          formattedTime = '${difference.inHours}小时前';
        } else if (difference.inMinutes > 0) {
          formattedTime = '${difference.inMinutes}分钟前';
        } else {
          formattedTime = '刚刚';
        }

        setState(() {
          _lastBackupTime = formattedTime;
        });
      }
    } catch (e) {
      debugPrint('获取最后备份时间失败: $e');
      _backupServiceAvailable = false;
    }
  }

  // 安全地保存设置
  Future<void> _saveSetting(String key, bool value) async {
    try {
      bool success = false;

      switch (key) {
        case '自动备份':
          if (_backupServiceAvailable) {
            await BackupService.setAutoBackupEnabled(
              value,
            ).timeout(const Duration(seconds: 2), onTimeout: () {});
            success = true;
          }
          break;
        case '暗黑模式':
          await Provider.of<ThemeProvider>(
            _context,
            listen: false,
          ).setDarkMode(value);
          success = true;
          break;
        case '声音提醒':
          if (_soundServiceAvailable) {
            await SoundService.setSoundEnabled(
              value,
            ).timeout(const Duration(seconds: 2), onTimeout: () {});

            if (value && _soundServiceAvailable) {
              SoundService.playSuccessSound().catchError((_) {});
            }
            success = true;
          }
          break;
        case '指纹登录':
          if (_authServiceAvailable && _fingerprintAvailable) {
            await AuthService.setFingerprintLoginEnabled(
              value,
            ).timeout(const Duration(seconds: 2), onTimeout: () {});
            success = true;
          }
          break;
      }

      if (mounted && success) {
        setState(() {
          _settings[key] = value;
        });

        // 显示设置已更改提示
        ToastMessage.show(
          _context,
          '$key 已${value ? '开启' : '关闭'}',
          icon: value ? Icons.check_circle_outline : Icons.notifications_off,
          backgroundColor: Theme.of(_context).primaryColor.withOpacity(0.9),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          _context,
          '保存"$key"设置失败: $e',
          icon: Icons.error,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
    }
  }

  // 执行实际备份操作
  Future<void> _performBackupNow() async {
    if (!_backupServiceAvailable) {
      ToastMessage.show(
        _context,
        '备份服务不可用',
        icon: Icons.error,
        backgroundColor: Colors.red.withOpacity(0.9),
      );
      return;
    }

    // 显示进度对话框
    showDialog(
      context: _context,
      barrierDismissible: false,
      builder:
          (BuildContext dialogContext) => const AlertDialog(
            title: Text('正在备份'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在将数据备份到本地文件，请勿关闭应用...'),
              ],
            ),
          ),
    );

    try {
      // 实际执行备份操作
      final backupPath = await BackupService.backupDatabase();

      // 获取备份文件大小
      final backupFile = File(backupPath);
      final fileSize = await backupFile.length();
      final fileSizeStr =
          fileSize < 1024 * 1024
              ? '${(fileSize / 1024).toStringAsFixed(2)} KB'
              : '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';

      // 备份成功后关闭进度对话框
      if (mounted) Navigator.of(_context).pop();

      if (mounted) {
        // 显示备份成功对话框
        showDialog(
          context: _context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('备份成功'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('数据已成功备份到手机下载目录'),
                    const SizedBox(height: 8),
                    Text('文件名：${path_lib.basename(backupPath)}'),
                    Text('文件大小：$fileSizeStr'),
                    Text(
                      '备份时间：${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '您可以在手机文件管理器中的"下载/轻合记账/备份"文件夹找到备份文件',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                  // 查看位置按钮
                  TextButton(
                    onPressed: () {
                      // 尝试打开文件所在目录
                      try {
                        final directory = File(backupPath).parent;
                        Navigator.pop(context);
                        ToastMessage.show(
                          _context,
                          '备份文件位于手机下载目录中的"轻合记账/备份"文件夹',
                          icon: Icons.folder_open,
                          backgroundColor: Colors.blue.withOpacity(0.9),
                        );
                      } catch (e) {
                        ToastMessage.show(
                          _context,
                          '无法定位文件: $e',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red.withOpacity(0.9),
                        );
                      }
                    },
                    child: const Text('查看位置'),
                  ),
                ],
              ),
        );

        ToastMessage.show(
          _context,
          '备份成功，文件保存在手机下载目录',
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.withOpacity(0.9),
        );
      }
    } catch (e) {
      // 备份失败后关闭进度对话框
      if (mounted) Navigator.of(_context).pop();

      if (mounted) {
        // 显示错误提示
        ToastMessage.show(
          _context,
          '备份失败: $e',
          icon: Icons.error,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
    }
  }

  // 执行实际数据恢复
  void _performDataRestore(String source) async {
    if (source == 'local') {
      // 从本地文件恢复
      try {
        // 获取所有备份文件
        final backupFiles = await BackupService.getAllBackups();

        if (backupFiles.isEmpty) {
          ToastMessage.show(
            _context,
            '没有找到备份文件',
            icon: Icons.error,
            backgroundColor: Colors.red.withOpacity(0.9),
          );
          return;
        }

        // 显示备份文件选择对话框
        showDialog(
          context: _context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('选择要恢复的备份'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400, // 限制高度
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 说明文字
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '从备份恢复将会覆盖现有数据。请选择要恢复的备份文件:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: backupFiles.length,
                          itemBuilder: (BuildContext context, int index) {
                            final file = backupFiles[index] as File;
                            final fileName = path_lib.basename(file.path);
                            DateTime? fileDate;

                            // 尝试从文件名提取日期 (格式: backup_yyyyMMdd_HHmmss.db)
                            try {
                              final regex = RegExp(
                                r'backup_(\d{8})_(\d{6})\.db',
                              );
                              final match = regex.firstMatch(fileName);
                              if (match != null) {
                                final dateStr = match.group(1)!;
                                final timeStr = match.group(2)!;
                                fileDate = DateFormat(
                                  'yyyyMMddHHmmss',
                                ).parse('$dateStr$timeStr');
                              } else {
                                fileDate = file.lastModifiedSync();
                              }
                            } catch (_) {
                              fileDate = file.lastModifiedSync();
                            }

                            final fileDateStr = DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format(fileDate!);
                            final fileSize = file.lengthSync();
                            final fileSizeStr =
                                fileSize < 1024 * 1024
                                    ? '${(fileSize / 1024).toStringAsFixed(2)} KB'
                                    : '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';

                            // 更好的列表项样式
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Icon(
                                    Icons.backup,
                                    color: Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  fileDateStr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('文件大小: $fileSizeStr'),
                                    Text(
                                      '文件名: $fileName',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context, file.path);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ],
              ),
        ).then((selectedBackupPath) async {
          if (selectedBackupPath != null) {
            // 显示恢复确认对话框
            final confirmRestore = await showDialog<bool>(
              context: _context,
              builder:
                  (BuildContext context) => AlertDialog(
                    title: const Text('确认恢复'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('从备份恢复将会覆盖当前所有数据，此操作不可撤销。'),
                        SizedBox(height: 12),
                        Text(
                          '注意: 恢复后需要重启应用才能看到恢复的数据。',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text('确定要继续吗？'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('恢复'),
                      ),
                    ],
                  ),
            );

            if (confirmRestore == true) {
              // 显示恢复进度对话框
              showDialog(
                context: _context,
                barrierDismissible: false,
                builder:
                    (BuildContext context) => const AlertDialog(
                      title: Text('正在恢复'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('正在恢复数据，请勿关闭应用...'),
                        ],
                      ),
                    ),
              );

              try {
                // 执行实际恢复操作
                final success = await BackupService.restoreDatabase(
                  selectedBackupPath,
                );

                // 恢复完成后关闭进度对话框
                if (mounted) Navigator.pop(_context);

                if (success) {
                  // 显示恢复成功对话框
                  showDialog(
                    context: _context,
                    builder:
                        (BuildContext context) => AlertDialog(
                          title: const Text('恢复成功'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('数据已成功从备份文件恢复'),
                              const SizedBox(height: 8),
                              Text(
                                '恢复时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '需要重启应用以加载恢复的数据',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('确定'),
                            ),
                            TextButton(
                              onPressed: () {
                                // 退出应用
                                Navigator.pop(context);
                                ToastMessage.show(
                                  _context,
                                  '请手动关闭并重新打开应用',
                                  icon: Icons.exit_to_app,
                                  backgroundColor: Colors.blue.withOpacity(0.9),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('退出应用'),
                            ),
                          ],
                        ),
                  );
                } else {
                  ToastMessage.show(
                    _context,
                    '恢复失败，请确保备份文件完整',
                    icon: Icons.error,
                    backgroundColor: Colors.red.withOpacity(0.9),
                  );
                }
              } catch (e) {
                // 恢复失败后关闭进度对话框
                if (mounted) Navigator.pop(_context);

                ToastMessage.show(
                  _context,
                  '恢复失败: $e',
                  icon: Icons.error,
                  backgroundColor: Colors.red.withOpacity(0.9),
                );
              }
            }
          }
        });
      } catch (e) {
        ToastMessage.show(
          _context,
          '获取备份文件失败: $e',
          icon: Icons.error,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
    } else if (source == 'cloud') {
      // 云端恢复暂不支持
      ToastMessage.show(
        _context,
        '云端备份功能暂未实现，请使用本地备份',
        icon: Icons.cloud_off,
        backgroundColor: Colors.orange.withOpacity(0.9),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _context = context; // 确保_context始终是最新的

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 确保暗黑模式设置与当前主题一致
    _settings['暗黑模式'] = isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0.5,
        leading: null,
        leadingWidth: 80,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(CupertinoIcons.back, color: Colors.black),
              label: const Text(
                '返回',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const Spacer(),
            const Text('设置', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在加载设置...'),
                  ],
                ),
              )
              : ListView(
                children: [
                  const SizedBox(height: 12),

                  // 基本设置区域
                  _buildSectionHeader('基本设置', isDarkMode),
                  _buildSettingCard([
                    _buildSettingItem(
                      '自动备份',
                      _getBackupSubtitle(),
                      _settings['自动备份'] ?? true,
                      (value) => _saveSetting('自动备份', value),
                      isDarkMode,
                      trailing:
                          _settings['自动备份'] == true
                              ? IconButton(
                                icon: const Icon(Icons.timer),
                                color: AppColors.primary,
                                onPressed: _showBackupIntervalDialog,
                                tooltip: '设置备份周期',
                              )
                              : null,
                      enabled: _backupServiceAvailable,
                    ),
                    _buildDivider(isDarkMode),
                    _buildSettingItem(
                      '暗黑模式',
                      '切换应用深色/浅色主题',
                      _settings['暗黑模式'] ?? false,
                      (value) => _saveSetting('暗黑模式', value),
                      isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildSettingItem(
                      '声音提醒',
                      '操作时播放提示音效',
                      _settings['声音提醒'] ?? true,
                      (value) => _saveSetting('声音提醒', value),
                      isDarkMode,
                      enabled: _soundServiceAvailable,
                    ),
                    _buildDivider(isDarkMode),
                    _buildSettingItem(
                      '指纹登录',
                      _fingerprintAvailable ? '使用指纹快速登录应用' : '您的设备不支持指纹识别',
                      _settings['指纹登录'] ?? false,
                      (value) => _saveSetting('指纹登录', value),
                      isDarkMode,
                      isLast: true,
                      enabled: _authServiceAvailable && _fingerprintAvailable,
                    ),
                  ], isDarkMode),

                  const SizedBox(height: 24),

                  // 数据管理区域
                  _buildSectionHeader('数据管理', isDarkMode),
                  _buildSettingCard([
                    _buildInfoItem(
                      '立即备份',
                      _lastBackupTime != null
                          ? '上次备份: $_lastBackupTime'
                          : '从未备份',
                      _performBackupNow,
                      isDarkMode,
                      showArrow: true,
                    ),
                    _buildDivider(isDarkMode),
                    _buildInfoItem(
                      '备份管理',
                      '设置保留的最大备份文件数量',
                      _showBackupManagementDialog,
                      isDarkMode,
                      showArrow: true,
                    ),
                    _buildDivider(isDarkMode),
                    _buildInfoItem(
                      '恢复数据',
                      '从本地或云端备份中恢复数据',
                      _showRestoreOptions,
                      isDarkMode,
                      showArrow: true,
                      isLast: true,
                    ),
                  ], isDarkMode),

                  const SizedBox(height: 24),

                  // 关于区域
                  _buildSectionHeader('关于', isDarkMode),
                  _buildSettingCard([
                    _buildInfoItem('版本', '1.0.0', () {}, isDarkMode),
                    _buildDivider(isDarkMode),
                    _buildInfoItem(
                      '用户协议',
                      '',
                      () => _showUserAgreement(),
                      isDarkMode,
                      showArrow: true,
                    ),
                    _buildDivider(isDarkMode),
                    _buildInfoItem(
                      '隐私政策',
                      '',
                      () => _showPrivacyPolicy(),
                      isDarkMode,
                      showArrow: true,
                      isLast: true,
                    ),
                  ], isDarkMode),

                  const SizedBox(height: 36),

                  // 退出登录按钮
                  _buildLogoutButton(isDarkMode),

                  const SizedBox(height: 24),
                ],
              ),
    );
  }

  // 构建设置分组标题
  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey[700],
        ),
      ),
    );
  }

  // 构建包含设置项的卡片
  Widget _buildSettingCard(List<Widget> children, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // 构建设置开关项
  Widget _buildSettingItem(
    String title,
    String subtitle,
    bool value,
    Function(bool)? onChanged,
    bool isDarkMode, {
    bool isLast = false,
    bool enabled = true,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        enabled
                            ? (isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)
                            : (isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        enabled
                            ? (isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary)
                            : (isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
          Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: AppColors.primary,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  // 构建信息项（无开关）
  Widget _buildInfoItem(
    String title,
    String value,
    VoidCallback onTap,
    bool isDarkMode, {
    bool showArrow = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
              ),
            if (showArrow)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color:
                      isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 构建分隔线
  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
    );
  }

  // 构建退出登录按钮
  Widget _buildLogoutButton(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDarkMode ? Colors.red.withOpacity(0.2) : Colors.red[50],
          foregroundColor: Colors.red,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
        child: const Text(
          '退出登录',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // 退出登录
  void _logout() {
    showDialog(
      context: _context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('确认退出登录'),
            content: const Text('退出登录后需要重新登录才能使用个人账户功能，确定要退出吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 处理退出登录逻辑
                  ToastMessage.show(
                    _context,
                    '已退出登录',
                    icon: Icons.check_circle_outline,
                    backgroundColor: Theme.of(
                      _context,
                    ).primaryColor.withOpacity(0.9),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('确认'),
              ),
            ],
          ),
    );
  }

  // 显示用户协议
  void _showUserAgreement() {
    showModalBottomSheet(
      context: _context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder:
          (BuildContext context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (
                  BuildContext context,
                  ScrollController scrollController,
                ) => SingleChildScrollView(
                  controller: scrollController,
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '用户协议',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '欢迎使用轻合记账应用。本协议为您与轻合记账应用之间的法律协议，规定了您使用我们服务的条款。请仔细阅读。\n\n'
                          '1. 接受条款\n通过使用轻合记账应用，您同意接受本协议的所有条款。如果您不同意这些条款，请不要使用本应用。\n\n'
                          '2. 账户\n您需要创建账户才能使用本应用的某些功能。您有责任维护您的账户安全性，并对您账户下发生的所有活动负责。\n\n'
                          '3. 使用规定\n您同意不会使用本应用从事任何非法或未经授权的活动。\n\n'
                          '4. 内容和版权\n轻合记账应用及其内容受版权法保护。未经许可，您不得复制、修改、分发或销售本应用的任何部分。\n\n'
                          '5. 免责声明\n本应用按"现状"提供，没有任何形式的保证。我们不对使用本应用所产生的结果负责。\n\n'
                          '6. 修改\n我们可能随时修改本协议。继续使用本应用即表示您接受修改后的条款。\n\n'
                          '7. 终止\n如果您违反本协议，我们有权终止您的账户和对本应用的访问。',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // 显示隐私政策
  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: _context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder:
          (BuildContext context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (
                  BuildContext context,
                  ScrollController scrollController,
                ) => SingleChildScrollView(
                  controller: scrollController,
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '隐私政策',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '我们重视您的隐私。本隐私政策描述了我们如何收集、使用和保护您的个人信息。\n\n'
                          '1. 信息收集\n我们可能收集您在使用轻合记账应用过程中提供的个人信息，如姓名、电子邮件地址等。我们还可能自动收集某些信息，如设备信息、使用数据等。\n\n'
                          '2. 信息使用\n我们使用收集的信息来提供、维护和改进我们的服务，以及开发新服务。\n\n'
                          '3. 信息共享\n我们不会出售您的个人信息。我们可能在以下情况下共享您的信息：经您同意、遵守法律要求、保护我们的权利或防止欺诈。\n\n'
                          '4. 数据安全\n我们采取合理措施来保护您的个人信息，防止未经授权的访问、使用或披露。\n\n'
                          '5. 数据保留\n我们会在必要的时间内保留您的个人信息，以实现本隐私政策中描述的目的，除非法律要求或允许更长的保留期。\n\n'
                          '6. 您的权利\n您有权访问、更正或删除您的个人信息。您还可以反对或限制某些处理，或请求数据可携带性。\n\n'
                          '7. 变更\n我们可能会更新本隐私政策。我们会通过在应用中发布新版本来通知您任何变更。',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // 显示恢复选项对话框
  void _showRestoreOptions() {
    showDialog(
      context: _context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('选择恢复方式'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.cloud_download, color: Colors.blue),
                  ),
                  title: const Text('从云端恢复'),
                  subtitle: const Text('从云端服务器恢复您的数据'),
                  onTap: () {
                    Navigator.pop(context);
                    _performDataRestore('cloud');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.sd_storage, color: Colors.green),
                  ),
                  title: const Text('从本地文件恢复'),
                  subtitle: const Text('从本地备份文件恢复数据'),
                  onTap: () {
                    Navigator.pop(context);
                    _performDataRestore('local');
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          ),
    );
  }

  // 获取备份设置的副标题
  String _getBackupSubtitle() {
    if (!(_settings['自动备份'] ?? true)) {
      return '自动备份已关闭';
    }

    final interval = _backupInterval ?? 7;
    String intervalText;

    // 根据备份周期显示不同文本
    switch (interval) {
      case 1:
        intervalText = '每天';
        break;
      case 3:
        intervalText = '每3天';
        break;
      case 7:
        intervalText = '每周';
        break;
      case 14:
        intervalText = '每两周';
        break;
      case 30:
        intervalText = '每月';
        break;
      default:
        intervalText = '每 $interval 天';
    }

    // 格式化上次备份时间显示
    String lastBackupInfo = '';
    if (_lastBackupTime != null) {
      lastBackupInfo = "\n上次备份: $_lastBackupTime";
    }

    return '${intervalText}自动备份您的数据$lastBackupInfo';
  }

  // 显示备份周期设置对话框
  void _showBackupIntervalDialog() async {
    final int currentInterval = await BackupService.getBackupInterval();
    int selectedInterval = currentInterval;

    // 备份周期选项
    final List<int> intervalOptions = [1, 3, 7, 14, 30];

    showDialog(
      context: _context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('自动备份周期'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('请选择自动备份的间隔时间:'),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      child: Column(
                        children:
                            intervalOptions.map((days) {
                              final String label =
                                  days == 1 ? '每天' : '每 $days 天';

                              return RadioListTile<int>(
                                title: Text(label),
                                value: days,
                                groupValue: selectedInterval,
                                onChanged: (value) {
                                  setState(() {
                                    selectedInterval = value!;
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await BackupService.setBackupInterval(selectedInterval);
                      // 更新UI显示
                      if (mounted) {
                        setState(() {
                          _backupInterval = selectedInterval;
                        });
                      }

                      ToastMessage.show(
                        _context,
                        '备份周期已设置为${selectedInterval == 1 ? "每天" : "每 $selectedInterval 天"}',
                        icon: Icons.schedule,
                        backgroundColor: Colors.green.withOpacity(0.9),
                      );

                      Navigator.pop(context);
                      // 刷新UI
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          ),
    ).then((_) {
      // 刷新状态
      if (mounted) {
        setState(() {});
      }
    });
  }

  // 加载备份间隔设置
  Future<void> _loadBackupInterval() async {
    try {
      final interval = await BackupService.getBackupInterval();
      if (mounted) {
        setState(() {
          _backupInterval = interval;
        });
      }
    } catch (e) {
      debugPrint('加载备份间隔设置失败: $e');
    }
  }

  // 显示备份管理对话框
  void _showBackupManagementDialog() async {
    final int currentMaxBackups = await BackupService.getMaxBackupFiles();
    int selectedMaxBackups = currentMaxBackups;

    // 获取当前备份文件数量
    final backupFiles = await BackupService.getAllBackups();
    final currentBackupCount = backupFiles.length;

    showDialog(
      context: _context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('备份管理设置'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前共有 $currentBackupCount 个备份文件'),
                    const SizedBox(height: 16),
                    const Text('设置自动保留的最大备份文件数量:'),
                    const SizedBox(height: 8),
                    const Text(
                      '超出数量限制的较早备份文件将在新备份创建后被自动删除',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: selectedMaxBackups.toDouble(),
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: selectedMaxBackups.toString(),
                            onChanged: (value) {
                              setState(() {
                                selectedMaxBackups = value.round();
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            selectedMaxBackups.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        // 显示清理备份对话框
                        _showCleanupBackupsDialog(
                          context,
                          currentBackupCount,
                          selectedMaxBackups,
                        );
                      },
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('立即清理旧备份'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await BackupService.setMaxBackupFiles(selectedMaxBackups);

                      Navigator.pop(context);

                      // 显示设置已更改提示
                      ToastMessage.show(
                        _context,
                        '已设置保留最多 $selectedMaxBackups 个备份文件',
                        icon: Icons.settings_backup_restore,
                        backgroundColor: Colors.green.withOpacity(0.9),
                      );
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // 显示清理备份对话框
  void _showCleanupBackupsDialog(
    BuildContext context,
    int currentCount,
    int maxToKeep,
  ) async {
    if (currentCount <= maxToKeep) {
      ToastMessage.show(
        _context,
        '当前备份数量未超出限制，无需清理',
        icon: Icons.info,
        backgroundColor: Colors.blue.withOpacity(0.9),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (BuildContext innerContext) => AlertDialog(
            title: const Text('清理备份文件'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '将保留最新的 $maxToKeep 个备份文件，删除其余 ${currentCount - maxToKeep} 个较早的备份文件。',
                ),
                const SizedBox(height: 12),
                const Text(
                  '警告：此操作不可撤销！',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(innerContext),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(innerContext);

                  // 显示进度对话框
                  showDialog(
                    context: _context,
                    barrierDismissible: false,
                    builder:
                        (BuildContext dialogContext) => const AlertDialog(
                          title: Text('正在清理'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('正在清理旧备份文件...'),
                            ],
                          ),
                        ),
                  );

                  try {
                    // 执行清理
                    final deletedCount =
                        await BackupService.cleanupOldBackups();

                    // 关闭进度对话框
                    Navigator.pop(_context);

                    ToastMessage.show(
                      _context,
                      '已清理 $deletedCount 个旧备份文件',
                      icon: Icons.delete_sweep,
                      backgroundColor: Colors.green.withOpacity(0.9),
                    );

                    // 关闭设置对话框并刷新
                    Navigator.pop(_context);
                  } catch (e) {
                    // 关闭进度对话框
                    Navigator.pop(_context);

                    ToastMessage.show(
                      _context,
                      '清理失败: $e',
                      icon: Icons.error,
                      backgroundColor: Colors.red.withOpacity(0.9),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('清理'),
              ),
            ],
          ),
    );
  }
}
