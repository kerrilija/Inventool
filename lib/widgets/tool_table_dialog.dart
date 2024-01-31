import 'package:flutter/material.dart';
import 'package:inventool/models/tool.dart';
import 'package:inventool/database.dart';
import 'package:inventool/widgets/toast_util.dart';
import 'package:inventool/main.dart';
import 'package:inventool/screens/exchange_screen.dart';
import 'package:inventool/widgets/search_widget.dart';
import 'package:inventool/widgets/tool_form.dart';
import 'package:inventool/utils/app_theme.dart';
import 'package:inventool/locale/locale.dart';

class ToolTableDialog extends StatefulWidget {
  final Map<int, Tool> tools;
  final DatabaseHelper databaseHelper;
  final int? machineNumber;
  final ToolExchangeNotifier notifier;
  final List<ToolAction> actionTypes;

  ToolTableDialog({
    required this.tools,
    required this.databaseHelper,
    this.machineNumber,
    required this.notifier,
    required this.actionTypes,
  });

  @override
  _ToolTableDialogState createState() => _ToolTableDialogState();
}

class _ToolTableDialogState extends State<ToolTableDialog> {
  late Map<int, Tool> currentTools;

  @override
  void initState() {
    super.initState();
    currentTools = Map.from(widget.tools);
  }

  Widget _createActionButton(
      ToolAction action, int exchangeId, Tool tool, int index) {
    String label = "";
    VoidCallback? onPressed;
    final toast = ToastUtil(context, MyApp.navigatorKey);

    void _refreshToolList() async {
      List<Tool> updatedLowQtyTools = await widget.databaseHelper.checkMinQty();
      if (updatedLowQtyTools.isEmpty) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          currentTools.clear();
          for (var tool in updatedLowQtyTools) {
            currentTools[tool.id!] = tool;
          }
        });
      }
    }

    switch (action) {
      case ToolAction.Return:
        label = context.localize('reportReturn');
        onPressed = () async {
          await widget.databaseHelper.processToolReturn(
            exchangeId,
            tool.sourcetable!,
            machine: widget.machineNumber,
          );
          toast.showToast(
            "${context.localize('returned')}!",
            bgColor: AppTheme.toastColor(context),
          );
          setState(() {
            currentTools.remove(exchangeId);
          });
          widget.notifier.updateTools();
        };
        break;
      case ToolAction.Edit:
        label = context.localize('reportEdit');
        onPressed = () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ToolFormScreen(
                tool: tool,
                connection: widget.databaseHelper.connection,
              ),
            ),
          );
          _refreshToolList();
        };
        break;
      default:
        label = "Unimplemented";
        onPressed = () {
          toast.showToast(
            "Action not implemented yet",
            bgColor: AppTheme.toastColor(context),
          );
        };
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Color> cardInnerColors = theme.brightness == Brightness.light
        ? AppTheme.machineCardInnerColorsLight
        : AppTheme.machineCardInnerColorsDark;

    String title = widget.machineNumber != null
        ? '${context.localize('machine')} #${widget.machineNumber} ${context.localize('tools')}'
        : context.localize('lowqtytools');

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 20,
            ),
          ),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: currentTools.isEmpty,
                child: Text(context.localize('machinecardempty')),
              ),
              ...List<Widget>.generate(currentTools.length, (index) {
                var entry = currentTools.entries.elementAt(index);
                return Card(
                  color: cardInnerColors[index % cardInnerColors.length],
                  child: ListTile(
                    title: Text(
                      '${entry.value.mfr ?? context.localize('unknownmfr')} ${entry.value.tooltype} Ø ${entry.value.parseTipdia()} ${entry.value.invnum}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.actionTypes.map((actionType) {
                        return _createActionButton(
                            actionType, entry.key, entry.value, entry.key);
                      }).toList(),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
