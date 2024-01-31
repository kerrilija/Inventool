import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:provider/provider.dart';
import 'package:dotenv/dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/addremove_screen.dart';
import 'screens/exchange_screen.dart';
import 'package:inventool/database.dart';
import 'package:inventool/utils/app_theme.dart';
import 'package:inventool/providers/locale_provider.dart';
import 'package:inventool/locale/locale.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PostgreSQLConnection? connection;
  late SearchProvider searchProvider;

  @override
  void initState() {
    super.initState();
    _openDatabaseConnection();
  }

  Future<void> _openDatabaseConnection() async {
    var env = DotEnv(includePlatformEnvironment: true)..load();

    String host = env['DB_HOST'] ?? '';
    int port = int.parse(env['DB_PORT'] ?? '5432');
    String dbName = env['DB_NAME'] ?? '';
    String username = env['DB_USERNAME'] ?? '';
    String password = env['DB_PASSWORD'] ?? '';

    connection = PostgreSQLConnection(
      host,
      port,
      dbName,
      username: username,
      password: password,
    );

    try {
      await connection!.open();
      print('SQL Connection successful!');

      if (connection != null && !connection!.isClosed) {
        var databaseHelper = DatabaseHelper(connection: connection!);
        searchProvider = SearchProvider();
        await searchProvider.loadConfig(databaseHelper);
      }
    } catch (e) {
      print('Error connecting to the database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _openDatabaseConnection(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (connection == null || connection!.isClosed) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Failed to connect to the database.'),
                ),
              ),
            );
          }
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: searchProvider),
              ChangeNotifierProvider(create: (context) => ToolFormProvider()),
              ChangeNotifierProvider(
                  create: (context) => ToolExchangeNotifier()),
              ChangeNotifierProvider(create: (context) => ThemeProvider()),
              ChangeNotifierProvider(create: (context) => LocaleProvider())
            ],
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Consumer<LocaleProvider>(
                  builder: (context, localeProvider, __) {
                    return MaterialApp(
                      title: 'Tool Crib',
                      theme: AppTheme.lightTheme,
                      darkTheme: AppTheme.darkTheme,
                      themeMode: themeProvider.themeMode,
                      navigatorKey: MyApp.navigatorKey,
                      locale: localeProvider.currentLocale,
                      localizationsDelegates: [
                        const MyLocalizationsDelegate(),
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      supportedLocales: [
                        const Locale('en', ''),
                        const Locale('hr', ''),
                      ],
                      builder: (context, child) => Overlay(
                        initialEntries: [
                          if (child != null)
                            OverlayEntry(
                              builder: (context) => child,
                            ),
                        ],
                      ),
                      home: HomeScreen(connection: connection!),
                    );
                  },
                );
              },
            ),
          );
        } else {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    connection?.close();
    super.dispose();
  }
}
