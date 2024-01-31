import 'package:flutter/material.dart';
import 'package:tool_crib/locale/locale.dart';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${context.localize('orderscreentitle')}'),
      ),
      body: Center(
        child: Text(
          '${context.localize('orderscreenbodytext')}',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
