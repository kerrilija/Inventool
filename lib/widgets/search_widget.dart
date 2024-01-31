import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:tool_crib/database.dart';
import 'package:tool_crib/models/tool.dart';
import 'package:tool_crib/widgets/toast_util.dart';
import 'package:provider/provider.dart';
import 'package:tool_crib/screens/search_screen.dart';
import 'package:tool_crib/main.dart';
import 'package:tool_crib/widgets/tool_form.dart';
import 'package:tool_crib/utils/app_theme.dart';
import 'package:tool_crib/locale/locale.dart';

enum ToolAction { Issue, Return, Order, Dispose, Edit }

class ToolSearchWidget extends StatefulWidget {
  final PostgreSQLConnection connection;
  final List<ToolAction> actionTypes;
  final void Function(Tool)? onEdit;

  ToolSearchWidget(
      {required this.actionTypes, required this.connection, this.onEdit});

  @override
  _ToolSearchWidgetState createState() => _ToolSearchWidgetState();
}

class _ToolSearchWidgetState extends State<ToolSearchWidget> {
  late DatabaseHelper databaseHelper;
  bool isTooltypeSelected = false;
  TextEditingController textEditingController = TextEditingController();
  List<String> tooltypeSuggestions = [];
  List<String> mfrSuggestions = [];
  List<String> subtypeSuggestions = [];
  List<String> catnumSuggestions = [];
  List<String> invnumSuggestions = [];
  List<Tool> searchResults = [];
  Map<String, String> columnAliases = {
    'fimm': 'tipdiamm',
    'fiinch': 'tipdiainch',
    'radna': 'worklen',
    'kat': 'catnum',
    'inv': 'invnum',
    'korak': 'pitch',
    'vrh': 'tipsize',
  };
  double rangePercentage = 0.90;
  String? manualRangeLower;
  String? manualRangeUpper;
  String manualRangeUnit = 'mm';

  void updateTooltypeSelectedState() {
    final anyTooltypeSelected =
        _getSelectedFilters().any((filter) => filter['column'] == 'tooltype');
    setState(() {
      isTooltypeSelected = anyTooltypeSelected;
    });
  }

