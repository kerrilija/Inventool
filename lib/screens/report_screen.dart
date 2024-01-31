import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:tool_crib/database.dart';
import 'package:tool_crib/models/sql_history.dart';
import 'package:tool_crib/models/tool.dart';
import 'package:intl/intl.dart';
import 'package:tool_crib/utils/app_theme.dart';
import 'package:tool_crib/locale/locale.dart';

class QueryParserUtil {
  final DatabaseHelper databaseHelper;

  QueryParserUtil({required this.databaseHelper});

  Future<String> fetchToolDetails(
      String query, String action, String formattedTimestamp) async {
    final match = RegExp(r'WHERE id = (\d+)').firstMatch(query);
    if (match != null) {
      String toolId = match.group(1)!;
      List<Map<String, String>> selectedFilters = [
        {'column': 'id', 'value': toolId}
      ];
      List<Tool> tools = await databaseHelper.performSearch(selectedFilters,
          shouldLogQuery: false);
      if (tools.isNotEmpty) {
        return '$action: ${tools.first.invnum} ${tools.first.mfr} ${tools.first.tooltype} Ø ${tools.first.parseTipdia()} $formattedTimestamp';
      }
    }
    return '$action with unspecified details.';
  }
}

class ReportScreen extends StatefulWidget {
  final PostgreSQLConnection connection;

