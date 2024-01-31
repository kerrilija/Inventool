import 'package:postgres/postgres.dart';
import 'package:inventool/models/sql_history.dart';
import 'models/tool.dart';

class DatabaseHelper {
  final PostgreSQLConnection connection;

  DatabaseHelper({required this.connection});

  Future<void> logQuery(String query, String queryType,
      [Map<String, dynamic>? substitutionValues]) async {
    substitutionValues?.forEach((key, value) {
      query = query.replaceAll('@$key', value.toString());
    });

    try {
      await connection.query(
        'INSERT INTO sql_history (query, query_type) VALUES (@query, @queryType)',
        substitutionValues: {
          'query': query,
          'queryType': queryType,
        },
      );
    } catch (e) {
      print('Error logging query: $e');
    }
  }

  Future<List<SqlHistory>> fetchSqlHistory({String? date}) async {
    List<SqlHistory> historyItems = [];

    String query;
    if (date != null) {
      query =
          "SELECT * FROM sql_history WHERE DATE(timestamp) = '$date' ORDER by id DESC";
    } else {
      query = 'SELECT * FROM sql_history ORDER by id DESC';
    }

    final results = await connection.query(query);
    historyItems = parseSqlHistory(results);
    return historyItems;
  }

  List<SqlHistory> parseSqlHistory(PostgreSQLResult results) {
    List<SqlHistory> historyItems = [];
    List<String> columnNames =
        results.columnDescriptions.map((desc) => desc.columnName).toList();

    for (final row in results) {
      final Map<String, dynamic> map = {};
      for (var i = 0; i < columnNames.length; i++) {
        final columnName = columnNames[i];
        final cellValue = row[i];
        map[columnName] = cellValue;
      }
      historyItems.add(SqlHistory(
          id: map['id'] as int,
          query: map['query'] as String,
          queryType: map['query_type'] as String,
          timestamp: map['timestamp'] as DateTime));
    }
    return historyItems;
  }

  Future<List<String>> fetchDistinctValues(String columnName,
      [String? tooltype]) async {
    try {
      String query;
      if (tooltype != null && columnName == 'subtype') {
        query = '''
        SELECT DISTINCT $columnName FROM tool WHERE tooltype = @tooltype
        UNION
        SELECT DISTINCT $columnName FROM fixture WHERE tooltype = @tooltype
        UNION
        SELECT DISTINCT $columnName FROM threadmaking WHERE tooltype = @tooltype ORDER BY $columnName ASC
      ''';
      } else {
        query = '''
        SELECT DISTINCT $columnName FROM tool
        UNION
        SELECT DISTINCT $columnName FROM fixture
        UNION
        SELECT DISTINCT $columnName FROM threadmaking ORDER BY $columnName ASC
      ''';
      }

      final results = await connection.query(
        query,
        substitutionValues: tooltype != null ? {'tooltype': tooltype} : null,
      );

      final suggestions =
          results.map((row) => row[0]?.toString() ?? '').toList();
      return suggestions;
    } catch (e) {
      print('Error fetching $columnName suggestions: $e');
      return [];
    }
  }

