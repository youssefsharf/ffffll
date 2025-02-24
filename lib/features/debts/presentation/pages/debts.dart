import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/daily_entity.dart';

class DebtsPage extends StatefulWidget {
  final String title;
  final Color tableColor;
  final List<DailyEntry> initialEntries;

  const DebtsPage({
    super.key,
    required this.title,
    required this.tableColor,
    required this.initialEntries,
  });

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  List<DailyEntry> debtsEntries = [];
  List<DailyEntry> filteredEntries = [];
  String? selectedName;
  List<DateTime?> selectedDateRange = [null, null];
  List<String> availableNames = [];
  Set<String> expandedNames = {}; // لتتبع الأسماء المفتوحة

  @override
  void initState() {
    super.initState();
    _loadDebtsEntries();
  }

  Future<void> _loadDebtsEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedEntries = prefs.getStringList('debtsEntries');
    List<DailyEntry> oldEntries = storedEntries != null
        ? storedEntries.map((e) => DailyEntry.fromJson(jsonDecode(e))).toList()
        : widget.initialEntries;

    setState(() {
      debtsEntries = oldEntries + widget.initialEntries;
      debtsEntries.sort((a, b) => b.date.compareTo(a.date));
      filteredEntries = debtsEntries;
      availableNames = debtsEntries.map((e) => e.name).toSet().toList();
    });

