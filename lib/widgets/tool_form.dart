import 'package:flutter/material.dart';
import 'package:inventool/models/tool.dart';
import 'package:postgres/postgres.dart';
import 'package:inventool/database.dart';
import 'package:inventool/widgets/insert_tool_dialog.dart';
import 'package:inventool/widgets/toast_util.dart';
import 'package:inventool/main.dart';
import 'dart:math';
import 'package:inventool/screens/exchange_screen.dart';
import 'package:provider/provider.dart';
import 'package:inventool/utils/app_theme.dart';
import 'package:inventool/locale/locale.dart';

class ToolForm extends StatefulWidget {
  final Tool? initialTool;
  final PostgreSQLConnection connection;

  ToolForm({this.initialTool, required this.connection});

  @override
  _ToolFormState createState() => _ToolFormState();
}

class _ToolFormState extends State<ToolForm> {
  int? toolId;
  String? sourceTable;
  String? subtype;
  String unitValue = 'mm';
  late DatabaseHelper databaseHelper;
  List<String> tooltypeSuggestions = [];
  List<String> mfrSuggestions = [];
  List<String> holdertypeSuggestions = [];
  List<String> subtypeSuggestions = [];
  List<String> coatingSuggestions = [];
  List<String> grindedSuggestions = [];
  List<String> tiptypeSuggestions = [];
  List<String> materialSuggestions = [];

  late TextEditingController toolTypeController;
  late TextEditingController invNumController;
  late TextEditingController catNumController;
  late TextEditingController unitController;
  late TextEditingController grindedController;
  late TextEditingController mfrController;
  late TextEditingController holdertypeController;
  late TextEditingController tipdiaController;
  late TextEditingController shankdiaController;
  late TextEditingController pitchController;
  late TextEditingController neckdiaController;
  late TextEditingController tslotdpController;
  late TextEditingController toollenController;
  late TextEditingController splenController;
  late TextEditingController worklenController;
  late TextEditingController bladecntController;
  late TextEditingController tiptypeController;
  late TextEditingController tipsizeController;
  late TextEditingController materialController;
  late TextEditingController coatingController;
  late TextEditingController inserttypeController;
  late TextEditingController cabinetController;
  late TextEditingController qtyController;
  late TextEditingController issuedController;
  late TextEditingController availController;
  late TextEditingController minqtyController;
  late TextEditingController ftscabController;
  late TextEditingController strcabController;
  late TextEditingController pfrcabController;
  late TextEditingController mitsucabController;
  late TextEditingController extcabController;
  late TextEditingController subtypeController;

  Map<String, bool> booleanValues = {
    'steel': false,
    'stainless': false,
    'castiron': false,
    'aluminum': false,
    'universal': false,
  };

  Map<String, String> tooltypeToSourcetable = {
    "Prihvat": "fixture",
    "Čahura": "fixture",
    "Glodalo za navoj": "threadmaking",
    "T-Glodalo": "tool",
    "Pločica": "tool",
    "Alat za štosanje": "tool",
    "Svrdlo": "tool",
    "Trkač": "tool",
    "Uvaljivač": "threadmaking",
    "Upuštač": "tool",
    "Glodalo": "tool",
    "Glava": "tool",
    "Lastin rep": "tool",
    "Centar punta": "tool",
    "Ureznik": "threadmaking",
    "Pila": "tool",
    "Trivela": "tool",
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    databaseHelper = DatabaseHelper(connection: widget.connection);
    fetchSuggestions();
    toolTypeController.addListener(() {
      if (toolTypeController.text.isNotEmpty) {
        fetchSubtypeSuggestions(toolTypeController.text);
      } else {
        setState(() {
          subtypeSuggestions.clear();
        });
      }
    });

    if (widget.initialTool != null) {
      toolId = widget.initialTool!.id;
      sourceTable = widget.initialTool!.sourcetable;
      subtype = widget.initialTool!.subtype;

      if (widget.initialTool!.tooltype.isNotEmpty) {
        fetchSubtypeSuggestions(widget.initialTool!.tooltype);
        toolTypeController.text = widget.initialTool!.tooltype;
      }
    }
  }

