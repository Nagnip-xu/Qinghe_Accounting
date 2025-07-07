import 'package:flutter/material.dart';

/// 自定义Toast消息提示工具类
class ToastMessage {
  /// 显示一个Toast消息
  ///
  /// [context] 上下文
  /// [message] 消息内容
  /// [duration] 显示时长
  /// [icon] 图标
  /// [backgroundColor] 背景颜色
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    IconData? icon,
    Color? backgroundColor,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            // 放置在屏幕中央
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white),
                        const SizedBox(width: 12.0),
                      ],
                      Flexible(
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}