  List<Tool> processResults(PostgreSQLResult results) {
    List<Tool> resultList = [];

    List<String> columnNames =
        results.columnDescriptions.map((desc) => desc.columnName).toList();

    for (final row in results) {
      final Map<String, dynamic> map = {};

      for (var i = 0; i < columnNames.length; i++) {
        final columnName = columnNames[i];
        final cellValue = row[i];
        map[columnName] = cellValue;
      }

      resultList.add(Tool(
          id: map['id'] as int,
          tooltype: map['tooltype'] as String,
          steel: map['steel'] as bool?,
          stainless: map['stainless'] as bool?,
          castiron: map['castiron'] as bool?,
          aluminum: map['aluminum'] as bool?,
          universal: map['universal'] as bool?,
          catnum: map['catnum'] as String? ?? '',
          invnum: map['invnum'] as String,
          unit: map['unit'] as String?,
          grinded: map['grinded'] as String?,
          mfr: map['mfr'] as String?,
          holdertype: map['holdertype'] as String?,
          tipdiamm: map['tipdiamm'] as String?,
          tipdiainch: map['tipdiainch'] as String?,
          shankdia: map['shankdia'] != null
              ? num.tryParse(map['shankdia'].toString())
              : null,
          pitch: map['pitch'] as String?,
          neckdia: map['neckdia'] != null
              ? num.tryParse(map['neckdia'].toString())
              : null,
          tslotdp: map['tslotdp'] != null
              ? num.tryParse(map['tslotdp'].toString())
              : null,
          toollen: map['toollen'] != null
              ? num.tryParse(map['toollen'].toString())
              : null,
          splen: map['splen'] != null
              ? num.tryParse(map['splen'].toString())
              : null,
          worklen: map['worklen'] != null
              ? num.tryParse(map['worklen'].toString())
              : null,
          bladecnt: map['bladecnt'] as int?,
          tiptype: map['tiptype'] as String?,
          tipsize: map['tipsize'] as String?,
          material: map['material'] as String?,
          coating: map['coating'] as String?,
          inserttype: map['inserttype'] as String?,
          cabinet: map['cabinet'] as String?,
          qty: map['qty'] as int?,
          issued: map['issued'] as int?,
          avail: map['avail'] as int?,
          minqty: map['minqty'] as int?,
          ftscab: map['ftscab'] as String?,
          strcab: map['strcab'] as String?,
          pfrcab: map['pfrcab'] as String?,
          mitsucab: map['mitsucab'] as String?,
          extcab: map['extcab'] as int?,
          sourcetable: map['sourcetable'] as String?,
          subtype: map['subtype'] as String?));
    }
    return resultList;
  }

  Future<Map<int, Tool>> fetchIssued() async {
    Map<int, Tool> issuedTools = {};

    try {
      final exchangeResults = await connection.query(
          'SELECT exchange_id, toissue, sourcetable FROM exchange WHERE toissue IS NOT NULL;');

      for (var row in exchangeResults) {
        int exchangeId = row[0] as int;
        int toolId = row[1] as int;
        String sourceTable = row[2] as String;

        final individualQuery =
            'SELECT *, \'$sourceTable\' AS sourcetable FROM $sourceTable WHERE id = $toolId';
        final toolResults = await connection.query(individualQuery);

        if (toolResults.isNotEmpty) {
          issuedTools[exchangeId] = processResults(toolResults).first;
        }
      }
    } catch (e) {
      print('Error fetching issued tools: $e');
    }

    return issuedTools;
  }

  Future<Map<int, Tool>> fetchReturned() async {
    Map<int, Tool> returnedTools = {};

    try {
      final exchangeResults = await connection.query(
          'SELECT exchange_id, toreturn, sourcetable FROM exchange WHERE toreturn IS NOT NULL;');

      if (exchangeResults.isNotEmpty) {
        for (var row in exchangeResults) {
          int exchangeId = row[0] as int;
          int id = row[1] as int;
          String sourceTable = row[2] as String;

          final individualQuery =
              'SELECT *, \'$sourceTable\' AS sourcetable FROM $sourceTable WHERE id = $id';
          final toolResults = await connection.query(individualQuery);

          if (toolResults.isNotEmpty) {
            returnedTools[exchangeId] = processResults(toolResults).first;
          }
        }
      }

      return returnedTools;
    } catch (e) {
      print('Error fetching returned tools: $e');
      return {};
    }
  }

  Future<Map<int, Tool>> fetchDisposed() async {
    Map<int, Tool> disposedTools = {};

    try {
      final exchangeResults = await connection.query(
          'SELECT exchange_id, todispose, sourcetable FROM exchange WHERE todispose IS NOT NULL;');

      if (exchangeResults.isNotEmpty) {
        for (var row in exchangeResults) {
          int exchangeId = row[0] as int;
          int id = row[1] as int;
          String sourceTable = row[2] as String;

          final individualQuery =
              'SELECT *, \'$sourceTable\' AS sourcetable FROM $sourceTable WHERE id = $id';
          final toolResults = await connection.query(individualQuery);

          if (toolResults.isNotEmpty) {
            disposedTools[exchangeId] = processResults(toolResults).first;
          }
        }
      }

      return disposedTools;
    } catch (e) {
      print('Error fetching disposed tools: $e');
      return {};
    }
  }

