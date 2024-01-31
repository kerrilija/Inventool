import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil {
  final BuildContext context;
  final FToast fToast;
  final GlobalKey<NavigatorState> navigatorKey;

  ToastUtil(this.context, this.navigatorKey) : fToast = FToast() {
    fToast.init(navigatorKey.currentContext!);
  }

  void showToast(String message, {Color? bgColor, int? duration}) {
    Duration durationSeconds = Duration(seconds: duration ?? 1);

    fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: bgColor ?? Colors.grey[900],
        ),
        child: Text(message),
      ),
      toastDuration: durationSeconds,
      gravity: ToastGravity.CENTER,
    );
  }
}
