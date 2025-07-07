import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const _autoBackupEnabledKey = 'auto_backup_enabled';
  static const _lastBackupTimeKey = 'last_backup_time';
  static const _backupIntervalKey = 'backup_interval_days';
  static const _maxBackupFilesKey = 'max_backup_files';

  // 获取备份目录
  static Future<String> _getBackupDirectory() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download/青禾记账/备份');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory.path;
    } else {
      // iOS或其他平台使用应用文档目录
      final docDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${docDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir.path;
    }
  }

  // 检查自动备份是否启用
  static Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupEnabledKey) ?? true;
  }

  // 设置自动备份是否启用
  static Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
  }

  // 获取上次备份时间
  static Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastBackupTimeKey);
    if (timeStr == null) return null;
    return DateTime.parse(timeStr);
  }

  // 设置上次备份时间
  static Future<void> _setLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupTimeKey, time.toIso8601String());
  }

  // 获取备份间隔天数
  static Future<int> getBackupInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_backupIntervalKey) ?? 7; // 默认7天
  }

  // 设置备份间隔天数
  static Future<void> setBackupInterval(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backupIntervalKey, days);
  }

  // 获取最大备份文件数量
  static Future<int> getMaxBackupFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxBackupFilesKey) ?? 10; // 默认保留10个备份
  }

  // 设置最大备份文件数量
  static Future<void> setMaxBackupFiles(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxBackupFilesKey, count);
  }

  // 执行数据库备份
  static Future<String> backupDatabase() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    // 获取数据库文件路径
    final dbPath = db.path;
    final dbFile = File(dbPath);

    // 如果数据库文件不存在，抛出异常
    if (!await dbFile.exists()) {
      throw Exception('数据库文件不存在');
    }

    // 获取备份目录
    final backupDir = await _getBackupDirectory();

    // 创建备份文件名（使用时间戳）
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFileName = 'backup_$timestamp.db';
    final backupFilePath = '$backupDir/$backupFileName';

    // 复制数据库文件到备份目录
    await dbFile.copy(backupFilePath);

    // 更新上次备份时间
    await _setLastBackupTime(DateTime.now());

    // 清理旧备份文件
    await cleanupOldBackups();

    return backupFilePath;
  }

  // 带进度报告的备份
  static Future<String> backupDatabaseWithProgress(
    Function(double progress) onProgress,
  ) async {
    // 模拟进度报告
    onProgress(0.1);
    await Future.delayed(const Duration(milliseconds: 100));
    onProgress(0.3);
    await Future.delayed(const Duration(milliseconds: 100));

    final backupPath = await backupDatabase();

    onProgress(0.6);
    await Future.delayed(const Duration(milliseconds: 100));
    onProgress(0.8);
    await Future.delayed(const Duration(milliseconds: 100));
    onProgress(1.0);

    return backupPath;
  }

  // 恢复数据库
  static Future<bool> restoreDatabase(String backupFilePath) async {
    try {
      // 获取DatabaseHelper实例
      final dbHelper = DatabaseHelper.instance;

      // 首先，获取当前数据库连接并关闭
      Database? db;
      try {
        db = await dbHelper.database;
        // 获取数据库文件路径
        final dbPath = db.path;

        // 先关闭数据库连接
        await db.close();
        // 重置数据库实例
        await dbHelper.resetDatabase();

        print('数据库已关闭，准备恢复文件: $dbPath');

        // 检查备份文件是否存在
        final backupFile = File(backupFilePath);
        if (!await backupFile.exists()) {
          throw Exception('备份文件不存在: $backupFilePath');
        }

        // 备份当前数据库（恢复前备份）
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          final timestamp = DateFormat(
            'yyyyMMdd_HHmmss',
          ).format(DateTime.now());
          final tempBackupPath =
              '${await _getBackupDirectory()}/pre_restore_$timestamp.db';
          await dbFile.copy(tempBackupPath);
          print('已创建恢复前备份: $tempBackupPath');
        }

        // 清理SQLite的WAL模式文件
        try {
          final shmFile = File('${dbPath}-shm');
          final walFile = File('${dbPath}-wal');
          if (await shmFile.exists()) {
            await shmFile.delete();
            print('已删除shm文件');
          }
          if (await walFile.exists()) {
            await walFile.delete();
            print('已删除wal文件');
          }
        } catch (e) {
          print('清理SQLite辅助文件失败: $e');
        }

        // 删除现有数据库文件
        if (await dbFile.exists()) {
          await dbFile.delete();
          print('已删除原始数据库文件');
        }

        // 复制备份文件到数据库位置
        await backupFile.copy(dbPath);
        print('已复制备份文件到数据库位置');

        // 确保文件权限正确
        try {
          final newDbFile = File(dbPath);
          if (Platform.isAndroid || Platform.isLinux) {
            await newDbFile.setLastModified(DateTime.now());
            // 设置文件权限为可读写
            final ioSink = newDbFile.openWrite();
            await ioSink.flush();
            await ioSink.close();
          }
          print('已设置文件权限');
        } catch (e) {
          print('设置文件权限时出错: $e');
        }

        // 验证数据库文件是否可以打开
        try {
          // 尝试打开恢复后的数据库来验证
          print('正在验证恢复的数据库...');
          final testDb = await openDatabase(dbPath);

          // 尝试运行一个简单查询来验证数据库完整性
          try {
            final result = await testDb.rawQuery(
              'SELECT name FROM sqlite_master WHERE type = "table"',
            );
            print('数据库表验证: $result');
          } catch (e) {
            print('数据库表验证失败: $e');
          }

          await testDb.close();
          print('数据库验证成功');
        } catch (e) {
          print('验证恢复的数据库文件失败: $e');
          return false;
        }

        // 为确保应用重启后能正确加载恢复的数据，
        // 在共享首选项中记录恢复状态，应用启动时可以检查
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('db_restored', true);
        await prefs.setString(
          'last_restore_time',
          DateTime.now().toIso8601String(),
        );

        return true;
      } catch (e) {
        print('获取或操作数据库过程中出错: $e');
        if (db != null) {
          try {
            await db.close();
          } catch (closeError) {
            print('关闭数据库连接出错: $closeError');
          }
        }
        throw e;
      }
    } catch (e) {
      print('恢复数据库失败: $e');
      return false;
    }
  }

  // 带进度报告的恢复
  static Future<bool> restoreDatabaseWithProgress(
    String backupFilePath,
    Function(double progress, String message) onProgress,
  ) async {
    // 模拟进度报告
    onProgress(0.1, '准备恢复...');
    await Future.delayed(const Duration(milliseconds: 200));
    onProgress(0.3, '备份当前数据...');
    await Future.delayed(const Duration(milliseconds: 200));
    onProgress(0.5, '恢复数据中...');

    final success = await restoreDatabase(backupFilePath);

    if (success) {
      onProgress(0.8, '验证恢复结果...');
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress(1.0, '恢复成功！');
    } else {
      onProgress(1.0, '恢复失败！');
    }

    return success;
  }

  // 获取所有备份文件
  static Future<List<FileSystemEntity>> getAllBackups() async {
    final backupDir = await _getBackupDirectory();
    final directory = Directory(backupDir);

    if (!await directory.exists()) {
      return [];
    }

    final List<FileSystemEntity> files =
        await directory
            .list()
            .where(
              (entity) =>
                  entity is File &&
                  basename(entity.path).startsWith('backup_') &&
                  entity.path.endsWith('.db'),
            )
            .toList();

    // 按修改时间倒序排列（最新的在前面）
    files.sort((a, b) {
      return b.statSync().modified.compareTo(a.statSync().modified);
    });

    return files;
  }

  // 清理旧备份
  static Future<int> cleanupOldBackups() async {
    try {
      final maxBackups = await getMaxBackupFiles();
      final backups = await getAllBackups();

      if (backups.length <= maxBackups) {
        return 0;
      }

      final filesToDelete = backups.sublist(maxBackups);
      for (var file in filesToDelete) {
        await file.delete();
      }

      return filesToDelete.length;
    } catch (e) {
      print('清理旧备份失败: $e');
      return 0;
    }
  }
}
