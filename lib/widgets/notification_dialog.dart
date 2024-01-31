import 'package:flutter/material.dart';
import 'package:tool_crib/screens/home_screen.dart';
import 'package:tool_crib/locale/locale.dart';

class NotificationDialog extends StatelessWidget {
  final List<NotificationItem> notifications;

  NotificationDialog({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${context.localize('notificationstitle')}'),
      content: notifications.isEmpty
          ? Text('${context.localize('notificationsempty')}')
          : SingleChildScrollView(
              child: ListBody(
                children: notifications.map((notificationItem) {
                  return ListTile(
                    title: Row(
                      children: [
                        Text(notificationItem.message),
                        const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Icon(Icons.arrow_forward))
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (notificationItem.action != null) {
                        notificationItem.action!();
                      }
                    },
                  );
                }).toList(),
              ),
            ),
      actions: <Widget>[
        ElevatedButton(
          child: Text('${context.localize('buttonclose')}'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
