import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:inventool/widgets/search_widget.dart';
import 'package:inventool/models/tool.dart';
import 'package:inventool/database.dart';
import 'package:inventool/locale/locale.dart';

class SearchScreen extends StatefulWidget {
  final PostgreSQLConnection connection;

  const SearchScreen({required this.connection});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${context.localize('searchscreentitle')}')),
      body: ToolSearchWidget(
        connection: widget.connection,
        actionTypes: const [
          ToolAction.Issue,
          ToolAction.Dispose,
          ToolAction.Edit
        ],
      ),
    );
  }
}

class SearchProvider with ChangeNotifier {
  List<Tool>? _searchResults;
  List<Map<String, String>> _selectedFilters = [];
  double _rangePercentage = 0.03;

  List<Tool>? get searchResults => _searchResults;
  List<Map<String, String>> get selectedFilters => _selectedFilters;

  double get rangePercentage => _rangePercentage;
  set rangePercentage(double value) {
    _rangePercentage = value;
    notifyListeners();
  }

  Future<void> loadConfig(DatabaseHelper databaseHelper) async {
    Map<String, String> config = await databaseHelper.loadConfig();
    rangePercentage = double.tryParse(config['rangePercentage']!) ?? 0.03;
    notifyListeners();
  }

  void updateConfig(
      DatabaseHelper databaseHelper, String key, String value) async {
    await databaseHelper.updateConfig(key, value);
    if (key == 'rangePercentage') {
      _rangePercentage = double.tryParse(value) ?? _rangePercentage;
    }
    notifyListeners();
  }

  void updateSearchResults(List<Tool> results) {
    _searchResults = results;
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = null;
    notifyListeners();
  }

  void updateSelectedFilters(List<Map<String, String>> filters) {
    _selectedFilters = filters;
    notifyListeners();
  }

  void clearSelectedFilters() {
    _selectedFilters.clear();
    notifyListeners();
  }
}
