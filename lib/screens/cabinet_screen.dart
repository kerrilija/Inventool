import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:tool_crib/database.dart';
import 'package:tool_crib/widgets/inventory_navigation_card.dart';
import 'cabinet_drawer_screen.dart';
import 'package:tool_crib/widgets/drawer_section_dialog.dart';
import 'package:tool_crib/locale/locale.dart';

class CabinetScreen extends StatefulWidget {
  final PostgreSQLConnection connection;
  final String cabinet;
  final String cabinetNumber;

  CabinetScreen({
    required this.connection,
    required this.cabinet,
    required this.cabinetNumber,
  });

  @override
  _CabinetScreenState createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  late DatabaseHelper databaseHelper;
  List<String> drawerTitles = [];

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    loadDrawers(widget.cabinetNumber);
  }

  void loadDrawers(String cabinetNumber) async {
    List<String> extcabs = ['mitsucab', 'pfrcab', 'ftscab', 'strcab'];
    if (!extcabs.contains(cabinetNumber)) {
      final drawers = await databaseHelper.fetchDrawers(cabinetNumber);
      drawers.sort((a, b) => a.compareTo(b));
      setState(() {
        drawerTitles = drawers;
      });
    } else {
      switch (cabinetNumber) {
        case "ftscab":
          final drawers =
              await databaseHelper.fetchExternalDrawers(cabinetNumber);
          var uniqueDrawerNumbers = drawers
              .map((drawer) => drawer.split('_').firstWhere(
                  (element) => element.isNotEmpty,
                  orElse: () => ""))
              .where((element) => element.isNotEmpty)
              .toSet()
              .toList();
          uniqueDrawerNumbers
              .sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          setState(() {
            drawerTitles = uniqueDrawerNumbers;
          });
          break;

        case "strcab":
          final drawers =
              await databaseHelper.fetchExternalDrawers(cabinetNumber);
          var drawerSections = drawers
              .map((drawer) => drawer.contains('_') ? drawer.split('_')[0] : "")
              .where((element) =>
                  element.isNotEmpty && int.tryParse(element) != null)
              .toSet()
              .toList();
          drawerSections.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          setState(() {
            drawerTitles = drawerSections;
          });
          break;

        case "mitsucab":
        case "pfrcab":
          final drawers =
              await databaseHelper.fetchExternalDrawers(cabinetNumber);
          drawers.sort((a, b) => a.compareTo(b));
          setState(() {
            drawerTitles = drawers;
          });
          break;

        default:
          final drawers = await databaseHelper.fetchDrawers(cabinetNumber);
          drawers.sort((a, b) => a.compareTo(b));
          setState(() {
            drawerTitles = drawers;
          });
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${context.localize('cabinet')} ${widget.cabinet}'),
      ),
      body: drawerTitles.isEmpty
          ? Center(child: CircularProgressIndicator())
          : buildDrawerGrid(),
    );
  }

  Widget buildDrawerGrid() {
    List<Widget> rows = [];
    for (int i = 0; i < drawerTitles.length; i += 5) {
      int end = (i + 5 < drawerTitles.length) ? i + 5 : drawerTitles.length;
      List<Widget> rowCards = [];
      for (var j = i; j < end; j++) {
        String drawerId = drawerTitles[j];
        String cardTitle;
        switch (widget.cabinetNumber) {
          case 'ftscab':
            cardTitle = '${context.localize('drawer')} $drawerId';
            break;
          case 'strcab':
            cardTitle = drawerId.contains('_')
                ? '${context.localize('drawer')} ${drawerId.split('_')[0]}'
                : '${context.localize('drawer')} $drawerId';
            break;
          case 'mitsucab':
          case 'pfrcab':
            cardTitle = '${context.localize('drawer')} $drawerId';
            break;
          default:
            cardTitle = drawerId.contains('_')
                ? '${context.localize('drawer')} ${drawerId.split('_')[1]}'
                : '${context.localize('drawer')} $drawerId';
            break;
        }
        rowCards.add(Flexible(
          child: InventoryNavigationCard(
            title: cardTitle,
            onTap: () {
              if (widget.cabinetNumber == 'pfrcab' ||
                  widget.cabinetNumber == 'mitsucab') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return DrawerSectionDialog(
                      connection: widget.connection,
                      section: drawerId,
                      cabinet: widget.cabinetNumber,
                    );
                  },
                );
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CabinetDrawerScreen(
                    connection: widget.connection,
                    drawer: drawerId,
                    cabinet: widget.cabinetNumber,
                  ),
                ));
              }
            },
          ),
        ));
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: rowCards,
      ));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows,
    );
  }
}
