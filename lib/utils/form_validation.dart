String? validateNumericField(String? value) {
  if (value!.contains(',')) {
    return 'Use a dot instead of a comma';
  }
  if (value != '' && double.tryParse(value) == null) {
    return 'Enter a valid number';
  }
  return null;
}

String? validateIntegerField(String? value) {
  if (value != '' && int.tryParse(value!) == null) {
    return 'Enter a valid integer';
  }
  return null;
}

String? validateToolType(String? value) {
  if (!tooltypeToSourcetable.containsKey(value)) {
    return 'Select correct tool type';
  }
  return null;
}

String? validateInvNum(String? value) {
  if (value == '') {
    return 'Inventory number missing';
  }
  return null;
}

Map<String, String> tooltypeToSourcetable = {
  "Prihvat": "fixture",
  "Čahura": "fixture",
  "Glodalo za navoj": "threadmaking",
  "T-Glodalo": "tool",
  "Pločica": "tool",
  "Alat za štosanje": "tool",
  "Svrdlo": "tool",
  "Trkač": "tool",
  "Uvaljivač": "threadmaking",
  "Upuštač": "tool",
  "Glodalo": "tool",
  "Glava": "tool",
  "Lastin rep": "tool",
  "Centar punta": "tool",
  "Ureznik": "threadmaking",
  "Pila": "tool",
  "Trivela": "tool",
};