  const ReportScreen({required this.connection});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DatabaseHelper databaseHelper;
  late QueryParserUtil queryParserUtil;
  List<SqlHistory> allSqlHistory = [];
  List<SqlHistory> displayedSqlHistory = [];
  List<String> availableFilters = [
    'Edit',
    'Insert',
    'Dispose',
    'Issue',
    'Return',
    'Updated Availability'
  ];
  List<String> selectedFilters = [];
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    queryParserUtil = QueryParserUtil(databaseHelper: databaseHelper);
    preloadHistory();
  }

  Future<void> preloadHistory({bool allTime = false}) async {
    String? formattedDate = allTime || selectedDate == null
        ? null
        : DateFormat('yyyy-MM-dd').format(selectedDate!);
    final history = await databaseHelper.fetchSqlHistory(date: formattedDate);
    setState(() {
      allSqlHistory = history;
      applyFilters();
    });
  }

  void _onAllTimeHistoryPressed() {
    setState(() {
      selectedDate = null;
      preloadHistory(allTime: true);
    });
  }

  void applyFilters() {
    setState(() {
      displayedSqlHistory = allSqlHistory
          .where((item) =>
              item.queryType != "Search" &&
              (selectedFilters.isEmpty ||
                  selectedFilters.contains(item.queryType)))
          .toList();
    });
  }

  void _onFilterSelected(bool selected, String filterName) {
    if (selected) {
      selectedFilters.add(filterName);
    } else {
      selectedFilters.remove(filterName);
    }
    applyFilters();
  }

  String parseAndFormatTimestamp(DateTime timestamp) {
    return DateFormat('EEEE dd MMM, HH:mm').format(timestamp);
  }

  Future<String> parseQuery(SqlHistory sqlHistoryItem) async {
    switch (sqlHistoryItem.queryType) {
      case 'Edit':
        return _parseEditQuery(sqlHistoryItem);
      case 'Insert':
        return _parseInsertQuery(sqlHistoryItem);
      case 'Dispose':
        return _parseDisposeQuery(sqlHistoryItem);
      case 'Issue':
        return _parseIssueQuery(sqlHistoryItem);
      case 'Return':
        return _parseReturnQuery(sqlHistoryItem);
      case 'Updated Availability':
        return _parseAvailability(sqlHistoryItem);
      default:
        return 'Unhandled query type: ${sqlHistoryItem.queryType}';
    }
  }

  Future<String> _parseEditQuery(SqlHistory sqlHistoryItem) async {
    String formattedTimestamp =
        parseAndFormatTimestamp(sqlHistoryItem.timestamp);
    return queryParserUtil.fetchToolDetails(sqlHistoryItem.query,
        context.localize('reportscreenedited'), formattedTimestamp);
  }

  Future<String> _parseAvailability(SqlHistory sqlHistoryItem) async {
    String formattedTimestamp =
        parseAndFormatTimestamp(sqlHistoryItem.timestamp);
    return queryParserUtil.fetchToolDetails(sqlHistoryItem.query,
        context.localize('reportscreenupdated'), formattedTimestamp);
  }

  Future<String> _parseInsertQuery(SqlHistory sqlHistoryItem) async {
    String formattedTimestamp =
        parseAndFormatTimestamp(sqlHistoryItem.timestamp);
    String details = extractInsertDetails(sqlHistoryItem.query);
    return '${context.localize('reportscreeninserted')}: $details $formattedTimestamp';
  }

  String extractInsertDetails(String query) {
    try {
      var valuesPart = query.split('VALUES')[1];
      valuesPart = valuesPart.replaceAll(RegExp(r'[()]'), '').trim();
      var values = valuesPart.split(',');
      String invnum = values[7].trim();
      String mfr = values[10].trim() != ''
          ? values[10].trim()
          : context.localize('unknownmfr');
      String tooltype = values[0].trim();
      num? tipdia;
      if (values[8].trim() == 'mm') {
        tipdia = num.tryParse(values[12].trim());
        if (tipdia != null) {
          tipdia = double.parse(tipdia.toStringAsFixed(2));
          if (tipdia % 1 == 0) {
            tipdia = tipdia.toInt();
          }
        }
      } else {
        tipdia = num.tryParse(values[13].trim());
        if (tipdia != null) {
          tipdia = double.parse(tipdia.toStringAsFixed(4));
        }
      }
      return '$invnum $mfr $tooltype Ø $tipdia';
    } catch (e) {
      print('Error parsing insert query: $e');
      return 'Unspecified details';
    }
  }

  Future<String> _parseDisposeQuery(SqlHistory sqlHistoryItem) async {
    String formattedTimestamp =
        parseAndFormatTimestamp(sqlHistoryItem.timestamp);
    return queryParserUtil.fetchToolDetails(sqlHistoryItem.query,
        context.localize('reportscreendisposed'), formattedTimestamp);
  }

  Future<String> _parseReturnQuery(SqlHistory sqlHistoryItem) async {
    String formattedTimestamp =
        parseAndFormatTimestamp(sqlHistoryItem.timestamp);
    return queryParserUtil.fetchToolDetails(
        sqlHistoryItem.query, context.localize('returned'), formattedTimestamp);
  }

  Future<String> _parseIssueQuery(SqlHistory sqlHistoryItem) async {
    String formattedTimestamp =
        parseAndFormatTimestamp(sqlHistoryItem.timestamp);
    return queryParserUtil.fetchToolDetails(sqlHistoryItem.query,
        context.localize('reportscreenissued'), formattedTimestamp);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        preloadHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color appBarColor =
        Theme.of(context).appBarTheme.backgroundColor ?? Colors.blueGrey;
    List<Color> cardInnerColors = theme.brightness == Brightness.light
        ? AppTheme.machineCardInnerColorsLight
        : AppTheme.machineCardInnerColorsDark;

    return Scaffold(
      appBar: AppBar(title: Text(context.localize('reportscreentitle'))),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(context.localize('selectdate')),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onAllTimeHistoryPressed,
                child: Text(context.localize('alltimehistory')),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: availableFilters.map((filterName) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.localize('report$filterName')),
                    Switch(
                      value: selectedFilters.contains(filterName),
                      onChanged: (bool newValue) {
                        _onFilterSelected(newValue, filterName);
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 4),
          Visibility(
            visible: displayedSqlHistory.isEmpty,
            child: Card(
              color: appBarColor,
              child: ListTile(
                title: Text(context.localize('nohistory')),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: displayedSqlHistory.length,
              itemBuilder: (context, index) {
                return FutureBuilder<String>(
                  future: parseQuery(displayedSqlHistory[index]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Card(
                        color: cardInnerColors[index % cardInnerColors.length],
                        child: ListTile(
                          title: Text(snapshot.data ??
                              context.localize('unknownquery')),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
