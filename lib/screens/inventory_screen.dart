import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:inventool/database.dart';
import 'package:inventool/widgets/navigation_card.dart';
import 'package:inventool/screens/cabinet_screen.dart';
import 'package:inventool/widgets/drawer_section_dialog.dart';
import 'package:inventool/locale/locale.dart';

class InventoryScreen extends StatefulWidget {
  final PostgreSQLConnection connection;

  InventoryScreen({required this.connection});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late DatabaseHelper databaseHelper;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> cabinetMap = {
      "${context.localize('cabinet')} 1": "1",
      "${context.localize('cabinet')} 2": "2",
      "${context.localize('cabinet')} 3": "3",
      "${context.localize('cabinet')} 4": "4",
      "${context.localize('cabinet')} 5": "5",
      "${context.localize('cabinet')} 6": "6",
      "${context.localize('workshop')}": "RADIONA",
      "${context.localize('workshopshelves')}": "RADIONA STALAŽA",
      "${context.localize('shelves')}": "STALAŽA",
      "${context.localize('shelves')} 2": "STALAŽA 2",
      "FTS": "ftscab",
      "Strojotehnika": "strcab",
      "Pfeifer": "pfrcab",
      "Mitsubishi": "mitsucab",
    };

    var firstRowTitles = cabinetMap.keys.toList().sublist(0, 5);
    var secondRowTitles = cabinetMap.keys.toList().sublist(5, 10);
    var thirdRowTitles = cabinetMap.keys.toList().sublist(10);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.localize('inventoryscreentitle')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildRow(firstRowTitles, cabinetMap),
            buildRow(secondRowTitles, cabinetMap),
            SizedBox(
                height: 60,
                child: Center(
                    child: Text('${context.localize('externalcabinets')}:'))),
            buildRow(thirdRowTitles, cabinetMap)
          ],
        ),
      ),
    );
  }

  Widget buildRow(List<String> titles, Map<String, String> cabinetMap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: titles.map((title) {
        return NavigationCard(
          title: title,
          onTap: () {
            if (['RADIONA', 'RADIONA STALAŽA', 'STALAŽA', 'STALAŽA 2']
                .contains(cabinetMap[title])) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return DrawerSectionDialog(
                    connection: widget.connection,
                    section: cabinetMap[title]!,
                  );
                },
              );
            } else if (['pfrcab', 'mitsucab'].contains(cabinetMap[title])) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CabinetScreen(
                  connection: widget.connection,
                  cabinet: title,
                  cabinetNumber: cabinetMap[title]!,
                ),
              ));
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CabinetScreen(
                  connection: widget.connection,
                  cabinet: title,
                  cabinetNumber: cabinetMap[title]!,
                ),
              ));
            }
          },
        );
      }).toList(),
    );
  }
}
