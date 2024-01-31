import 'package:inventool/database.dart';
import 'package:flutter/material.dart';
import 'package:inventool/models/tool.dart';
import 'package:postgres/postgres.dart';
import 'package:provider/provider.dart';
import 'package:inventool/screens/exchange_screen.dart';
import 'package:inventool/widgets/tool_table_dialog.dart';
import 'package:inventool/widgets/search_widget.dart';
import 'package:inventool/utils/app_theme.dart';
import 'package:inventool/locale/locale.dart';

class MachineCard extends StatefulWidget {
  final PostgreSQLConnection connection;
  final int machineNumber;

  MachineCard({required this.connection, required this.machineNumber});

  @override
  _MachineCardState createState() => _MachineCardState();
}

class _MachineCardState extends State<MachineCard> {
  late DatabaseHelper databaseHelper;
  Map<int, Tool> toolList = {};

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    fetchToolList();

    Provider.of<ToolExchangeNotifier>(context, listen: false)
        .addListener(fetchToolList);
  }

  Future<void> fetchToolList() async {
    final toolsWithExchangeIds =
        await databaseHelper.fetchMachine(widget.machineNumber);
    if (mounted) {
      setState(() {
        toolList = toolsWithExchangeIds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<Color> cardInnerColors = theme.brightness == Brightness.light
        ? AppTheme.machineCardInnerColorsLight
        : AppTheme.machineCardInnerColorsDark;

    ToolExchangeNotifier notifier =
        Provider.of<ToolExchangeNotifier>(context, listen: false);

    return Card(
      color: AppTheme.machineCardColor(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${context.localize('machine')} #${widget.machineNumber}',
              style: TextStyle(color: AppTheme.machineCardTitleColor),
            ),
          ),
          if (toolList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('${context.localize('machinecardempty')}'),
              ),
            ),
          if (toolList.isNotEmpty)
            SizedBox(
              height: 180,
              child: SingleChildScrollView(
                child: Column(
                  children: Iterable.generate(toolList.length).map((index) {
                    var entry = toolList.entries.elementAt(index);
                    return Card(
                      color: cardInnerColors[index % cardInnerColors.length],
                      child: ListTile(
                        title: Text(
                          '${entry.value.tooltype} Ø ${entry.value.parseTipdia()}${entry.value.unit == 'mm' ? ' mm' : '"'}',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => ToolTableDialog(
                      tools: toolList,
                      databaseHelper: databaseHelper,
                      machineNumber: widget.machineNumber,
                      notifier: notifier,
                      actionTypes: const [ToolAction.Edit, ToolAction.Return]),
                );
              },
              child: Text('${context.localize('machinecardbutton')}'),
            ),
          ),
        ],
      ),
    );
  }
}