  Future<Map<int, Tool>> fetchMachine(int? machineNumber) async {
    Map<int, Tool> machineTools = {};

    if (machineNumber == null) {
      return machineTools;
    }

    try {
      final exchangeResults = await connection.query(
          'SELECT exchange_id, issued FROM exchange WHERE machine = @machineNumber AND issued IS NOT NULL;',
          substitutionValues: {'machineNumber': machineNumber});

      for (var row in exchangeResults) {
        int exchangeId = row[0] as int;
        int toolId = row[1] as int;

        final toolResults =
            await connection.query('SELECT * FROM tool WHERE id = $toolId;');
        Tool tool = processResults(toolResults).first;
        machineTools[exchangeId] = tool;
      }

      return machineTools;
    } catch (e) {
      print('Error fetching tools for machine $machineNumber: $e');
      return machineTools;
    }
  }

  Future<List<Tool>> performSearch(List<Map<String, String>> selectedFilters,
      {bool shouldLogQuery = true,
      Map<String, dynamic>? manualRange,
      double? rangePercentage}) async {
    List<Tool> resultList = [];

    double effectiveRangePercentage = rangePercentage ?? 0.03;
    bool isTipDiameterSearch = false;

    Map<String, double> calculateRange(
        double value, String filterUnit, String columnUnit) {
      double lower, upper;
      if (filterUnit == columnUnit) {
        lower = value * (1 - effectiveRangePercentage);
        upper = value * (1 + effectiveRangePercentage);
      } else if (filterUnit == 'mm' && columnUnit == 'tipdiainch') {
        lower = (value * (1 - effectiveRangePercentage)) / 25.4;
        upper = (value * (1 + effectiveRangePercentage)) / 25.4;
      } else if (filterUnit == 'inch' && columnUnit == 'tipdiamm') {
        lower = (value * (1 - effectiveRangePercentage)) * 25.4;
        upper = (value * (1 + effectiveRangePercentage)) * 25.4;
      } else {
        throw Exception('Invalid unit conversion');
      }
      return {'lower': lower, 'upper': upper};
    }

    Map<String, String> columnFetchOperator = {
      'tooltip': '=',
      'worklen': '>=',
      'catnum': 'LIKE',
      'invnum': 'LIKE',
      'pitch': '=',
      'tipsize': '=',
    };

    String createQueryString(String tableName, String conditions) {
      return 'SELECT * FROM $tableName ${conditions.isNotEmpty ? "WHERE $conditions" : ""}';
    }

    String conditions = '';
    if (selectedFilters.isNotEmpty) {
      List<String> queries = [];

      for (final filter in selectedFilters) {
        final columnName = filter['column'];
        final value = filter['value'];
        final operator = columnFetchOperator[columnName] ?? '=';

        if (columnName != null && value != null) {
          if (columnName == 'catnum' || columnName == 'invnum') {
            queries.add("$columnName $operator '$value%'");
          } else if ((columnName == 'tipdiamm' || columnName == 'tipdiainch') &&
              manualRange == null) {
            if (value.contains('-')) {
              var rangeParts = value.split('-');
              if (rangeParts.length == 2) {
                String lowerRange = rangeParts[0];
                String upperRange = rangeParts[1];
                queries
                    .add('($columnName BETWEEN $lowerRange AND $upperRange)');
              }
            } else {
              double val = double.parse(value);
              String filterUnit = columnName == 'tipdiamm' ? 'mm' : 'inch';
              String columnUnit = columnName == 'tipdiamm' ? 'mm' : 'inch';
              var range = calculateRange(val, filterUnit, columnUnit);
              queries.add(
                  '($columnName BETWEEN ${range['lower']} AND ${range['upper']})');
            }
          } else if (manualRange == null) {
            queries.add('$columnName $operator \'$value\'');
          }

          if (columnName == 'tipdiamm' || columnName == 'tipdiainch') {
            isTipDiameterSearch = true;
          }
        }
      }

      if (manualRange != null &&
          (manualRange['lower'] != null && manualRange['upper'] != null)) {
        queries.add(
            '(tipdiamm BETWEEN ${manualRange['lower']} AND ${manualRange['upper']})');
      }

      conditions = queries.join(' AND ');
    }

    Future<List<Tool>> processQuery(String query) async {
      try {
        final results = await connection.query(query);
        if (shouldLogQuery) {
          await logQuery(query, 'Search');
        }
        return processResults(results);
      } catch (e) {
        print('Error executing query: $e');
        return [];
      }
    }

    String toolQuery = createQueryString('tool', conditions);
    resultList.addAll(await processQuery(toolQuery));
    print(toolQuery);

    if (!isTipDiameterSearch) {
      String combinedQuery = '''
    SELECT * FROM fixture ${conditions.isNotEmpty ? "WHERE $conditions" : ""}
    UNION
    SELECT * FROM threadmaking ${conditions.isNotEmpty ? "WHERE $conditions" : ""}
    ''';
      resultList.addAll(await processQuery(combinedQuery));
    }

    return resultList;
  }

