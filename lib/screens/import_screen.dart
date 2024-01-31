import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:postgres/postgres.dart';
import 'package:inventool/utils/app_theme.dart';
import 'package:inventool/widgets/toast_util.dart';
import 'package:inventool/main.dart';
import 'package:inventool/locale/locale.dart';
import 'package:path_provider/path_provider.dart';

enum TableType { Tool, ThreadMaking, Fixture }

class ImportScreen extends StatefulWidget {
  final PostgreSQLConnection connection;

  const ImportScreen({required this.connection});

  @override
  _ImportScreenState createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late final ToastUtil toast;

  @override
  void initState() {
    super.initState();
    toast = ToastUtil(context, MyApp.navigatorKey);
  }

  Future<void> pickAndImportFile(TableType tableType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      switch (tableType) {
        case TableType.Tool:
          await _importToDatabase(file, toast, 'tool');
          break;
        case TableType.ThreadMaking:
          await _importToDatabase(file, toast, 'threadmaking');
          break;
        case TableType.Fixture:
          await _importToDatabase(file, toast, 'fixture');
          break;
      }

      toast.showToast(context.localize('toastimportedsuccessfully'),
          bgColor: AppTheme.toastColor(context), duration: 2);
    } else {
      print('File pick was canceled.');
    }
  }

  Future<void> _importToDatabase(
      File csvFile, ToastUtil toast, String tableName) async {
    final content = await csvFile.readAsString();
    final List<String> lines = LineSplitter.split(content).toList();

    List<List<dynamic>> csvData = lines.map((line) => line.split(';')).toList();

    for (var i = 1; i < csvData.length; i++) {
      final List<dynamic> row = csvData[i];
      final List<String> columns = [
        'tooltype',
        'steel',
        'stainless',
        'castiron',
        'aluminum',
        'universal',
        'catnum',
        'invnum',
        'unit',
        'grinded',
        'mfr',
        'holdertype',
        'tipdiamm',
        'tipdiainch',
        'shankdia',
        'pitch',
        'neckdia',
        'tslotdp',
        'toollen',
        'splen',
        'worklen',
        'bladecnt',
        'tiptype',
        'tipsize',
        'material',
        'coating',
        'inserttype',
        'cabinet',
        'qty',
        'issued',
        'avail',
        'minqty',
        'ftscab',
        'strcab',
        'pfrcab',
        'mitsucab',
        'extcab',
        'sourcetable',
        'subtype'
      ];

      final List<String> values = row.map(parseValue).toList();

      final String columnsString = columns.join(', ');
      final String valuesString = values.join(', ');

      final queryString = '''
      INSERT INTO $tableName ($columnsString)
      VALUES ($valuesString)
    ''';

      try {
        await widget.connection.query(queryString);
        print('Row $i inserted successfully.');
      } catch (e) {
        print('Error inserting row $i: $e');
      }
    }
  }

  String parseValue(dynamic value) {
    if (value == 'N/A') {
      return 'NULL';
    } else if (value is bool) {
      return value.toString();
    } else if (value is String) {
      return "'$value'";
    } else if (value is double) {
      return value.toString();
    } else if (value is int) {
      return value.toString();
    } else {
      return 'NULL';
    }
  }

  Future<List<List<dynamic>>> exportDatabase(String tableName) async {
    try {
      final result =
          await widget.connection.query("SELECT * FROM $tableName ORDER BY id");
      return result.map((row) => row.toList()).toList();
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  String convertToCsv(List<List<dynamic>> data) {
    List<String> rows = [];
    for (var row in data) {
      String csvRow = row.sublist(1).map((value) {
        if (value == null) {
          return 'N/A';
        } else if (value is bool) {
          return value ? '1' : '0';
        } else {
          return value.toString();
        }
      }).join(';');
      rows.add(csvRow);
    }
    return rows.join('\n');
  }

  Future<File> saveCsvFile(String data, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName.csv';
    final file = File(path);

    print('CSV file saved at: $path');

    return file.writeAsString(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.localize('importscreentitle')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.localize('importscreencaptionimport'),
              style: TextStyle(fontSize: 24.0),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => pickAndImportFile(TableType.Tool),
                  child: Text('Tool CSV'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => pickAndImportFile(TableType.ThreadMaking),
                  child: Text('Thread Making CSV'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => pickAndImportFile(TableType.Fixture),
                  child: Text('Fixture CSV'),
                )
              ],
            ),
            const SizedBox(
              height: 40,
            ),
            Text(
              context.localize('importscreencaptionexport'),
              style: TextStyle(fontSize: 24.0),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    List<List<dynamic>> data = await exportDatabase('tool');
                    String csvData = convertToCsv(data);
                    await saveCsvFile(csvData, 'tool_backup');
                  },
                  child: Text('Export Tool'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () async {
                    List<List<dynamic>> data =
                        await exportDatabase('threadmaking');
                    String csvData = convertToCsv(data);
                    await saveCsvFile(csvData, 'threadmaking_backup');
                  },
                  child: Text('Export Threadmaking'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () async {
                    List<List<dynamic>> data = await exportDatabase('fixture');
                    String csvData = convertToCsv(data);
                    await saveCsvFile(csvData, 'fixture_backup');
                  },
                  child: Text('Export Fixture'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
