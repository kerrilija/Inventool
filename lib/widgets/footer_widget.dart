import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tool_crib/locale/locale.dart';

class FooterWidget extends StatefulWidget {
  @override
  _FooterWidgetState createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      color: theme.appBarTheme.backgroundColor,
      child: Text(
        '${context.localize('version')}: $_version (c) Eduard Ravnić, 2024',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white,
        ),
      ),
    );
  }
}