  Future<void> processToolIssuance(int id, String sourceTable) async {
    String query =
        'INSERT INTO exchange (toissue, sourcetable) VALUES (@id, @sourceTable)';
    try {
      await connection.query(query,
          substitutionValues: {'id': id, 'sourceTable': sourceTable});
    } catch (e) {
      print('processToolIssuance | Error processing tool issuance: $e');
    }
  }

  Future<void> processToolReturn(int exchangeId, String sourceTable,
      {int? machine}) async {
    try {
      String updateQuery = '''
    UPDATE exchange 
    SET toReturn = issued,
        issued = NULL,
        sourcetable = '$sourceTable'
    WHERE exchange_id = $exchangeId;
    ''';
      await connection.query(updateQuery);

      if (machine != null) {
        String clearIssuedQuery =
            'UPDATE exchange SET issued = NULL WHERE exchange_id = $exchangeId';
        await connection.query(clearIssuedQuery);
      }
    } catch (e) {
      print('processToolReturn | Error processing tool returning: $e');
    }
  }

  Future<void> processToolDisposal(int id, String sourceTable) async {
    String query =
        'INSERT INTO exchange (toDispose, sourcetable) VALUES (@id, @sourceTable)';
    try {
      await connection.query(query,
          substitutionValues: {'id': id, 'sourceTable': sourceTable});
    } catch (e) {
      print('processToolDisposal | Error processing tool disposal: $e');
    }
  }

  Future<void> deleteExchangeId(int exchangeId) async {
    try {
      await connection
          .query('DELETE FROM exchange WHERE exchange_id = $exchangeId');
    } catch (e) {
      print('Error in deleteExchangeId: $e');
    }
  }

  Future<void> returnToolToMachine(int exchangeId) async {
    try {
      await connection.query(
        'UPDATE exchange SET issued = toReturn, toReturn = NULL WHERE exchange_id = @exchangeId',
        substitutionValues: {'exchangeId': exchangeId},
      );
    } catch (e) {
      print(
          'returnToolToMachine | Error processing returning tool to machine: $e');
    }
  }

  void returnTool(Tool tool) async {
    String query = 'UPDATE ${tool.sourcetable} '
        'SET avail = avail + 1, issued = issued - 1 '
        'WHERE id = @id';
    Map<String, dynamic> substitutionValues = {
      'id': tool.id,
    };

    try {
      await connection.query(query, substitutionValues: substitutionValues);
      await logQuery(query, 'Return', substitutionValues);
    } catch (e) {
      print('returnTool | Error processing tool returning: $e');
    }
  }

  void issueTool(Tool tool, bool newTool, int? machine) async {
    String query;
    Map<String, dynamic> substitutionValues = {
      'id': tool.id,
      'machine': machine
    };

    if (newTool == false) {
      query =
          'UPDATE ${tool.sourcetable} SET avail = avail - 1, issued = issued + 1 WHERE id = @id';
      String exchangeQuery =
          'INSERT INTO exchange (issued, machine) VALUES (@id, @machine)';
      try {
        if (machine != null) {
          await connection.query(exchangeQuery,
              substitutionValues: substitutionValues);
        }
        await connection.query(query, substitutionValues: substitutionValues);
        await logQuery(query, 'Issue', substitutionValues);
      } catch (e) {
        print('issueTool | Error logging exchange for tool issuing: $e');
      }
    } else {
      query =
          'UPDATE ${tool.sourcetable} SET extcab = extcab - 1, issued = issued + 1, qty = qty + 1 WHERE id = @id';
      String exchangeQuery =
          'INSERT INTO exchange (issued, machine) VALUES (@id, @machine)';
      try {
        await connection.query(exchangeQuery,
            substitutionValues: substitutionValues);
        await connection.query(query, substitutionValues: substitutionValues);
        await logQuery(query, 'Issue', substitutionValues);
      } catch (e) {
        print('issueTool | Error in issuing new tool: $e');
      }
    }
  }

