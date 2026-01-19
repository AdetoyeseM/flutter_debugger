import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry representing a single SharedPreferences value
class PrefsEntry {
  final String key;
  final dynamic value;
  final String type;

  PrefsEntry({
    required this.key,
    required this.value,
    required this.type,
  });

  String get displayValue {
    if (value == null) return 'null';
    if (value is String && value.length > 100) {
      return '${value.substring(0, 100)}...';
    }
    return value.toString();
  }

  String get fullValue => value?.toString() ?? 'null';
}

/// Service to view and manage SharedPreferences
class PrefsViewer {
  static PrefsViewer? _instance;
  
  static PrefsViewer get instance {
    _instance ??= PrefsViewer._internal();
    return _instance!;
  }

  PrefsViewer._internal();

  SharedPreferences? _prefs;
  final ValueNotifier<int> updateNotifier = ValueNotifier(0);

  /// Initialize the preferences instance
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    updateNotifier.value++;
  }

  /// Get all stored preferences
  Future<List<PrefsEntry>> getAll() async {
    if (_prefs == null) await init();
    
    final keys = _prefs!.getKeys().toList()..sort();
    final entries = <PrefsEntry>[];

    for (final key in keys) {
      final value = _prefs!.get(key);
      String type;

      if (value is String) {
        type = 'String';
      } else if (value is int) {
        type = 'int';
      } else if (value is double) {
        type = 'double';
      } else if (value is bool) {
        type = 'bool';
      } else if (value is List<String>) {
        type = 'List<String>';
      } else {
        type = value.runtimeType.toString();
      }

      entries.add(PrefsEntry(key: key, value: value, type: type));
    }

    return entries;
  }

  /// Get a specific value
  Future<dynamic> get(String key) async {
    if (_prefs == null) await init();
    return _prefs!.get(key);
  }

  /// Set a string value
  Future<bool> setString(String key, String value) async {
    if (_prefs == null) await init();
    final result = await _prefs!.setString(key, value);
    updateNotifier.value++;
    return result;
  }

  /// Set an int value
  Future<bool> setInt(String key, int value) async {
    if (_prefs == null) await init();
    final result = await _prefs!.setInt(key, value);
    updateNotifier.value++;
    return result;
  }

  /// Set a double value
  Future<bool> setDouble(String key, double value) async {
    if (_prefs == null) await init();
    final result = await _prefs!.setDouble(key, value);
    updateNotifier.value++;
    return result;
  }

  /// Set a bool value
  Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) await init();
    final result = await _prefs!.setBool(key, value);
    updateNotifier.value++;
    return result;
  }

  /// Set a string list value
  Future<bool> setStringList(String key, List<String> value) async {
    if (_prefs == null) await init();
    final result = await _prefs!.setStringList(key, value);
    updateNotifier.value++;
    return result;
  }

  /// Remove a specific key
  Future<bool> remove(String key) async {
    if (_prefs == null) await init();
    final result = await _prefs!.remove(key);
    updateNotifier.value++;
    return result;
  }

  /// Clear all preferences
  Future<bool> clear() async {
    if (_prefs == null) await init();
    final result = await _prefs!.clear();
    updateNotifier.value++;
    return result;
  }

  /// Search preferences by key
  Future<List<PrefsEntry>> search(String query) async {
    final all = await getAll();
    if (query.isEmpty) return all;
    
    final lowerQuery = query.toLowerCase();
    return all.where((entry) {
      return entry.key.toLowerCase().contains(lowerQuery) ||
          entry.displayValue.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Export all preferences as JSON
  Future<Map<String, dynamic>> exportAsJson() async {
    final all = await getAll();
    final map = <String, dynamic>{};
    for (final entry in all) {
      map[entry.key] = {
        'value': entry.value,
        'type': entry.type,
      };
    }
    return map;
  }

  /// Get total count
  Future<int> getCount() async {
    if (_prefs == null) await init();
    return _prefs!.getKeys().length;
  }
}

/// Global instance accessor
PrefsViewer get prefsViewer => PrefsViewer.instance;

