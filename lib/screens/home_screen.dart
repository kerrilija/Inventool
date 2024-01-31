import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:provider/provider.dart';
import 'package:inventool/screens/exchange_screen.dart';
import 'package:inventool/widgets/navigation_card.dart';
import 'package:inventool/widgets/machine_card.dart';
import 'search_screen.dart';
import 'import_screen.dart';
import 'order_screen.dart';
import 'addremove_screen.dart';
import 'report_screen.dart';
import 'package:inventool/widgets/notification_dialog.dart';
import 'package:inventool/models/tool.dart';
import 'package:inventool/database.dart';
import 'package:inventool/widgets/tool_table_dialog.dart';
import 'package:inventool/widgets/search_widget.dart';
import 'package:inventool/screens/inventory_screen.dart';
import 'package:inventool/utils/app_theme.dart';
import 'package:flag/flag.dart';
import 'package:inventool/providers/locale_provider.dart';
import 'package:inventool/locale/locale.dart';
import 'package:inventool/widgets/footer_widget.dart';

class NotificationItem {
  final String message;
  final VoidCallback? action;

  NotificationItem({required this.message, this.action});
}

class HomeScreen extends StatefulWidget {
  final PostgreSQLConnection connection;

  HomeScreen({required this.connection});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int notificationCount = 0;
  List<NotificationItem> notifications = [];
  late DatabaseHelper databaseHelper;

  void _onToolsChanged() {
    fetchNotifications();
  }

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper(connection: widget.connection);
    fetchNotifications();

    var toolNotifier =
        Provider.of<ToolExchangeNotifier>(context, listen: false);
    toolNotifier.addListener(_onToolsChanged);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.localize('apptitle')),
        actions: <Widget>[buildAppBarIcons()],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 75,
                backgroundColor: Colors.transparent,
                flexibleSpace: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        color: theme.appBarTheme.backgroundColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                      child: buildNavigationRow(context),
                    ),
                  ),
                ),
              ),
              Consumer<ToolExchangeNotifier>(
                builder: (context, notifier, _) {
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: EdgeInsets.only(top: 0),
                        child: buildMachineRow(widget.connection, [1, 2, 3]),
                      ),
                      SizedBox(height: 10),
                      buildMachineRow(widget.connection, [4, 5, 6]),
                      SizedBox(height: 10),
                      buildMachineRow(widget.connection, [7]),
                    ]),
                  );
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FooterWidget(),
          ),
        ],
      ),
    );
  }

  Widget buildNavigationRow(BuildContext context) {
    var navigationItems = [
      NavigationItem('${context.localize('navcardsearch')}',
          SearchScreen(connection: widget.connection)),
      NavigationItem('${context.localize('navcardexchange')}',
          ExchangeScreen(connection: widget.connection)),
      NavigationItem('${context.localize('navcardorders')}', OrderScreen()),
      NavigationItem('${context.localize('navcardaddremove')}',
          AddRemoveScreen(connection: widget.connection)),
      NavigationItem('${context.localize('navcardimport')}',
          ImportScreen(connection: widget.connection)),
      NavigationItem('${context.localize('navcardreport')}',
          ReportScreen(connection: widget.connection)),
      NavigationItem('${context.localize('navcardinventory')}',
          InventoryScreen(connection: widget.connection))
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: navigationItems.map((item) {
        return NavigationCard(
          title: item.title,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item.screen),
            );
          },
        );
      }).toList(),
    );
  }

  Widget buildMachineRow(
      PostgreSQLConnection connection, List<int> machineNumbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: machineNumbers.length == 1
          ? [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: MachineCard(
                      connection: connection,
                      machineNumber: machineNumbers.first),
                ),
              ),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ]
          : machineNumbers.map((number) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: MachineCard(
                      connection: connection, machineNumber: number),
                ),
              );
            }).toList(),
    );
  }

  void fetchNotifications() async {
    List<Tool> lowQtyTools = await databaseHelper.checkMinQty();
    int notificationIndex = notifications.indexWhere(
      (n) => n.message.contains('tools below minimum order quantity'),
    );

    if (lowQtyTools.isNotEmpty) {
      String newMessage =
          'There are ${lowQtyTools.length} tools below minimum order quantity!';
      if (notificationIndex >= 0) {
        notifications[notificationIndex] = NotificationItem(
          message: newMessage,
          action: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ToolTableDialog(
                tools: Map.fromIterable(lowQtyTools,
                    key: (item) => item.id!, value: (item) => item),
                databaseHelper: databaseHelper,
                notifier:
                    Provider.of<ToolExchangeNotifier>(context, listen: false),
                actionTypes: const [ToolAction.Edit],
              ),
            ));
          },
        );
      } else {
        notifications.add(NotificationItem(
          message: newMessage,
          action: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ToolTableDialog(
                tools: Map.fromIterable(lowQtyTools,
                    key: (item) => item.id!, value: (item) => item),
                databaseHelper: databaseHelper,
                notifier:
                    Provider.of<ToolExchangeNotifier>(context, listen: false),
                actionTypes: const [ToolAction.Edit],
              ),
            ));
          },
        ));
      }
    } else {
      if (notificationIndex >= 0) {
        notifications.removeAt(notificationIndex);
      }
    }

    setState(() {
      notificationCount = notifications.length;
    });
  }

  Widget buildAppBarIcons() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Padding(
        padding: const EdgeInsets.only(right: 100),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return NotificationDialog(notifications: notifications);
                  },
                );
              },
              onHover: (isHovering) {},
              borderRadius: BorderRadius.circular(32.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications, size: 32.0),
                      if (notificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(themeProvider.themeMode == ThemeMode.dark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round),
              onPressed: () {
                themeProvider
                    .toggleTheme(themeProvider.themeMode != ThemeMode.dark);
              },
            ),
            IconButton(
              icon: Flag.fromCode(
                localeProvider.currentLocale.languageCode == 'hr'
                    ? FlagsCode.GB
                    : FlagsCode.HR,
                height: 20,
                width: 30,
                fit: BoxFit.fill,
              ),
              onPressed: () {
                if (localeProvider.currentLocale.languageCode == 'hr') {
                  localeProvider.setLocale(Locale('en'));
                } else {
                  localeProvider.setLocale(Locale('hr'));
                }
              },
            ),
          ],
        ));
  }
}

class NavigationItem {
  final String title;
  final Widget screen;

  NavigationItem(this.title, this.screen);
}