  Map<String, dynamic> generateSqlComponents(Tool tool) {
    List<String> setComponents = [];
    Map<String, dynamic> substitutionValues = {};

    void addComponent(String columnName, dynamic value) {
      setComponents.add('$columnName = @$columnName');
      substitutionValues[columnName] = value;
    }

    addComponent('tooltype', tool.tooltype);
    addComponent('steel', tool.steel);
    addComponent('stainless', tool.stainless);
    addComponent('castiron', tool.castiron);
    addComponent('aluminum', tool.aluminum);
    addComponent('universal', tool.universal);
    addComponent('catnum', tool.catnum);
    addComponent('invnum', tool.invnum);
    addComponent('unit', tool.unit);
    addComponent('grinded', tool.grinded);
    addComponent('mfr', tool.mfr);
    addComponent('holdertype', tool.holdertype);
    addComponent('tipdiamm', tool.tipdiamm);
    addComponent('tipdiainch', tool.tipdiainch);
    addComponent('shankdia', tool.shankdia);
    addComponent('pitch', tool.pitch);
    addComponent('neckdia', tool.neckdia);
    addComponent('tslotdp', tool.tslotdp);
    addComponent('toollen', tool.toollen);
    addComponent('splen', tool.splen);
    addComponent('worklen', tool.worklen);
    addComponent('bladecnt', tool.bladecnt);
    addComponent('tiptype', tool.tiptype);
    addComponent('tipsize', tool.tipsize);
    addComponent('material', tool.material);
    addComponent('coating', tool.coating);
    addComponent('inserttype', tool.inserttype);
    addComponent('cabinet', tool.cabinet);
    addComponent('qty', tool.qty);
    addComponent('issued', tool.issued);
    addComponent('avail', tool.avail);
    addComponent('minqty', tool.minqty);
    addComponent('ftscab', tool.ftscab);
    addComponent('strcab', tool.strcab);
    addComponent('pfrcab', tool.pfrcab);
    addComponent('mitsucab', tool.mitsucab);
    addComponent('extcab', tool.extcab);
    addComponent('sourcetable', tool.sourcetable);
    addComponent('subtype', tool.subtype);

    return {
      'setComponents': setComponents.join(', '),
      'substitutionValues': substitutionValues,
    };
  }

  void insertTool(Tool tool) async {
    var components = generateSqlComponents(tool);
    String sql =
        'INSERT INTO ${tool.sourcetable} (${components['substitutionValues'].keys.join(', ')}) VALUES (${components['substitutionValues'].keys.map((k) => '@$k').join(', ')})';

    try {
      await connection.query(sql,
          substitutionValues: components['substitutionValues']);
      await logQuery(sql, 'Insert', components['substitutionValues']);
    } catch (e) {
      print('insertTool | Error processing tool insertion: $e');
    }
  }

  void disposeTool(Tool tool) async {
    String query = 'UPDATE ${tool.sourcetable} '
        'SET avail = avail - 1, qty = qty - 1 '
        'WHERE id = @id';
    Map<String, dynamic> substitutionValues = {'id': tool.id};

    try {
      await connection.query(query, substitutionValues: substitutionValues);

      await logQuery(query, 'Dispose', substitutionValues);
    } catch (e) {
      print('disposeTool | Error processing tool disposal: $e');
    }
  }

  void editTool(Tool tool) async {
    var components = generateSqlComponents(tool);
    String sql =
        'UPDATE ${tool.sourcetable} SET ${components['setComponents']} WHERE id = @id';
    components['substitutionValues']['id'] = tool.id;

    try {
      await connection.query(sql,
          substitutionValues: components['substitutionValues']);
      await logQuery(sql, 'Edit', components['substitutionValues']);
    } catch (e) {
      print('Error updating tool: $e');
    }
  }

  Future<List<Tool>> checkMinQty() async {
    List<Tool> lowQtyTools = [];

    Future<List<Tool>> processQuery(String tableName) async {
      try {
        final query = 'SELECT * FROM $tableName WHERE minqty > (qty + extcab)';
        final results = await connection.query(query);
        return processResults(results);
      } catch (e) {
        print(
            'checkMinQty | Error fetching tools below minqty from $tableName: $e');
        return [];
      }
    }

    lowQtyTools.addAll(await processQuery('tool'));
    lowQtyTools.addAll(await processQuery('fixture'));
    lowQtyTools.addAll(await processQuery('threadmaking'));

    return lowQtyTools;
  }

