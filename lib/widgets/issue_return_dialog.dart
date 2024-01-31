import 'package:flutter/material.dart';
import 'package:tool_crib/models/tool.dart';
import 'package:tool_crib/database.dart';
import 'package:tool_crib/widgets/toast_util.dart';
import 'package:provider/provider.dart';
import 'package:tool_crib/main.dart';
import 'package:tool_crib/screens/exchange_screen.dart';
import 'package:tool_crib/utils/app_theme.dart';
import 'package:tool_crib/locale/locale.dart';

class IssueReturnDialog extends StatefulWidget {
  final Map<int, Tool> tools;
  final String title;
  final DatabaseHelper databaseHelper;
  final bool isIssue;
  final Map<int, bool> issuedCheckStates;
  final Map<int, int> machineNumbers;
  final Function(List<int>) onDialogClose;

  IssueReturnDialog({
    required this.tools,
    required this.title,
    required this.databaseHelper,
    this.isIssue = true,
    required this.issuedCheckStates,
    required this.machineNumbers,
    required this.onDialogClose,
  });

  @override
  _IssueReturnDialogState createState() => _IssueReturnDialogState();
}

class _IssueReturnDialogState extends State<IssueReturnDialog> {
  late Map<int, Tool> modifiedTools;

  @override
  void initState() {
    super.initState();
    modifiedTools = Map.from(widget.tools);
  }

  void _handleIssueOrReturn() {
    final toolsToUpdate = <int>[];
    for (var entry in modifiedTools.entries) {
      int exchangeId = entry.key;
      Tool tool = entry.value;

      if (widget.isIssue) {
        final newTool = widget.issuedCheckStates[exchangeId] ?? false;
        final machineNumber = widget.machineNumbers[exchangeId];
        widget.databaseHelper.issueTool(tool, newTool, machineNumber);
      } else {
        widget.databaseHelper.returnTool(tool);
      }
      widget.databaseHelper.deleteExchangeId(exchangeId);
      toolsToUpdate.add(exchangeId);
    }

    widget.onDialogClose(toolsToUpdate);
  }

  @override
  Widget build(BuildContext context) {
    final toast = ToastUtil(context, MyApp.navigatorKey);

    final theme = Theme.of(context);
    List<Color> cardInnerColors = theme.brightness == Brightness.light
        ? AppTheme.machineCardInnerColorsLight
        : AppTheme.machineCardInnerColorsDark;

    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: modifiedTools.entries.map((entry) {
              int exchangeId = entry.key;
              Tool tool = entry.value;
              return Card(
                color: cardInnerColors[exchangeId % cardInnerColors.length],
                child: ListTile(
                    title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tool.mfr} ${tool.tooltype} Ø ${tool.parseTipdia()} ${tool.invnum}',
                    ),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${context.localize('avail')}: ',
                            style:
                                TextStyle(color: AppTheme.dialogText(context)),
                          ),
                          TextSpan(
                            text: '${tool.avail}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          TextSpan(
                              text: ' ---> (',
                              style: TextStyle(
                                  color: AppTheme.dialogText(context))),
                          TextSpan(
                            text: widget.isIssue
                                ? (widget.issuedCheckStates[exchangeId] == true
                                    ? '${tool.avail}'
                                    : '${tool.avail! - 1}')
                                : '${tool.avail! + 1}',
                            style: const TextStyle(color: Colors.green),
                          ),
                          TextSpan(
                              text: ') ${context.localize('issued')}: ',
                              style: TextStyle(
                                  color: AppTheme.dialogText(context))),
                          TextSpan(
                              text: '${tool.issued}',
                              style: TextStyle(
                                  color: AppTheme.dialogText(context))),
                          TextSpan(
                              text: ' ---> (',
                              style: TextStyle(
                                  color: AppTheme.dialogText(context))),
                          TextSpan(
                            text: widget.isIssue
                                ? '${tool.issued! + 1}'
                                : '${tool.issued! - 1}',
                            style: const TextStyle(color: Colors.green),
                          ),
                          TextSpan(
                              text: ')',
                              style: TextStyle(
                                  color: AppTheme.dialogText(context))),
                          if (widget.isIssue &&
                              widget.issuedCheckStates[exchangeId] == true)
                            TextSpan(
                                text:
                                    ' ${context.localize('issuereturnnewtool')} ',
                                style: TextStyle(
                                    color: AppTheme.dialogText(context))),
                          if (widget.isIssue &&
                              widget.issuedCheckStates[exchangeId] == true)
                            TextSpan(
                              text: '${tool.extcab}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          if (widget.isIssue &&
                              widget.issuedCheckStates[exchangeId] == true)
                            TextSpan(
                                text: ' ---> (',
                                style: TextStyle(
                                    color: AppTheme.dialogText(context))),
                          if (widget.isIssue &&
                              widget.issuedCheckStates[exchangeId] == true)
                            TextSpan(
                              text: '${tool.extcab! - 1}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          if (widget.isIssue &&
                              widget.issuedCheckStates[exchangeId] == true)
                            TextSpan(
                                text: ')',
                                style: TextStyle(
                                    color: AppTheme.dialogText(context))),
                        ],
                      ),
                    ),
                    if (widget.isIssue)
                      Text(
                        widget.machineNumbers[exchangeId] != null
                            ? '${context.localize('machine')} #${widget.machineNumbers[exchangeId]}'
                            : '${context.localize('issuereturntoolnotselected')}',
                        style: TextStyle(
                            color: widget.machineNumbers[exchangeId] != null
                                ? Colors.orange.shade900
                                : Colors.red),
                      ),
                    if (!widget.isIssue)
                      Text(
                        '${tool.cabinet}',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                  ],
                )),
              );
            }).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            _handleIssueOrReturn();
            Provider.of<ToolExchangeNotifier>(context, listen: false)
                .updateTools();
            Navigator.of(context).pop();
            toast.showToast(
              widget.isIssue
                  ? "${context.localize('toastissuedsuccessfully')}"
                  : "${context.localize('toastreturnedsuccessfully')}",
              bgColor: AppTheme.toastColor(context),
            );
          },
          child: const Text('Yes'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('No'),
        ),
      ],
    );
  }
}
