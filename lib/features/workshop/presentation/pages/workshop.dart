import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/daily_entity.dart';

class WorkshopPage extends StatefulWidget {
  final String title;
  final Color tableColor;
  final List<DailyEntry> initialEntries;

  const WorkshopPage({
    super.key,
    required this.title,
    required this.tableColor,
    required this.initialEntries,
  });

  @override
  State<WorkshopPage> createState() => _WorkshopPageState();
}

class _WorkshopPageState extends State<WorkshopPage> {
  List<DailyEntry> workshopEntries = [];
  List<DailyEntry> filteredEntries = [];
  String? selectedName;
  List<DateTime?> selectedDateRange = [null, null];
  List<String> availableNames = [];

  @override
  void initState() {
    super.initState();
    _loadworkshopEntries();
  }

  Future<void> _loadworkshopEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedEntries = prefs.getStringList('workshopEntries');

    if (storedEntries != null) {
      List<DailyEntry> oldEntries = storedEntries
          .map((entry) => DailyEntry.fromJson(jsonDecode(entry)))
          .toList();
      setState(() {
        workshopEntries = oldEntries;
        workshopEntries.sort((a, b) => b.date.compareTo(a.date));
        filteredEntries = workshopEntries;
        availableNames =
            workshopEntries.map((entry) => entry.name).toSet().toList();
      });
    }
  }

  Future<void> _saveworkshopEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> entries =
    workshopEntries.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList('workshopEntries', entries);
  }

  double get totalGoldForUs =>
      filteredEntries.fold(0, (sum, entry) => sum + entry.goldForUs);
  double get totalGoldForHim =>
      filteredEntries.fold(0, (sum, entry) => sum + entry.goldForHim);

  void _filterEntriesByName(String? name) {
    setState(() {
      filteredEntries = name == null || name.isEmpty
          ? workshopEntries
          : workshopEntries.where((entry) => entry.name == name).toList();
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _filterEntriesByDateRange(List<DateTime?> range) {
    setState(() {
      filteredEntries = range[0] != null && range[1] != null
          ? workshopEntries
          .where((entry) =>
      entry.date.isAfter(range[0]!) &&
          entry.date.isBefore(range[1]!))
          .toList()
          : workshopEntries;
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
        calendarType: CalendarDatePicker2Type.range);
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

  Future<void> _createAndShareText(DailyEntry entry) async {
    final text = '''
الفاتورة:
الاسم: ${entry.name}
التاريخ: ${DateFormat('yyyy-MM-dd').format(entry.date)}
البيان: ${entry.notes}
ذهب لنا: ${entry.goldForUs}
ذهب له: ${entry.goldForHim}
''';

    Share.share(text); // مشاركة النص كرسالة
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Container(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'الورشة',
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
      body:

      Directionality(

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
                      child: Text(
                        selectedDateRange[0] == null ||
                            selectedDateRange[1] == null
                            ? "اختر نطاق التاريخ"
                            : "${DateFormat('yyyy-MM-dd').format(selectedDateRange[0]!)} - ${DateFormat('yyyy-MM-dd').format(selectedDateRange[1]!)}",
                      ),
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
                          color: Colors.white),
                      border: TableBorder.all(
                          color: Colors.grey.shade400,
                          width: 1,
                          borderRadius: BorderRadius.circular(8)),
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
                            label: buildCenteredText('إرسال الفاتورة', width: 100)),
                      ],
                      rows: filteredEntries.map((entry) {
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              return states.contains(MaterialState.selected)
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                                  : Colors.white;
                            },
                          ),
                          cells: [
                            DataCell(buildCenteredText(entry.name)),
                            DataCell(buildCenteredText(
                                DateFormat('yyyy-MM-dd').format(entry.date))),
                            DataCell(buildCenteredText(entry.notes)),
                            DataCell(
                                buildCenteredText(entry.goldForUs.toString())),
                            DataCell(
                                buildCenteredText(entry.goldForHim.toString())),
                            DataCell(
                              ElevatedButton(
                                onPressed: () => _createAndShareText(entry),
                                child: const Text('إرسال الفاتورة'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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
}