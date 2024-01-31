import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:provider/provider.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class AppTheme {
  static Color parseMaterialText(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? AppColors.grey
        : AppColors.blueGrey700;
  }

  static Color toolLocationText(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? AppColors.greenDark
        : AppColors.indigo300;
  }

  static Color invNumText(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? AppColors.yellow
        : AppColors.orange900;
  }

  static Color dialogText(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? AppColors.white
        : AppColors.black;
  }

  static Color machineCardColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
        ? machineCardColorDark
        : machineCardColorLight;
  }

  static Color toastColor(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark
        ? AppColors.blueGrey900
        : AppColors.blueGrey100;
  }

  static final Color machineCardColorLight = AppColors.blueGrey100;
  static final Color machineCardColorDark = AppColors.blueGrey900;
  static final Color machineCardTitleColor = AppColors.orange900;

  static final List<Color> machineCardInnerColorsLight = [
    AppColors.teal50,
    Colors.cyan.shade50,
  ];
  static final List<Color> machineCardInnerColorsDark = [
    AppColors.blueGrey800,
    AppColors.blueGrey700,
  ];

  static ThemeData get lightTheme {
    return ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(primary: AppColors.blueGrey300),
        appBarTheme: AppBarTheme(
            backgroundColor: AppColors.blueGrey100,
            titleTextStyle:
                const TextStyle(color: AppColors.black, fontSize: 20)),
        scaffoldBackgroundColor: AppColors.cyan,
        cardTheme: CardTheme(
          color: AppColors.teal50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade50,
            foregroundColor: AppColors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.white,
          headerBackgroundColor: AppColors.blueGrey300,
          headerForegroundColor: AppColors.black,
          dayStyle: const TextStyle(color: AppColors.black),
          yearStyle: const TextStyle(color: AppColors.black),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.teal50,
        ),
        dialogTheme: DialogTheme(backgroundColor: AppColors.blueGrey100));
  }

  static ThemeData get darkTheme {
    return ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(primary: AppColors.blueGrey300),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.blueGrey900,
          titleTextStyle: const TextStyle(color: AppColors.white, fontSize: 20),
        ),
        scaffoldBackgroundColor: AppColors.grey900,
        cardTheme: CardTheme(
          color: AppColors.blueGrey900,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blueGrey800,
            foregroundColor: AppColors.white, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.grey850,
          headerBackgroundColor: AppColors.blueGrey900,
          headerForegroundColor: AppColors.white,
          dayStyle: const TextStyle(color: AppColors.white),
          yearStyle: const TextStyle(color: AppColors.white),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.blueGrey900,
        ),
        dialogTheme: DialogTheme(backgroundColor: AppColors.blueGrey900));
  }
}