  TextEditingController rangePercentageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    fetchSuggestions();
    performSearch();
    updateTooltypeSelectedState();
    rangePercentageController.text = (rangePercentage * 100).toStringAsFixed(2);
  }

  void fetchSuggestions() async {
    final tooltypeSuggestions =
        await databaseHelper.fetchDistinctValues('tooltype');
    final mfrSuggestions = await databaseHelper.fetchDistinctValues('mfr');
    final subtypeSuggestionsFetched =
        await databaseHelper.fetchDistinctValues('subtype');
    final catnumSuggestionsFetched =
        await databaseHelper.fetchDistinctValues('catnum');
    final invnumSuggestionsFetched =
        await databaseHelper.fetchDistinctValues('invnum');

    setState(() {
      this.tooltypeSuggestions.addAll(tooltypeSuggestions);
      this.mfrSuggestions.addAll(mfrSuggestions);
      subtypeSuggestions.addAll(subtypeSuggestionsFetched);
      catnumSuggestions.addAll(catnumSuggestionsFetched);
      invnumSuggestions.addAll(invnumSuggestionsFetched);
    });
  }

  void fetchSubtypeSuggestionsForToolType(String toolType) async {
    final fetchedSubtypes =
        await databaseHelper.fetchDistinctValues('subtype', toolType);
    setState(() {
      subtypeSuggestions = fetchedSubtypes;
    });
  }

  List<Tool> processResults(PostgreSQLResult results) {
    return databaseHelper.processResults(results);
  }

  Future<void> performSearch({Map<String, dynamic>? manualRange}) async {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    List<Map<String, String>> selectedFilters =
        searchProvider.selectedFilters.toList();
    double rangePercentage = searchProvider.rangePercentage;

    if (manualRange != null) {
      String lowerRange = manualRange['lower'] ?? '0';
      String upperRange = manualRange['upper'] ?? '0';
      String unit = manualRange['unit'] ?? 'mm';

      selectedFilters.removeWhere((filter) =>
          filter['column'] == 'tipdiamm' || filter['column'] == 'tipdiainch');

      String filterColumn = unit == 'mm' ? 'tipdiamm' : 'tipdiainch';
      selectedFilters.add({
        'column': filterColumn,
        'value': '$lowerRange-$upperRange',
      });
    }

    final resultList = await databaseHelper.performSearch(selectedFilters,
        shouldLogQuery: selectedFilters.isNotEmpty,
        manualRange: manualRange,
        rangePercentage: rangePercentage);

    searchProvider.updateSearchResults(resultList);

    setState(() {
      searchResults = resultList;
    });
  }

  String? determineColumnName(String selectedValue) {
    if (tooltypeSuggestions.contains(selectedValue)) {
      return 'tooltype';
    } else if (mfrSuggestions.contains(selectedValue)) {
      return 'mfr';
    } else if (subtypeSuggestions.contains(selectedValue)) {
      return 'subtype';
    } else if (catnumSuggestions.contains(selectedValue)) {
      return 'catnum';
    } else if (invnumSuggestions.contains(selectedValue)) {
      return 'invnum';
    }
    return null;
  }

  void addFilter(String column, String value, TextEditingController controller,
      {Map<String, dynamic>? manualRange}) {
    final updatedFilters = Provider.of<SearchProvider>(context, listen: false)
        .selectedFilters
        .toList();

    if (manualRange != null &&
        manualRange.containsKey('lower') &&
        manualRange.containsKey('upper')) {
      updatedFilters.removeWhere((filter) => filter['column'] == column);
      updatedFilters.add({
        'column': column,
        'value': '${manualRange['lower']}-${manualRange['upper']}',
      });
    } else {
      final filter = {'column': column, 'value': value};
      updatedFilters.add(filter);
    }

    Provider.of<SearchProvider>(context, listen: false)
        .updateSelectedFilters(updatedFilters);

    if (column == 'tooltype') {
      fetchSubtypeSuggestionsForToolType(value);
    }

    controller.clear();
    updateTooltypeSelectedState();
  }

  void removeFilter(int index) {
    final updatedFilters = Provider.of<SearchProvider>(context, listen: false)
        .selectedFilters
        .toList();
    var removedFilter = updatedFilters[index];
    updatedFilters.removeAt(index);
    Provider.of<SearchProvider>(context, listen: false)
        .updateSelectedFilters(updatedFilters);

    bool tooltypeFilterExists =
        updatedFilters.any((filter) => filter['column'] == 'tooltype');
    if (!tooltypeFilterExists && removedFilter['column'] == 'tooltype') {
      setState(() {
        subtypeSuggestions.clear();
      });
    }

    updateTooltypeSelectedState();
  }

  List<Map<String, String>> _getSelectedFilters() {
    return Provider.of<SearchProvider>(context, listen: false).selectedFilters;
  }

  Widget buildOnExpandedWidget(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 16.0,
        height: 1.5,
      ),
    );
  }

  Widget buildOnExpandedWidgetVendor(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16.0,
        height: 1.5,
      ),
    );
  }

  List<Widget> onExpandedWidgetsLeft(Tool result) {
    List<Widget> widgets = [];

    if (result.catnum != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('catnum')}: ${result.catnum}'));
    }

    if (result.materialParse() != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('materials')}: ${result.materialParse()}'));
    }
    if (result.bladecnt != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('bladecnt')}: ${result.bladecnt}'));
    }
    if (result.unit != null) {
      widgets.add(
          buildOnExpandedWidget('${context.localize('unit')}: ${result.unit}'));
    }
    if (result.tiptype != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('tiptype')}: ${result.tiptype}'));
    }
    if (result.tipsize != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('tipsize')}: ${result.tipsize} mm'));
    }
    if (result.coating != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('coating')}: ${result.coating}'));
    }
    if (result.splen != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('splen')}: ${result.splen} mm'));
    }
    if (result.toollen != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('toollen')}: ${result.toollen} mm'));
    }
    if (result.neckdia != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('neckdia')}: ${result.neckdia} mm'));
    }
    if (result.pitch != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('pitch')}: ${result.pitch} mm'));
    }
    if (result.shankdia != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('shankdia')}: ${result.shankdia} mm'));
    }
    if (result.grinded != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('grinded')}: ${result.grinded}'));
    }

    return widgets;
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

  List<Widget> onExpandedWidgetsRightDown(Tool result) {
    List<Widget> widgets = [];

    if (result.qty != null) {
      widgets.add(
          buildOnExpandedWidget('${context.localize('total')}: ${result.qty}'));
    }
    if (result.issued != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('issued')}: ${result.issued}'));
    }
    if (result.avail != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('avail')}: ${result.avail}'));
    }
    if (result.minqty != null) {
      widgets.add(buildOnExpandedWidget(
          '${context.localize('minqty')}: ${result.minqty}'));
    }

    return widgets;
  }

  Widget _createActionButton(ToolAction action, Tool tool) {
    String label = "";
    VoidCallback? onPressed;
    final toast = ToastUtil(context, MyApp.navigatorKey);

    switch (action) {
      case ToolAction.Issue:
        label = context.localize('reportIssue');
        onPressed = () {
          databaseHelper.processToolIssuance(tool.id!, tool.sourcetable!);
          databaseHelper.fetchIssued();
          toast.showToast(
            '${context.localize('toastaddedtoissue')}',
            bgColor: AppTheme.toastColor(context),
          );
        };
        break;
      case ToolAction.Return:
        label = context.localize('reportReturn');
        onPressed = () {
          databaseHelper.processToolReturn(tool.id!, tool.sourcetable!);
          toast.showToast(
            '${context.localize('toastaddedtoreturn')}',
            bgColor: AppTheme.toastColor(context),
          );
        };
        break;
      case ToolAction.Order:
        label = "Order";
        onPressed = () {};
        break;
      case ToolAction.Dispose:
        label = context.localize('reportDispose');
        onPressed = () {
          databaseHelper.processToolDisposal(tool.id!, tool.sourcetable!);
          toast.showToast(
            '${context.localize('toastaddedtodispose')}',
            bgColor: AppTheme.toastColor(context),
          );
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
                connection: databaseHelper.connection,
              ),
            ),
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
    String? alias;
    String? filterValue;
    final toast = ToastUtil(context, MyApp.navigatorKey);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              final suggestions = <String>[];
              final pattern = textEditingValue.text.toLowerCase();

              if (pattern.isNotEmpty) {
                suggestions.addAll(tooltypeSuggestions.where((suggestion) =>
                    suggestion.toLowerCase().contains(pattern)));
                suggestions.addAll(mfrSuggestions.where((suggestion) =>
                    suggestion.toLowerCase().contains(pattern)));
                suggestions.addAll(catnumSuggestions.where((suggestion) =>
                    suggestion.toLowerCase().contains(pattern)));
                suggestions.addAll(invnumSuggestions.where((suggestion) =>
                    suggestion.toLowerCase().contains(pattern)));

                if (isTooltypeSelected) {
                  suggestions.addAll(subtypeSuggestions.where((suggestion) =>
                      suggestion.toLowerCase().contains(pattern)));
                }
              }
              return Iterable<String>.generate(
                  suggestions.length, (index) => suggestions[index]);
            },
            onSelected: (String value) {
              final columnName = determineColumnName(value);
              if (columnName != null) {
                textEditingController.clear();
                addFilter(columnName, value, textEditingController);
                updateTooltypeSelectedState();
              }
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController fieldTextEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              textEditingController = fieldTextEditingController;
              return TextField(
                controller: fieldTextEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: '${context.localize('searchwidgetsearchlabel')}',
                  suffixIcon: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.back_hand_rounded),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String localManualRangeUnit = manualRangeUnit;
                              String? localManualRangeLower;
                              String? localManualRangeUpper;

                              final searchProvider =
                                  Provider.of<SearchProvider>(context,
                                      listen: false);

                              TextEditingController rangePercentageController =
                                  TextEditingController();
                              rangePercentageController.text =
                                  (searchProvider.rangePercentage * 100 % 1 ==
                                          0)
                                      ? (searchProvider.rangePercentage * 100)
                                          .toInt()
                                          .toString()
                                      : (searchProvider.rangePercentage * 100)
                                          .toStringAsFixed(2);

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Text(
                                        '${context.localize('manualsearchdialogtitle')}'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: rangePercentageController,
                                          decoration: InputDecoration(
                                            labelText:
                                                '${context.localize('manualsearchrangetolerance')}',
                                            hintText:
                                                '${context.localize('manualsearchmanualrange')}',
                                          ),
                                          onChanged: (value) {
                                            double? enteredPercentage =
                                                double.tryParse(value);
                                            if (enteredPercentage != null) {
                                              double newRangePercentage =
                                                  enteredPercentage / 100;
                                              searchProvider.updateConfig(
                                                  databaseHelper,
                                                  'rangePercentage',
                                                  newRangePercentage
                                                      .toString());
                                              setState(() {
                                                rangePercentage =
                                                    newRangePercentage;
                                              });
                                            }
                                          },
                                        ),
                                        TextField(
                                          decoration: InputDecoration(
                                            labelText:
                                                '${context.localize('manualsearchlower')}',
                                            hintText:
                                                '${context.localize('manualsearchlowerhint')}',
                                          ),
                                          onChanged: (value) {
                                            localManualRangeLower = value;
                                          },
                                        ),
                                        TextField(
                                          decoration: InputDecoration(
                                            labelText:
                                                '${context.localize('manualsearchupper')}',
                                            hintText:
                                                '${context.localize('manualsearchupperhint')}',
                                          ),
                                          onChanged: (value) {
                                            localManualRangeUpper = value;
                                          },
                                        ),
                                        Row(
                                          children: [
                                            Radio<String>(
                                              value: 'mm',
                                              groupValue: localManualRangeUnit,
                                              onChanged: (String? value) {
                                                if (value != null) {
                                                  setState(() {
                                                    localManualRangeUnit =
                                                        value;
                                                  });
                                                }
                                              },
                                            ),
                                            const Text('mm'),
                                            Radio<String>(
                                              value: 'inch',
                                              groupValue: localManualRangeUnit,
                                              onChanged: (String? value) {
                                                if (value != null) {
                                                  setState(() {
                                                    localManualRangeUnit =
                                                        value;
                                                  });
                                                }
                                              },
                                            ),
                                            const Text('inch'),
                                          ],
                                        ),
                                        ElevatedButton(
                                          child: Text(
                                              '${context.localize('manualrangeapply')}'),
                                          onPressed: () {
                                            bool shouldApplyManualRange =
                                                localManualRangeLower != null &&
                                                    localManualRangeUpper !=
                                                        null;
                                            if (shouldApplyManualRange) {
                                              double? lowerRange =
                                                  double.tryParse(
                                                      localManualRangeLower!);
                                              double? upperRange =
                                                  double.tryParse(
                                                      localManualRangeUpper!);

                                              if (lowerRange == null ||
                                                  upperRange == null) {
                                                toast.showToast(
                                                  '${context.localize('toastinvalidrange')}',
                                                  bgColor: AppTheme.toastColor(
                                                      context),
                                                );
                                                return;
                                              }

                                              setState(() {
                                                manualRangeUnit =
                                                    localManualRangeUnit;
                                                manualRangeLower =
                                                    localManualRangeLower;
                                                manualRangeUpper =
                                                    localManualRangeUpper;
                                              });

                                              final String filterColumn =
                                                  localManualRangeUnit == 'mm'
                                                      ? 'tipdiamm'
                                                      : 'tipdiainch';

                                              addFilter(filterColumn, '',
                                                  TextEditingController(),
                                                  manualRange: {
                                                    'lower':
                                                        lowerRange.toString(),
                                                    'upper':
                                                        upperRange.toString(),
                                                  });

                                              toast.showToast(
                                                  '${context.localize('toastrangeapplied')}',
                                                  bgColor: AppTheme.toastColor(
                                                      context));
                                            } else {
                                              double? enteredPercentage =
                                                  double.tryParse(
                                                          rangePercentageController
                                                              .text) ??
                                                      0;
                                              double newRangePercentage =
                                                  enteredPercentage / 100;
                                              searchProvider.updateConfig(
                                                  databaseHelper,
                                                  'rangePercentage',
                                                  newRangePercentage
                                                      .toString());
                                              toast.showToast(
                                                  '${context.localize('toastdefaultrangechanged')}',
                                                  bgColor: AppTheme.toastColor(
                                                      context));
                                            }
                                            Navigator.of(context).pop();
                                            performSearch();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                    '${context.localize('helpdialogtitle')}'),
                                content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${context.localize('helpdialogtipdia')}'),
                                      Text(
                                          '${context.localize('helpdialogworklen')}'),
                                      Text(
                                          '${context.localize('helpdialogcatnum')}'),
                                      Text(
                                          '${context.localize('helpdialoginvnum')}'),
                                      Text(
                                          '${context.localize('helpdialogpitch')}'),
                                      Text(
                                          '${context.localize('helpdialogtipsize')}'),
                                      SizedBox(height: 16),
                                      Text(
                                          '${context.localize('helpdialogexample')}')
                                    ]),
                                actions: <Widget>[
                                  ElevatedButton(
                                    child: Text(
                                        '${context.localize('buttonclose')}'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          performSearch();
                          fieldTextEditingController.clear();
                        },
                      ),
                    ],
                  ),
                ),
                onChanged: (String value) {
                  if (value.endsWith(' ')) {
                    alias = value.trim();
                  } else if (alias != null) {
                    filterValue = value;
                  } else {
                    alias = null;
                    filterValue = null;
                  }
                },
                onSubmitted: (String value) {
                  onFieldSubmitted();
                  if (alias != null && filterValue != null) {
                    final filterColumn = columnAliases[alias!];
                    if (filterColumn != null && filterValue != null) {
                      filterValue = filterValue?.split(" ")[1];
                      addFilter(
                          filterColumn, filterValue!, textEditingController);
                    }
                    alias = null;
                    filterValue = null;
                  }
                  performSearch();
                  fieldTextEditingController.clear();
                  FocusScope.of(context).requestFocus(focusNode);
                },
              );
            },
            optionsViewBuilder: (BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options) {
              final highlightedIndex =
                  AutocompleteHighlightedOption.of(context);

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: SizedBox(
                    height: 300.0,
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);

                        return ListTile(
                          tileColor: index == highlightedIndex
                              ? Theme.of(context).focusColor.withOpacity(0.1)
                              : null,
                          title: Text(option),
                          onTap: () {
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          Consumer<SearchProvider>(
            builder: (context, searchProvider, child) {
              return Wrap(
                children: searchProvider.selectedFilters.map((filter) {
                  String displayValue = filter['value']!;
                  if (filter['column'] == 'tipdiamm' ||
                      filter['column'] == 'tipdiainch') {
                    displayValue +=
                        filter['column'] == 'tipdiamm' ? ' mm' : ' inch';
                  }
                  return Padding(
                      padding: const EdgeInsets.only(right: 4, top: 4),
                      child: Chip(
                        label: Text('${filter['column']} = $displayValue'),
                        onDeleted: () {
                          removeFilter(
                              searchProvider.selectedFilters.indexOf(filter));
                          performSearch();
                        },
                      ));
                }).toList(),
              );
            },
          ),
          Expanded(
            child: Consumer<SearchProvider>(
                builder: (context, searchProvider, child) {
              return ListView.builder(
                itemCount: searchProvider.searchResults?.length ?? 0,
                itemBuilder: (context, index) {
                  final result = searchProvider.searchResults![index];
                  String title;
                  if (result.subtype == 'Glodalo za skidanje srha') {
                    title =
                        '${result.subtype} Ø ${result.parseTipdia()} ${result.tiptype}';
                  } else if (result.tooltype
                          .toLowerCase()
                          .startsWith('t-glodalo') &&
                      result.tslotdp != null) {
                    title =
                        '${result.subtype} Ø ${result.parseTipdia()} x ${result.tslotdp}';
                  } else if (result.tooltype == 'Ureznik') {
                    title =
                        '${result.subtype} ${result.parseTipdia()} x ${result.pitch}';
                  } else {
                    title =
                        '${result.subtype} Ø ${result.parseTipdia()}${result.unit == 'mm' ? ' mm' : '"'}';
                  }
                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: ExpansionTile(
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${result.mfr ?? '${context.localize('unknownmfr')}'} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      height: 1.5,
                                    ),
                                  ),
                                  Text(
                                    result.invnum,
                                    style: TextStyle(
                                      color: AppTheme.invNumText(context),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  height: 1.5,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${result.cabinet} ',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      height: 1.5,
                                      color: AppTheme.toolLocationText(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '(${context.localize('avail')} ${result.avail}, ${context.localize('issued')} ${result.issued})',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Visibility(
                                  visible:
                                      result.parseLengthAndMaterial(context) !=
                                          null,
                                  child: Text(
                                    result.parseLengthAndMaterial(context) ??
                                        '',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      height: 1.5,
                                      color:
                                          AppTheme.parseMaterialText(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ...widget.actionTypes.map((actionType) {
                                  return _createActionButton(
                                      actionType, result);
                                }).toList(),
                                const SizedBox(width: 50),
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    '${parseExternalCabinet(result)}'.isEmpty
                                        ? ''
                                        : '${parseExternalCabinet(result)} \n${result.extcab} ${context.localize('new')}',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      children: <Widget>[
                        Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 16.0),
                          elevation: 0,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: onExpandedWidgetsLeft(result),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: onExpandedWidgetsRightDown(result),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
