import 'package:flutter/material.dart';
import 'package:tool_crib/models/tool.dart';
import 'package:tool_crib/database.dart';
import 'package:tool_crib/widgets/toast_util.dart';
import 'package:tool_crib/main.dart';
import 'package:postgres/postgres.dart';
import 'package:tool_crib/utils/app_theme.dart';
import 'package:tool_crib/locale/locale.dart';

class DrawerSectionDialog extends StatefulWidget {
  final PostgreSQLConnection connection;
  final String section;
  final String? cabinet;

  DrawerSectionDialog({
    required this.connection,
    required this.section,
    this.cabinet,
  });

  @override
  _DrawerSectionDialogState createState() => _DrawerSectionDialogState();
}

class _DrawerSectionDialogState extends State<DrawerSectionDialog> {
  late DatabaseHelper databaseHelper;
  List<Tool> tools = [];
  List<int?> updatedQuantities = [];

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    fetchTools();
  }

  void fetchTools() async {
    List<String> extcabs = ['pfrcab', 'mitsucab', 'strcab', 'ftscab'];
    List<Tool> fetchedTools;
    List<Map<String, String>> selectedFilters = extcabs.contains(widget.cabinet)
        ? [
            {'column': widget.cabinet!, 'value': widget.section}
          ]
        : [
            {'column': 'cabinet', 'value': widget.section}
          ];

    fetchedTools = await databaseHelper.performSearch(selectedFilters,
        shouldLogQuery: false);
    setState(() {
      tools = fetchedTools;
      updatedQuantities = tools.map((tool) => tool.avail).toList();
    });
  }

  void showConfirmDialog() {
    final toast = ToastUtil(context, MyApp.navigatorKey);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.localize('confirmchanges')),
          content: SingleChildScrollView(
            child: ListBody(
              children: tools
                  .asMap()
                  .map((index, tool) {
                    return MapEntry(
                      index,
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.dialogText(context),
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  "${tool.invnum} ${context.localize('old')}: ",
                            ),
                            TextSpan(
                              text: "${tool.avail}",
                              style: TextStyle(color: Colors.orange),
                            ),
                            TextSpan(
                              text: " ${context.localize('new')}: ",
                            ),
                            TextSpan(
                              text: "${updatedQuantities[index]}",
                              style: TextStyle(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .values
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text(context.localize('cancel')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(context.localize('confirm')),
              onPressed: () async {
                for (int i = 0; i < tools.length; i++) {
                  Tool tool = tools[i];
                  int? newAvailability = updatedQuantities[i];

                  if (newAvailability != null &&
                      newAvailability != tool.avail) {
                    await databaseHelper.updateInventoryQty(
                        tool.id!, newAvailability, tool.sourcetable!);
                  }
                }

                if (mounted) {
                  Navigator.of(context).pop();
                  fetchTools();
                  toast.showToast(context.localize('toastquantitiesupdated'));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<Color> cardInnerColors = theme.brightness == Brightness.light
        ? AppTheme.machineCardInnerColorsLight
        : AppTheme.machineCardInnerColorsDark;

    return AlertDialog(
      title: Text(
        '${context.localize('section')} ${widget.section}',
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tools.asMap().entries.map((entry) {
              int index = entry.key;
              Tool tool = entry.value;
              return Card(
                color: cardInnerColors[index % cardInnerColors.length],
                child: ListTile(
                  title: RichText(
                      text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                          text:
                              '${tool.mfr ?? context.localize('unknownmfr')} ${tool.tooltype} Ø ${tool.parseTipdia()} ${tool.invnum} ${context.localize('avail')}:',
                          style:
                              TextStyle(color: AppTheme.dialogText(context))),
                      TextSpan(
                          text: ' ${tool.avail}',
                          style: const TextStyle(color: Colors.orange))
                    ],
                    style: const TextStyle(fontSize: 16),
                  )),
                  trailing: SizedBox(
                    width: 50,
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                          hintText: context.localize('hintqty')),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        updatedQuantities[index] =
                            int.tryParse(value) ?? tool.avail;
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text(context.localize('buttonclose')),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text(context.localize('updatequantities')),
          onPressed: showConfirmDialog,
        ),
      ],
    );
  }
}
