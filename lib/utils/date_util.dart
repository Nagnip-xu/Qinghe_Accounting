import 'package:intl/intl.dart';

class DateUtil {
  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthFormatter = DateFormat('yyyy年MM月');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _dayFormatter = DateFormat('dd');
  static final DateFormat _weekdayFormatter = DateFormat('EEE', 'zh_CN');

  // 获取当前日期的格式化字符串 yyyy-MM-dd
  static String getCurrentDate() {
    return _dateFormatter.format(DateTime.now());
  }

  // 获取当前月份的格式化字符串 yyyy年MM月
  static String getCurrentMonth() {
    return _monthFormatter.format(DateTime.now());
  }

  // 获取下一个月份的格式化字符串 yyyy年MM月
  static String getNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return _monthFormatter.format(nextMonth);
  }

  // 获取上一个月份的格式化字符串 yyyy年MM月
  static String getPreviousMonth() {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    return _monthFormatter.format(previousMonth);
  }

  // 获取当前时间的格式化字符串 HH:mm
  static String getCurrentTime() {
    return _timeFormatter.format(DateTime.now());
  }

  // 获取当前日期和时间的格式化字符串 yyyy-MM-dd HH:mm
  static String getCurrentDateTime() {
    return _dateTimeFormatter.format(DateTime.now());
  }

  // 将字符串转换为日期对象
  static DateTime parseDate(String date) {
    return _dateFormatter.parse(date);
  }

  // 将字符串转换为日期时间对象
  static DateTime parseDateTime(String dateTime) {
    return _dateTimeFormatter.parse(dateTime);
  }

  // 获取星期几
  static String getWeekday(DateTime date) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  // 获取某月的天数
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // 获取月份字符串 yyyyMM
  static String getMonthString(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}';
  }

  // 格式化月份显示 yyyy年MM月
  static String formatMonthForDisplay(String yyyyMM) {
    if (yyyyMM.length < 6) return '格式错误';
    final year = yyyyMM.substring(0, 4);
    final month = yyyyMM.substring(4, 6);
    return '$year年$month月';
  }

  // 获取今日日期显示，用于交易记录
  static String getTodayDisplay() {
    return '今天 ${getCurrentTime()}';
  }
}