  void fetchSuggestions() async {
    final tooltypeSuggestions =
        await databaseHelper.fetchDistinctValues('tooltype');
    final mfrSuggestions = await databaseHelper.fetchDistinctValues('mfr');
    final holdertypeSuggestions =
        await databaseHelper.fetchDistinctValues('holdertype');
    final coatingSuggestions =
        await databaseHelper.fetchDistinctValues('coating');
    final grindedSuggestions =
        await databaseHelper.fetchDistinctValues('grinded');
    final tiptypeSuggestions =
        await databaseHelper.fetchDistinctValues('tiptype');
    final materialSuggestions =
        await databaseHelper.fetchDistinctValues('material');
    setState(() {
      this.tooltypeSuggestions.addAll(tooltypeSuggestions);
      this.mfrSuggestions.addAll(mfrSuggestions);
      this.holdertypeSuggestions.addAll(holdertypeSuggestions);
      this.coatingSuggestions.addAll(coatingSuggestions);
      this.grindedSuggestions.addAll(grindedSuggestions);
      this.tiptypeSuggestions.addAll(tiptypeSuggestions);
      this.materialSuggestions.addAll(materialSuggestions);
    });
  }

  void fetchSubtypeSuggestions(String tooltype) async {
    final subtypeSuggestionsFetched =
        await databaseHelper.fetchDistinctValues('subtype', tooltype);
    setState(() {
      subtypeSuggestions = subtypeSuggestionsFetched;
    });
  }

