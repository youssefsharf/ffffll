import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/daily_entity.dart';

class DataManager {
  // حفظ مدخل واحد
  Future<void> saveEntry(DailyEntry entry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedEntries = prefs.getStringList('dailyEntries') ?? [];

    String entryJson = jsonEncode(entry.toJson());
    storedEntries.add(entryJson);

    await prefs.setStringList('dailyEntries', storedEntries);
  }



  // تحميل جميع المدخلات المحفوظة
  Future<List<DailyEntry>> loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedEntries = prefs.getStringList('dailyEntries') ?? [];

    List<DailyEntry> entries = storedEntries
        .map((entryJson) => DailyEntry.fromJson(jsonDecode(entryJson)))
        .toList();

    return entries;
  }

  // تحديث المدخلات في SharedPreferences
  Future<void> updateEntries(List<DailyEntry> entries) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> entryJsonList =
    entries.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList('dailyEntries', entryJsonList);
  }

  // حذف مدخل محدد
  Future<void> deleteEntry(DailyEntry entry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedEntries = prefs.getStringList('dailyEntries') ?? [];

    List<DailyEntry> entries = storedEntries
        .map((entryJson) => DailyEntry.fromJson(jsonDecode(entryJson)))
        .toList();

    entries.remove(entry);

    List<String> entryJsonList =
    entries.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList('dailyEntries', entryJsonList);
  }
}