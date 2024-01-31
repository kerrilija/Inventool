import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:inventool/database.dart';
import 'package:inventool/widgets/inventory_navigation_card.dart';
import 'package:inventool/widgets/drawer_section_dialog.dart';
import 'dart:math';
import 'package:inventool/locale/locale.dart';

class CabinetDrawerScreen extends StatefulWidget {
  final PostgreSQLConnection connection;
  final String drawer;
  final String cabinet;

  CabinetDrawerScreen(
      {required this.connection, required this.drawer, required this.cabinet});

  @override
  _CabinetDrawerScreenState createState() => _CabinetDrawerScreenState();
}

class _CabinetDrawerScreenState extends State<CabinetDrawerScreen> {
  late DatabaseHelper databaseHelper;
  List<String> sectionTitles = [];

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    loadSections();
  }

  void loadSections() async {
    if (widget.cabinet != 'ftscab' && widget.cabinet != 'strcab') {
      final sections = await databaseHelper.fetchDrawerSections(widget.drawer);

      sections.sort((a, b) {
        List<String> partsA = a.split('_').map((part) => part.trim()).toList();
        List<String> partsB = b.split('_').map((part) => part.trim()).toList();

        for (int i = 0; i < min(partsA.length, partsB.length); i++) {
          int numA = int.tryParse(partsA[i]) ?? -1;
          int numB = int.tryParse(partsB[i]) ?? -1;

          if (numA != -1 && numB != -1) {
            if (numA != numB) return numA.compareTo(numB);
          } else {
            int strCompare = partsA[i].compareTo(partsB[i]);
            if (strCompare != 0) return strCompare;
          }
        }

        return partsA.length.compareTo(partsB.length);
      });

      setState(() {
        sectionTitles = sections;
      });
    } else {
      final sections = await databaseHelper.fetchExternalDrawerSections(
          widget.drawer, widget.cabinet);

      sections.sort((a, b) {
        List<String> partsA = a.split('_').map((part) => part.trim()).toList();
        List<String> partsB = b.split('_').map((part) => part.trim()).toList();

        for (int i = 0; i < min(partsA.length, partsB.length); i++) {
          int numA = int.tryParse(partsA[i]) ?? -1;
          int numB = int.tryParse(partsB[i]) ?? -1;

          if (numA != -1 && numB != -1) {
            if (numA != numB) return numA.compareTo(numB);
          } else {
            int strCompare = partsA[i].compareTo(partsB[i]);
            if (strCompare != 0) return strCompare;
          }
        }

        return partsA.length.compareTo(partsB.length);
      });

      setState(() {
        sectionTitles = sections;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${context.localize('drawer')} ${widget.drawer}'),
      ),
      body: sectionTitles.isEmpty
          ? Center(child: CircularProgressIndicator())
          : buildSectionGrid(),
    );
  }

  Widget buildSectionGrid() {
    List<Widget> rows = [];
    for (int i = 0; i < sectionTitles.length; i += 5) {
      int end = (i + 5 < sectionTitles.length) ? i + 5 : sectionTitles.length;
      List<Widget> rowCards = [];

      for (var j = i; j < end; j++) {
        rowCards.add(
          Flexible(
            child: InventoryNavigationCard(
              title: sectionTitles[j],
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return DrawerSectionDialog(
                      connection: widget.connection,
                      section: sectionTitles[j],
                      cabinet: widget.cabinet,
                    );
                  },
                );
              },
            ),
          ),
        );
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