  List<Widget> getGeneralInfoFields() {
    return [
      Container(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  buildAutoCompleteFormField(
                      toolTypeController, '${context.localize('tooltype')}'),
                  buildAutoCompleteFormField(
                      subtypeController, '${context.localize('subtype')}')
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  buildAutoCompleteFormField(
                      mfrController, '${context.localize('mfr')}'),
                  buildTextFormField(
                      catNumController, '${context.localize('catnum')}'),
                  buildTextFormField(
                      invNumController, '${context.localize('invnum')}',
                      isRequired: true),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> getToolDataFields() {
    bool showPitch =
        ['Glodalo za navoj', 'Ureznik'].contains(toolTypeController.text);
    bool showInsertType = ['Upuštač', 'Pločica', 'Glava', 'Lastin rep', 'Pila']
        .contains(toolTypeController.text);
    bool showTipSize = [
      'T-Glodalo',
      'Glodalo',
      'Pločica',
      'Glava',
      'Lastin rep'
    ].contains(toolTypeController.text);
    bool showTSlotDp = [
      'Alat za štosanje',
      'T-Glodalo',
      'Uvaljivač',
      'Glodalo',
      'Pločica',
      'Glava',
      'Ureznik',
      'Svrdlo',
      'Pila'
    ].contains(toolTypeController.text);

    return [
      Container(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 576),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        buildTextFormField(
                            tipdiaController, '${context.localize('tipdia')}'),
                        buildTextFormField(
                            splenController, '${context.localize('splen')}'),
                        buildTextFormField(worklenController,
                            '${context.localize('worklen')}'),
                        buildAutoCompleteFormField(grindedController,
                            '${context.localize('grinded')}'),
                        buildAutoCompleteFormField(tiptypeController,
                            '${context.localize('tiptype')}'),
                        if (showTipSize)
                          buildTextFormField(tipsizeController,
                              '${context.localize('tipsize')}'),
                        if (showPitch)
                          buildTextFormField(
                              pitchController, '${context.localize('pitch')}'),
                        Row(
                          children: [
                            Text(
                                ' ${context.localize('toolformunitsystem')}: '),
                            buildUnitRadio(),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildTextFormField(shankdiaController,
                            '${context.localize('shankdia')}'),
                        buildTextFormField(neckdiaController,
                            '${context.localize('neckdia')}'),
                        if (showTSlotDp)
                          buildTextFormField(tslotdpController,
                              '${context.localize('tslotdp')}'),
                        buildTextFormField(toollenController,
                            '${context.localize('toollen')}'),
                        buildTextFormField(bladecntController,
                            '${context.localize('bladecnt')}'),
                        buildAutoCompleteFormField(materialController,
                            '${context.localize('material')}'),
                        buildAutoCompleteFormField(coatingController,
                            '${context.localize('coating')}'),
                        if (showInsertType)
                          buildTextFormField(inserttypeController,
                              '${context.localize('inserttype')}'),
                        buildAutoCompleteFormField(holdertypeController,
                            '${context.localize('holdertype')}'),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(' ${context.localize('toolformmaterialscaption')}'),
                  Padding(
                    padding: EdgeInsets.only(left: 30),
                    child: Column(
                      children: [
                        buildCheckbox('${context.localize('steel')}', 'steel'),
                        buildCheckbox(
                            '${context.localize('stainless')}', 'stainless'),
                        buildCheckbox(
                            '${context.localize('castiron')}', 'castiron'),
                        buildCheckbox(
                            '${context.localize('aluminum')}', 'aluminum'),
                        buildCheckbox(
                            '${context.localize('universal')}', 'universal'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> getLocationAndQuantityFields() {
    return [
      Container(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  buildTextFormField(
                      cabinetController, '${context.localize('cabinet')}'),
                  buildTextFormField(
                      qtyController, '${context.localize('qty')}'),
                  buildTextFormField(
                      issuedController, '${context.localize('issued')}'),
                  buildTextFormField(
                      availController, '${context.localize('avail')}'),
                  buildTextFormField(
                      minqtyController, '${context.localize('minqty')}'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  buildTextFormField(
                      ftscabController, '${context.localize('ftscab')}'),
                  buildTextFormField(
                      strcabController, '${context.localize('strcab')}'),
                  buildTextFormField(
                      pfrcabController, '${context.localize('pfrcab')}'),
                  buildTextFormField(
                      mitsucabController, '${context.localize('mitsucab')}'),
                  buildTextFormField(
                      extcabController, '${context.localize('extcab')}'),
                ],
              ),
            ),
          ],
        ),
      )
    ];
  }

  void _initializeControllers() {
    toolTypeController =
        TextEditingController(text: widget.initialTool?.tooltype);
    invNumController = TextEditingController(text: widget.initialTool?.invnum);
    catNumController = TextEditingController(text: widget.initialTool?.catnum);
    unitController =
        TextEditingController(text: widget.initialTool?.unit ?? 'mm');
    unitValue = widget.initialTool?.unit ?? 'mm';
    grindedController =
        TextEditingController(text: widget.initialTool?.grinded);
    mfrController = TextEditingController(text: widget.initialTool?.mfr);
    holdertypeController =
        TextEditingController(text: widget.initialTool?.holdertype);
    tipdiaController =
        TextEditingController(text: widget.initialTool?.parseTipdia());
    shankdiaController =
        TextEditingController(text: widget.initialTool?.shankdia?.toString());
    pitchController = TextEditingController(text: widget.initialTool?.pitch);
    neckdiaController =
        TextEditingController(text: widget.initialTool?.neckdia?.toString());
    tslotdpController =
        TextEditingController(text: widget.initialTool?.tslotdp?.toString());
    toollenController =
        TextEditingController(text: widget.initialTool?.toollen?.toString());
    splenController =
        TextEditingController(text: widget.initialTool?.splen?.toString());
    worklenController =
        TextEditingController(text: widget.initialTool?.worklen?.toString());
    bladecntController =
        TextEditingController(text: widget.initialTool?.bladecnt?.toString());
    tiptypeController =
        TextEditingController(text: widget.initialTool?.tiptype);
    tipsizeController =
        TextEditingController(text: widget.initialTool?.tipsize);
    materialController =
        TextEditingController(text: widget.initialTool?.material);
    coatingController =
        TextEditingController(text: widget.initialTool?.coating);
    inserttypeController =
        TextEditingController(text: widget.initialTool?.inserttype);
    cabinetController =
        TextEditingController(text: widget.initialTool?.cabinet);
    qtyController =
        TextEditingController(text: widget.initialTool?.qty?.toString());
    issuedController =
        TextEditingController(text: widget.initialTool?.issued?.toString());
    availController =
        TextEditingController(text: widget.initialTool?.avail?.toString());
    minqtyController =
        TextEditingController(text: widget.initialTool?.minqty?.toString());
    ftscabController = TextEditingController(text: widget.initialTool?.ftscab);
    strcabController = TextEditingController(text: widget.initialTool?.strcab);
    pfrcabController = TextEditingController(text: widget.initialTool?.pfrcab);
    mitsucabController =
        TextEditingController(text: widget.initialTool?.mitsucab);
    extcabController =
        TextEditingController(text: widget.initialTool?.extcab?.toString());
    subtypeController =
        TextEditingController(text: widget.initialTool?.subtype);

    if (widget.initialTool != null) {
      booleanValues['steel'] = widget.initialTool!.steel ?? false;
      booleanValues['stainless'] = widget.initialTool!.stainless ?? false;
      booleanValues['castiron'] = widget.initialTool!.castiron ?? false;
      booleanValues['aluminum'] = widget.initialTool!.aluminum ?? false;
      booleanValues['universal'] = widget.initialTool!.universal ?? false;
    }
  }

  Widget buildAutoCompleteFormField(
      TextEditingController controller, String label) {
    List<String> suggestions = [];
    if (controller == toolTypeController) {
      suggestions.addAll(tooltypeSuggestions);
    } else if (controller == mfrController) {
      suggestions.addAll(mfrSuggestions);
    } else if (controller == holdertypeController) {
      suggestions.addAll(holdertypeSuggestions);
    } else if (controller == coatingController) {
      suggestions.addAll(coatingSuggestions);
    } else if (controller == materialController) {
      suggestions.addAll(materialSuggestions);
    } else if (controller == grindedController) {
      suggestions.addAll(grindedSuggestions);
    } else if (controller == tiptypeController) {
      suggestions.addAll(tiptypeSuggestions);
    } else if (controller == subtypeController) {
      if (toolTypeController.text.isNotEmpty) {
        suggestions.addAll(subtypeSuggestions);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          final pattern = textEditingValue.text.toLowerCase();

          final filteredSuggestions = pattern.isEmpty
              ? suggestions // Show all suggestions when the pattern is empty
              : suggestions
                  .where((suggestion) =>
                      suggestion.toLowerCase().contains(pattern))
                  .toList();

          return Iterable<String>.generate(filteredSuggestions.length,
              (index) => filteredSuggestions[index]);
        },
        onSelected: (String suggestion) {
          controller.text = suggestion;
        },
        fieldViewBuilder: (BuildContext context,
            TextEditingController fieldController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted) {
          if (fieldController.text.isEmpty && controller.text.isNotEmpty) {
            fieldController.text = controller.text;
          }

          return TextField(
            controller: fieldController,
            focusNode: fieldFocusNode,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onSubmitted: (_) {
              onFieldSubmitted();
            },
          );
        },
        optionsViewBuilder: (BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options) {
          final highlightedIndex = AutocompleteHighlightedOption.of(context);

          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: SizedBox(
                height: 300.0,
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);

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
    );
  }

  Widget buildCheckbox(String label, String key) {
    return SizedBox(
      width: 170.0,
      child: CheckboxListTile(
        title: Text(label),
        value: booleanValues[key]!,
        onChanged: (bool? value) {
          if (value != null) {
            handleCheckbox(key, value);
          }
        },
      ),
    );
  }

  void handleCheckbox(String key, bool value) {
    setState(() {
      booleanValues[key] = value;
    });
  }

  Widget buildTextFormField(TextEditingController controller, String labelText,
      {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffix: isRequired
              ? const Text(
                  '*',
                  style: TextStyle(color: Colors.red),
                )
              : null,
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return '${context.localize('toolformfieldrequired')}';
          }
          return null;
        },
      ),
    );
  }

  Widget buildUnitRadio() {
    return Column(
      children: [
        Row(
          children: [
            Radio(
              value: 'mm',
              groupValue: unitValue,
              onChanged: (value) {
                setState(() {
                  unitValue = value.toString();
                });
              },
            ),
            const Text('mm'),
          ],
        ),
        Row(
          children: [
            Radio(
              value: 'inch',
              groupValue: unitValue,
              onChanged: (value) {
                setState(() {
                  unitValue = value.toString();
                });
              },
            ),
            const Text('inch'),
          ],
        ),
      ],
    );
  }

  Tool _createToolFromFormData() {
    double? parseAndConvert(String text, double Function(double) convertFunc) {
      var parsedValue = double.tryParse(text);
      if (parsedValue != null) {
        return convertFunc(parsedValue);
      }
      return null;
    }

    double toMillimeters(double inches) => inches * 25.4;
    double toInches(double millimeters) => millimeters / 25.4;

    double? tipdiaInMm = unitValue == "mm"
        ? parseAndConvert(tipdiaController.text, (val) => val)
        : parseAndConvert(tipdiaController.text, toMillimeters);

    double? tipdiaInInch = unitValue == "inch"
        ? parseAndConvert(tipdiaController.text, (val) => val)
        : parseAndConvert(tipdiaController.text, toInches);

    String roundDouble(double? value, int places) {
      if (value == null) return 'null';
      double mod = pow(10.0, places).toDouble();
      return ((value * mod).round().toDouble() / mod).toStringAsFixed(places);
    }

    String? selectedSourcetable =
        tooltypeToSourcetable[toolTypeController.text];

    String? getText(TextEditingController controller) {
      return controller.text.isEmpty ? null : controller.text;
    }

    return Tool(
      id: toolId,
      mfr: getText(mfrController),
      tooltype: toolTypeController.text,
      steel: booleanValues['steel']!,
      stainless: booleanValues['stainless']!,
      castiron: booleanValues['castiron']!,
      aluminum: booleanValues['aluminum']!,
      universal: booleanValues['universal']!,
      catnum: getText(catNumController),
      invnum: invNumController.text,
      unit: unitValue,
      grinded: getText(grindedController),
      holdertype: getText(holdertypeController),
      tipdiamm: roundDouble(tipdiaInMm, 2),
      tipdiainch: roundDouble(tipdiaInInch, 4),
      shankdia: double.tryParse(shankdiaController.text),
      pitch: getText(pitchController),
      neckdia: double.tryParse(neckdiaController.text),
      tslotdp: double.tryParse(tslotdpController.text),
      toollen: double.tryParse(toollenController.text),
      splen: double.tryParse(splenController.text),
      worklen: double.tryParse(worklenController.text),
      bladecnt: int.tryParse(bladecntController.text),
      tiptype: getText(tiptypeController),
      tipsize: getText(tipsizeController),
      material: getText(materialController),
      coating: getText(coatingController),
      inserttype: getText(inserttypeController),
      cabinet: getText(cabinetController),
      qty: int.tryParse(qtyController.text),
      issued: int.tryParse(issuedController.text),
      avail: int.tryParse(availController.text),
      minqty: int.tryParse(minqtyController.text),
      ftscab: getText(ftscabController),
      strcab: getText(strcabController),
      pfrcab: getText(pfrcabController),
      mitsucab: getText(mitsucabController),
      extcab: int.tryParse(extcabController.text),
      sourcetable: selectedSourcetable,
      subtype: getText(subtypeController),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toast = ToastUtil(context, MyApp.navigatorKey);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ExpansionTile(
              title: Text(
                '${context.localize('toolformgeneralinfo')}',
              ),
              children: getGeneralInfoFields(),
            ),
            ExpansionTile(
              title: Text(
                '${context.localize('toolformtooldata')}',
              ),
              children: getToolDataFields(),
            ),
            ExpansionTile(
              title: Text(
                '${context.localize('toolformlocationquantity')}',
              ),
              children: getLocationAndQuantityFields(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  Tool newTool = _createToolFromFormData();

                  if (widget.initialTool == null) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => InsertToolDialog(
                        newTool: newTool,
                        databaseHelper: databaseHelper,
                      ),
                    );
                  } else {
                    databaseHelper.editTool(newTool);
                    toast.showToast(
                        '${context.localize('toasteditedsuccessfully')}',
                        bgColor: AppTheme.toastColor(context));
                    Provider.of<ToolExchangeNotifier>(context, listen: false)
                        .toolUpdated();
                  }
                },
                child: Text(
                  widget.initialTool == null
                      ? '${context.localize('toolforminserttool')}'
                      : '${context.localize('toolformconfirmediting')}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolFormScreen extends StatelessWidget {
  final Tool? tool;
  final PostgreSQLConnection connection;

  ToolFormScreen({this.tool, required this.connection});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onBackPressed(context),
      child: Scaffold(
        appBar: AppBar(
            title: Text(tool == null
                ? '${context.localize('toolforminserttool')}'
                : '${context.localize('toolformedittool')}')),
        body: ToolForm(
          initialTool: tool,
          connection: connection,
        ),
      ),
    );
  }

  Future<bool> _onBackPressed(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${context.localize('toolformconfirmexit')}'),
            content: Text('${context.localize('toolformleaveprompt')}'),
            actions: <Widget>[
              ElevatedButton(
                child: Text('${context.localize('buttonno')}'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              ElevatedButton(
                child: Text('${context.localize('buttonyes')}'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
        ) ??
        false;
  }
}
