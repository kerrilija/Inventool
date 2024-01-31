import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:inventool/locale/locale.dart';
import 'package:inventool/models/tool.dart';
import 'package:inventool/database.dart';
import 'package:provider/provider.dart';
import 'package:inventool/widgets/issue_return_dialog.dart';
import 'package:inventool/utils/app_theme.dart';

class ToolExchangeNotifier with ChangeNotifier {
  Map<int, int> machineNumbers = {};
  Map<int, bool> issuedCheckStates = {};

  void updateMachineNumber(int exchangeId, int machineNumber) {
    machineNumbers[exchangeId] = machineNumber;
    notifyListeners();
  }

  void updateTools() {
    notifyListeners();
  }

  void toolUpdated() {
    notifyListeners();
  }

  void updateIssuedCheckState(int exchangeId, bool newState) {
    issuedCheckStates[exchangeId] = newState;
    notifyListeners();
  }
}

class ExchangeScreen extends StatefulWidget {
  final PostgreSQLConnection connection;

  ExchangeScreen({required this.connection});

  @override
  _ExchangeScreenState createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  Map<int, int> _machineNumbers = {};
  late DatabaseHelper databaseHelper;
  Map<int, Tool> issued = {};
  Map<int, Tool> returned = {};
  Map<int, bool> _issuedCheckStates = {};

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    fetchIssuedTools();
    fetchReturnedTools();

    var notifier = Provider.of<ToolExchangeNotifier>(context, listen: false);
    _machineNumbers = Map.from(notifier.machineNumbers);
    _issuedCheckStates = Map.from(notifier.issuedCheckStates);
  }

  String? parseExternalCabinet(Tool result) {
    String? string = "";

    if (result.ftscab != null) {
      string = 'FTS: ${result.ftscab}';
    }
    if (result.strcab != null) {
      string = 'Strojotehnika: ${result.strcab}';
    }
    if (result.pfrcab != null) {
      string = 'Pfeifer: ${result.pfrcab}';
    }
    if (result.mitsucab != null) {
      string = 'Mitsubishi: ${result.mitsucab}';
    }
    return string;
  }

  Future<void> fetchIssuedTools() async {
    final Map<int, Tool> issuedTools = await databaseHelper.fetchIssued();
    setState(() {
      issued = issuedTools;

      for (final exchangeId in issued.keys) {
        if (!_issuedCheckStates.containsKey(exchangeId)) {
          _issuedCheckStates[exchangeId] = false;
        }
      }
    });
  }

  Future<void> fetchReturnedTools() async {
    final Map<int, Tool> returnedTools = await databaseHelper.fetchReturned();
    setState(() {
      returned = returnedTools;
    });
  }

  void _showIssueReturnDialog(bool isIssue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return IssueReturnDialog(
          tools: isIssue ? issued : returned,
          title: isIssue
              ? '${context.localize('exchangescreentitleissue')}'
              : '${context.localize('exchangescreentitlereturn')}',
          databaseHelper: databaseHelper,
          isIssue: isIssue,
          issuedCheckStates: _issuedCheckStates,
          machineNumbers: _machineNumbers,
          onDialogClose: (updatedExchangeIds) {
            setState(() {
              if (isIssue) {
                updatedExchangeIds.forEach((exchangeId) {
                  issued.remove(exchangeId);
                });
              } else {
                updatedExchangeIds.forEach((exchangeId) {
                  returned.remove(exchangeId);
                });
              }
            });
          },
        );
      },
    ).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Color> cardInnerColors = theme.brightness == Brightness.light
        ? AppTheme.machineCardInnerColorsLight
        : AppTheme.machineCardInnerColorsDark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${context.localize('exchangescreentitle')}'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Text('${context.localize('exchangescreenissuecaption')}'),
                      Visibility(
                        visible: issued.isEmpty,
                        child: Card(
                          child: ListTile(
                            title: Text(
                                '${context.localize('exchangescreenissueempty')}'),
                          ),
                        ),
                      ),
                      if (issued.isNotEmpty)
                        Card(
                          elevation: 0,
                          child: Column(
                            children: [
                              ...List.generate(issued.keys.length, (index) {
                                int exchangeId = issued.keys.elementAt(index);
                                Tool tool = issued[exchangeId]!;
                                return Card(
                                  color: cardInnerColors[
                                      index % cardInnerColors.length],
                                  child: ListTile(
                                    title: Text(
                                      '${tool.mfr} ${tool.tooltype} Ø ${tool.parseTipdia()} ${tool.invnum}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DropdownButton<int>(
                                          value: _machineNumbers[exchangeId],
                                          hint: Text(
                                              '${context.localize('machine')}'),
                                          items: [1, 2, 3, 4, 5, 6, 7]
                                              .map((int value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(value.toString()),
                                            );
                                          }).toList(),
                                          onChanged: (int? newValue) {
                                            setState(() {
                                              _machineNumbers[exchangeId] =
                                                  newValue!;
                                            });
                                            Provider.of<ToolExchangeNotifier>(
                                                    context,
                                                    listen: false)
                                                .updateMachineNumber(
                                                    exchangeId, newValue!);
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        Text('${context.localize('new')}?'),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6.0),
                                          child: Checkbox(
                                            value: _issuedCheckStates[
                                                    exchangeId] ??
                                                false,
                                            onChanged: (bool? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  _issuedCheckStates[
                                                      exchangeId] = newValue;
                                                });
                                                Provider.of<ToolExchangeNotifier>(
                                                        context,
                                                        listen: false)
                                                    .updateIssuedCheckState(
                                                        exchangeId, newValue);
                                              }
                                            },
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            databaseHelper
                                                .deleteExchangeId(exchangeId);
                                            setState(() {
                                              issued.remove(exchangeId);
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 30,
                                              maxHeight: 30,
                                            ),
                                            child: const Icon(
                                              Icons.highlight_remove_rounded,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: ElevatedButton(
                                  onPressed: () => _showIssueReturnDialog(true),
                                  child: Text(
                                      '${context.localize('exchangescreentitleissue')}'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 50),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                          '${context.localize('exchangescreenreturncaption')}'),
                      Visibility(
                        visible: returned.isEmpty,
                        child: Card(
                          child: ListTile(
                            title: Text(
                                '${context.localize('exchangescreenreturnempty')}'),
                          ),
                        ),
                      ),
                      if (returned.isNotEmpty)
                        Card(
                          elevation: 0,
                          child: Column(
                            children: [
                              ...List.generate(returned.keys.length, (index) {
                                int exchangeId = returned.keys.elementAt(index);
                                Tool tool = returned[exchangeId]!;
                                return Card(
                                  color: cardInnerColors[
                                      index % cardInnerColors.length],
                                  child: ListTile(
                                    title: Text(
                                      '${tool.mfr} ${tool.tooltype} Ø ${tool.parseTipdia()} ${tool.invnum}',
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        databaseHelper
                                            .returnToolToMachine(exchangeId);
                                        setState(() {
                                          returned.remove(exchangeId);
                                        });
                                        Provider.of<ToolExchangeNotifier>(
                                                context,
                                                listen: false)
                                            .updateTools();
                                      },
                                      child: const Icon(
                                          Icons.highlight_remove_rounded,
                                          size: 20),
                                    ),
                                  ),
                                );
                              }),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _showIssueReturnDialog(false),
                                  child: Text(
                                    '${context.localize('exchangescreentitlereturn')}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
