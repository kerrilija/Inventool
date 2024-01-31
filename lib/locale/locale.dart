import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MyLocalizations {
  Locale locale;
  MyLocalizations(this.locale);

  static MyLocalizations? of(BuildContext context) {
    return Localizations.of<MyLocalizations>(context, MyLocalizations);
  }

  Map<String, String>? _localizedStrings;

  Future<bool> load() async {
    String jsonString =
        await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key) {
    return _localizedStrings?[key] ?? key;
  }
}

class MyLocalizationsDelegate extends LocalizationsDelegate<MyLocalizations> {
  const MyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['hr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<MyLocalizations> load(Locale locale) async {
    MyLocalizations localizations = MyLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(MyLocalizationsDelegate old) => true;
}

extension LocalizationExtension on BuildContext {
  String localize(String key) {
    return MyLocalizations.of(this)!.translate(key);
  }
}