    _saveDebtsEntries();
  }

  Future<void> _saveDebtsEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> entries =
    debtsEntries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('debtsEntries', entries);
  }

  void _filterEntriesByName(String? name) {
    setState(() {
      filteredEntries = name == null || name.isEmpty
          ? debtsEntries
          : debtsEntries.where((entry) => entry.name == name).toList();
      if (filteredEntries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد بيانات مطابقة للاسم المحدد'),
          ),
        );
      }
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _filterEntriesByDateRange(List<DateTime?> range) {
    setState(() {
      filteredEntries = range[0] != null && range[1] != null
          ? debtsEntries
          .where((entry) =>
      entry.date.isAfter(range[0]!) &&
          entry.date.isBefore(range[1]!))
          .toList()
          : debtsEntries;
      if (filteredEntries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد بيانات مطابقة لنطاق التاريخ المحدد'),
          ),
        );
      }
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _showNamePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: availableNames.map((name) {
            return ListTile(
              title: Text(name),
              onTap: () {
                setState(() {
                  selectedName = name;
                  _filterEntriesByName(selectedName);
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _pickDateRange() async {
    final config = CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.range,
    );

    List<DateTime?>? pickedDateRange = await showCalendarDatePicker2Dialog(
      context: context,
      config: config,
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
      dialogBackgroundColor: Colors.white,
    );

    if (pickedDateRange != null && pickedDateRange.length == 2) {
      setState(() {
        selectedDateRange = pickedDateRange;
        _filterEntriesByDateRange(selectedDateRange);
      });
    }
  }

  Future<void> _createAndShareText(
      String name, double goldForUs, double goldForHim, DateTime date, String notes) async {
    // إنشاء نص الفاتورة
    String invoiceText = '''
الفاتورة:
الاسم: $name
التاريخ: ${DateFormat('yyyy-MM-dd').format(date)}
ذهب لنا: $goldForUs
ذهب له: $goldForHim
البيان: $notes
''';

    // إرسال النص كمشاركة
    Share.share(invoiceText, subject: 'إرسال الفاتورة');
  }

  Map<String, double> get totalGoldForUsByName {
    Map<String, double> totals = {};
    for (var entry in filteredEntries) {
      totals.update(entry.name, (value) => value + entry.goldForUs,
          ifAbsent: () => entry.goldForUs);
    }
    return totals;
  }

  Map<String, double> get totalGoldForHimByName {
    Map<String, double> totals = {};
    for (var entry in filteredEntries) {
      totals.update(entry.name, (value) => value + entry.goldForHim,
          ifAbsent: () => entry.goldForHim);
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    double totalGoldForUs = totalGoldForUsByName.values.fold(0, (a, b) => a + b);
    double totalGoldForHim = totalGoldForHimByName.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'الذمم',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
        backgroundColor: widget.tableColor,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showNamePicker(context),
                      child: Text(
                          selectedName == null ? "اختر الاسم" : selectedName!),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickDateRange,
                      child: Text(selectedDateRange[0] == null ||
                          selectedDateRange[1] == null
                          ? "اختر نطاق التاريخ"
                          : "${DateFormat('yyyy-MM-dd').format(selectedDateRange[0]!)} - ${DateFormat('yyyy-MM-dd').format(selectedDateRange[1]!)}"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 22,
                      horizontalMargin: 10,
                      headingRowHeight: 60,
                      dataRowHeight: 70,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      border: TableBorder.all(
                        color: Colors.grey.shade400,
                        width: 1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      headingRowColor:
                      MaterialStateProperty.all(widget.tableColor),
                      columns: [
                        DataColumn(
                            label: buildCenteredText('الاسم', width: 100)),
                        DataColumn(
                            label: buildCenteredText('التاريخ', width: 100)),
                        DataColumn(
                            label: buildCenteredText('البيان', width: 100)),
                        DataColumn(
                            label: buildCenteredText('ذهب لنا', width: 80)),
                        DataColumn(
                            label: buildCenteredText('ذهب له', width: 80)),
                        DataColumn(
                            label: buildCenteredText('إرسال الفاتورة',
                                width: 100)),
                      ],
                      rows: _buildDataRows(),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            "مجموع ذهب لنا: ${totalGoldForUs.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 20),
                        Text(
                            "مجموع ذهب له: ${totalGoldForHim.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DataRow> _buildDataRows() {
    List<DataRow> rows = [];

    if (filteredEntries.isEmpty) {
      return [
        DataRow(
          cells: [
            DataCell(buildCenteredText('لا توجد بيانات مطابقة')),
            DataCell(buildCenteredText('')),
            DataCell(buildCenteredText('')),
            DataCell(buildCenteredText('')),
            DataCell(buildCenteredText('')),
            DataCell(buildCenteredText('')),
          ],
        ),
      ];
    }

    for (var name in availableNames) {
      if (!filteredEntries.any((e) => e.name == name)) continue;

      double totalForUs = totalGoldForUsByName[name] ?? 0;
      double totalForHim = totalGoldForHimByName[name] ?? 0;

      // الصف الرئيسي
      rows.add(
        DataRow(
          cells: [
            DataCell(
              InkWell(
                onTap: () {
                  setState(() {
                    if (expandedNames.contains(name)) {
                      expandedNames.remove(name);
                    } else {
                      expandedNames.add(name);
                    }
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      expandedNames.contains(name)
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.blue.shade800,
                    ),
                    const SizedBox(width: 8),
                    buildCenteredText(name),
                  ],
                ),
              ),
            ),
            DataCell(
              buildCenteredText(
                DateFormat('yyyy-MM-dd').format(
                  filteredEntries.firstWhere((e) => e.name == name).date,
                ),
              ),
            ),
            DataCell(
              buildCenteredText(
                filteredEntries.firstWhere((e) => e.name == name).notes,
              ),
            ),
            DataCell(buildCenteredText(totalForUs.toStringAsFixed(2))),
            DataCell(buildCenteredText(totalForHim.toStringAsFixed(2))),
            DataCell(
              ElevatedButton(
                onPressed: () => _createAndShareText(
                    name, totalForUs, totalForHim, DateTime.now(), ''),
                child: const Text('إرسال الفاتورة'),
              ),
            ),
          ],
        ),
      );

      // إذا كان الاسم مفتوحًا، نضيف الصفوف التفصيلية
      if (expandedNames.contains(name)) {
        for (var entry in filteredEntries.where((e) => e.name == name)) {
          rows.add(
            DataRow(
              color: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                  return Colors.grey[100]!; // لون خلفية الصف التفصيلي
                },
              ),
              cells: [
                DataCell(
                  Row(
                    children: [
                      Icon(Icons.arrow_right, color: Color(0xFF63CCCA)),
                      SizedBox(width: 8),
                      Center(
                        child: Text(entry.name,
                            style: TextStyle(color: Colors.blue.shade800)),
                      ),
                    ],
                  ),
                ),
                DataCell(Center(
                  child: Text(DateFormat('yyyy-MM-dd').format(entry.date),
                      style: TextStyle(color: Colors.blue.shade800)),
                )),
                DataCell(Center(
                  child: Text(entry.notes,
                      style: TextStyle(color: Colors.blue.shade800)),
                )),
                DataCell(Center(
                  child: Text(entry.goldForUs.toStringAsFixed(2),
                      style: TextStyle(color: Colors.blue.shade800)),
                )),
                DataCell(Center(
                  child: Text(entry.goldForHim.toStringAsFixed(2),
                      style: TextStyle(color: Colors.blue.shade800)),
                )),
                DataCell(
                  ElevatedButton(
                    onPressed: () => _createAndShareText(name, entry.goldForUs,
                        entry.goldForHim, entry.date, entry.notes),
                    child: const Text('إرسال الفاتورة'),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }

    return rows;
  }
}