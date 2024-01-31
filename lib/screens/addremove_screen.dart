import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:inventool/database.dart';
import 'package:inventool/models/tool.dart';
import 'package:inventool/screens/edit_tool_screen.dart';
import 'package:inventool/widgets/tool_form.dart';
import 'package:inventool/widgets/navigation_card.dart';
import 'package:inventool/widgets/toast_util.dart';
import 'package:inventool/main.dart';
import 'package:inventool/utils/app_theme.dart';
import 'package:inventool/screens/exchange_screen.dart';
import 'package:provider/provider.dart';
import 'package:inventool/locale/locale.dart';

class ToolFormProvider with ChangeNotifier {
  Tool? _toolData;

  Tool? get toolData => _toolData;

  void updateToolData(Tool tool) {
    _toolData = tool;
    notifyListeners();
  }

  void clearToolData() {
    _toolData = null;
    notifyListeners();
  }
}

class AddRemoveScreen extends StatefulWidget {
  final PostgreSQLConnection connection;
  AddRemoveScreen({required this.connection});

  @override
  _AddRemoveScreenState createState() => _AddRemoveScreenState();
}

class _AddRemoveScreenState extends State<AddRemoveScreen> {
  Map<int, Tool> disposed = {};
  late DatabaseHelper databaseHelper;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    fetchDisposedTools();
  }

  Future<void> fetchDisposedTools() async {
    final disposedTools = await databaseHelper.fetchDisposed();
    setState(() {
      disposed = disposedTools;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Color> cardInnerColors = theme.brightness == Brightness.light
        ? AppTheme.machineCardInnerColorsLight
        : AppTheme.machineCardInnerColorsDark;

    final toast = ToastUtil(context, MyApp.navigatorKey);

    return Scaffold(
      appBar: AppBar(
        title: Text('${context.localize('addremovescreentitle')}'),
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text('${context.localize('addremovescreendisposecaption')}',
                    style: TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                Visibility(
                  visible: disposed.isEmpty,
                  child: Card(
                    child: ListTile(
                      title: Text(
                          '${context.localize('addremovescreendisposedempty')}'),
                    ),
                  ),
                ),
                Card(
                  elevation: 0,
                  child: Column(
                    children: [
                      if (disposed.isNotEmpty)
                        ...disposed.entries.map((entry) {
                          Tool tool = entry.value;
                          return Card(
                            color: cardInnerColors[
                                entry.key % cardInnerColors.length],
                            child: ListTile(
                              title: Text(
                                '${tool.mfr} ${tool.tooltype} Ø ${tool.parseTipdia()} ${tool.invnum}',
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  databaseHelper.deleteExchangeId(entry.key);
                                  setState(() {
                                    disposed.remove(entry.key);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(
                                  Icons.highlight_remove_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      Visibility(
                        visible: disposed.isNotEmpty,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                        '${context.localize('addremovescreentitledispose')}'),
                                    content: Column(
                                      children: disposed.entries.map((entry) {
                                        Tool tool = entry.value;
                                        return Card(
                                          color: cardInnerColors[entry.key % 2],
                                          child: ListTile(
                                            title: Column(
                                              children: [
                                                Text(
                                                  '${tool.mfr} ${tool.tooltype} Ø ${tool.parseTipdia()} ${tool.invnum} ',
                                                ),
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                          text:
                                                              '${context.localize('avail')}: ',
                                                          style: TextStyle(
                                                              color: AppTheme
                                                                  .dialogText(
                                                                      context))),
                                                      TextSpan(
                                                        text: (tool.avail)
                                                            .toString(),
                                                        style: const TextStyle(
                                                            color: Colors.grey),
                                                      ),
                                                      TextSpan(
                                                          text: ' ---> (',
                                                          style: TextStyle(
                                                              color: AppTheme
                                                                  .dialogText(
                                                                      context))),
                                                      TextSpan(
                                                        text:
                                                            '${tool.avail! - 1}',
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.green),
                                                      ),
                                                      TextSpan(
                                                          text:
                                                              ') ${context.localize('total')}: ',
                                                          style: TextStyle(
                                                              color: AppTheme
                                                                  .dialogText(
                                                                      context))),
                                                      TextSpan(
                                                        text: (tool.qty)
                                                            .toString(),
                                                        style: const TextStyle(
                                                            color: Colors.grey),
                                                      ),
                                                      TextSpan(
                                                          text: ' ---> (',
                                                          style: TextStyle(
                                                              color: AppTheme
                                                                  .dialogText(
                                                                      context))),
                                                      TextSpan(
                                                        text:
                                                            '${tool.qty! - 1}',
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.green),
                                                      ),
                                                      TextSpan(
                                                          text: ') ',
                                                          style: TextStyle(
                                                              color: AppTheme
                                                                  .dialogText(
                                                                      context)))
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        onPressed: () {
                                          for (final entry
                                              in disposed.entries) {
                                            databaseHelper
                                                .disposeTool(entry.value);
                                            databaseHelper
                                                .deleteExchangeId(entry.key);
                                          }
                                          Provider.of<ToolExchangeNotifier>(
                                                  context,
                                                  listen: false)
                                              .updateTools();

                                          toast.showToast(
                                              '${context.localize('toastdisposedsuccessfully')}',
                                              bgColor:
                                                  AppTheme.toastColor(context),
                                              duration: 2);
                                          setState(() {
                                            disposed.clear();
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                            '${context.localize('buttonyes')}'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                            '${context.localize('buttonno')}'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Text(
                              '${context.localize('addremovescreentitledispose')}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NavigationCard(
                title: '${context.localize('navcardaddnewtool')}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ToolFormScreen(
                        tool: null,
                        connection: widget.connection,
                      ),
                    ),
                  );
                },
              ),
              NavigationCard(
                title: '${context.localize('navcardedittool')}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditToolScreen(
                        connection: widget.connection,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