  Future<List<String>> fetchDrawers(String cabinetNumber) async {
    String query = '''
    SELECT DISTINCT SUBSTRING(cabinet FROM 1 FOR POSITION('_' IN cabinet) + 1) AS drawer
    FROM tool
    WHERE cabinet LIKE '$cabinetNumber%'

    UNION

    SELECT DISTINCT SUBSTRING(cabinet FROM 1 FOR POSITION('_' IN cabinet) + 1)
    FROM fixture
    WHERE cabinet LIKE '$cabinetNumber%'

    UNION

    SELECT DISTINCT SUBSTRING(cabinet FROM 1 FOR POSITION('_' IN cabinet) + 1)
    FROM threadmaking
    WHERE cabinet LIKE '$cabinetNumber%';
  ''';

    final results = await connection.query(query);
    List<String> drawers = results.map((row) => row[0] as String).toList();
    return drawers;
  }

  Future<List<String>> fetchDrawerSections(String drawer) async {
    String query = '''
    SELECT DISTINCT cabinet
    FROM tool
    WHERE cabinet LIKE '$drawer%'

    UNION

    SELECT DISTINCT cabinet
    FROM fixture
    WHERE cabinet LIKE '$drawer%'

    UNION

    SELECT DISTINCT cabinet
    FROM threadmaking
    WHERE cabinet LIKE '$drawer%';
  ''';

    final results = await connection.query(query);
    List<String> drawerSections =
        results.map((row) => row[0] as String).toList();
    return drawerSections;
  }

  Future<List<String>> fetchExternalDrawers(String cabinetName) async {
    String column;
    String query;

    switch (cabinetName) {
      case "ftscab":
        column = "ftscab";
        break;
      case "strcab":
        column = "strcab";
        break;
      case "pfrcab":
        column = "pfrcab";
        break;
      case "mitsucab":
        column = "mitsucab";
        break;
      default:
        throw Exception("Invalid cabinet name");
    }

    query = '''
  SELECT DISTINCT $column
  FROM tool
  WHERE $column <> '0'
  ''';

    final results = await connection.query(query);
    List<String> drawers = results.map((row) => row[0] as String).toList();
    return drawers;
  }

  Future<List<String>> fetchExternalDrawerSections(
      String drawer, String cabinet) async {
    String query = '''
    SELECT DISTINCT $cabinet
    FROM tool
    WHERE $cabinet LIKE '$drawer%'

    UNION

    SELECT DISTINCT $cabinet
    FROM fixture
    WHERE $cabinet LIKE '$drawer%'

    UNION

    SELECT DISTINCT $cabinet
    FROM threadmaking
    WHERE $cabinet LIKE '$drawer%';
  ''';

    final results = await connection.query(query);
    List<String> drawerSections =
        results.map((row) => row[0] as String).toList();
    return drawerSections;
  }

  Future<void> updateInventoryQty(
      int toolId, int newAvailability, String sourceTable) async {
    String query =
        'UPDATE $sourceTable SET avail = @newAvailability WHERE id = @toolId';
    try {
      await connection.query(query, substitutionValues: {
        'newAvailability': newAvailability,
        'toolId': toolId
      });
      await logQuery(query, 'Updated Availability',
          {'newAvailability': newAvailability, 'toolId': toolId});
    } catch (e) {
      print('Error updating tool availability: $e');
    }
  }

  Future<Map<String, String>> loadConfig() async {
    Map<String, String> config = {};

    try {
      final results =
          await connection.query('SELECT key, value FROM app_config');

      if (results.isEmpty) {
        await updateConfig('rangePercentage', '0.03');
        config['rangePercentage'] = '0.03';
      } else {
        for (final row in results) {
          config[row[0] as String] = row[1] as String;
        }
      }
    } catch (e) {
      print('loadConfig | Error fetching configuration: $e');
    }

    return config;
  }

  Future<void> updateConfig(String key, String value) async {
    try {
      final result = await connection.query(
          'SELECT 1 FROM app_config WHERE key = @key',
          substitutionValues: {'key': key});

      if (result.isEmpty) {
        await connection.execute(
            'INSERT INTO app_config (key, value) VALUES (@key, @value)',
            substitutionValues: {'key': key, 'value': value});
      } else {
        await connection.execute(
            'UPDATE app_config SET value = @value WHERE key = @key',
            substitutionValues: {'key': key, 'value': value});
      }
    } catch (e) {
      print('updateConfig | Error updating configuration: $e');
    }
  }

  void orderTool(Tool tool) async {}
}
