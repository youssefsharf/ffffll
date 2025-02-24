import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/daily_entity.dart';
import '../../../home/presentation/pages/myHomePage.dart';

class OfficePage extends StatefulWidget {
  final String title;
  final Color tableColor;
  final List<DailyEntry> initialEntries;

  const OfficePage({
    super.key,
    required this.title,
    required this.tableColor,
    required this.initialEntries,
  });

  @override
  State<OfficePage> createState() => _OfficePageState();
}

class _OfficePageState extends State<OfficePage> {
  List<DailyEntry> officeEntries = [];
  List<DailyEntry> filteredEntries = [];
  String? selectedName;
  List<DateTime?> selectedDateRange = [null, null];
  List<String> availableNames = [];

  @override
  void initState() {
    super.initState();
    _loadOfficeEntries();
  }

  Future<void> _loadOfficeEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedEntries = prefs.getStringList('officeEntries');

    setState(() {
      officeEntries = storedEntries != null
          ? storedEntries.map((entry) => DailyEntry.fromJson(jsonDecode(entry))).toList() + widget.initialEntries
          : widget.initialEntries;
      officeEntries.sort((a, b) => b.date.compareTo(a.date)); // ترتيب من الجديد إلى القديم
      filteredEntries = officeEntries;
      availableNames = officeEntries.map((entry) => entry.name).toSet().toList();
    });

    _saveOfficeEntries();
  }

  Future<void> _saveOfficeEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> entries = officeEntries.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList('officeEntries', entries);
  }

  double get totalGoods => filteredEntries.fold(0, (sum, entry) => sum + entry.goldForUs);
  double get totalKheesh => filteredEntries.fold(0, (sum, entry) => sum + entry.goldForUs);
  double get totalAshr => filteredEntries.fold(0, (sum, entry) => sum + entry.goldForUs);

  void _filterEntriesByName(String? name) {
    setState(() {
      filteredEntries = name == null || name.isEmpty
          ? List.from(officeEntries)
          : officeEntries.where((entry) => entry.name == name).toList();
      filteredEntries.sort((a, b) => b.date.compareTo(a.date)); // ترتيب من الجديد إلى القديم
    });
  }

  void _filterEntriesByDateRange(List<DateTime?> range) {
    setState(() {
      filteredEntries = range[0] != null && range[1] != null
          ? officeEntries.where((entry) => entry.date.isAfter(range[0]!) && entry.date.isBefore(range[1]!)).toList()
          : List.from(officeEntries);
      filteredEntries.sort((a, b) => b.date.compareTo(a.date)); // ترتيب من الجديد إلى القديم
    });
  }

  void _showNamePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: availableNames.map((name) => ListTile(
          title: Text(name),
          onTap: () {
            setState(() {
              selectedName = name;
              _filterEntriesByName(selectedName);
            });
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _pickDateRange() async {
    final config = CalendarDatePicker2WithActionButtonsConfig(calendarType: CalendarDatePicker2Type.range);
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

  @override
  Widget build(BuildContext context) {
    List<DailyEntry> goodsEntries = filteredEntries.where((entry) => entry.notes == "بضاعة").toList();
    List<DailyEntry> kheeshEntries = filteredEntries.where((entry) => entry.notes == "خياس").toList();
    List<DailyEntry> ashrEntries = filteredEntries.where((entry) => entry.notes == "خشر").toList();

    // ترتيب المدخلات من الجديد إلى القديم
    goodsEntries.sort((a, b) => b.date.compareTo(a.date));
    kheeshEntries.sort((a, b) => b.date.compareTo(a.date));
    ashrEntries.sort((a, b) => b.date.compareTo(a.date));

    double totalGoodsColumn = goodsEntries.fold(0, (sum, entry) => sum + (entry.goldForUs - entry.goldForHim));
    double totalKheeshColumn = kheeshEntries.fold(0, (sum, entry) => sum + (entry.goldForUs - entry.goldForHim));
    double totalAshrColumn = ashrEntries.fold(0, (sum, entry) => sum + (entry.goldForUs - entry.goldForHim));

    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 16,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 600;
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ValueListenableBuilder<double>(
                      valueListenable: cumulativeGoldForUsNotifier,
                      builder: (context, value, child) {
                        return Text(
                          'لنا: ${value.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ValueListenableBuilder<double>(
                      valueListenable: cumulativeGoldForHimNotifier,
                      builder: (context, value, child) {
                        return Text(
                          'له: ${value.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                  if (isWide) const SizedBox(width: 230),
                  if (!isWide) SizedBox(width: 30),
                  const Text(
                    'الخزينة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
        backgroundColor: widget.tableColor,
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.3),
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
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: DataTable(
                          columnSpacing: 22,
                          horizontalMargin: 10,
                          headingRowHeight: 60,
                          dataRowHeight: 50,
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
                          headingRowColor: MaterialStateProperty.all(widget.tableColor),
                          columns: [
                            DataColumn(label: buildCenteredText('بضاعة', width: 90)),
                            DataColumn(label: buildCenteredText('خياس', width: 90)),
                            DataColumn(label: buildCenteredText('خشر', width: 90)),
                          ],
                          rows: [
                            // عرض البيانات في الأعمدة المناسبة
                            for (int i = 0; i < max(goodsEntries.length, max(kheeshEntries.length, ashrEntries.length)); i++)
                              DataRow(cells: [
                                DataCell(
                                  Center(
                                    child: Text(
                                      i < goodsEntries.length
                                          ? (goodsEntries[i].goldForUs - goodsEntries[i].goldForHim).toStringAsFixed(2)
                                          : "",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Center(
                                    child: Text(
                                      i < kheeshEntries.length
                                          ? (kheeshEntries[i].goldForUs - kheeshEntries[i].goldForHim).toStringAsFixed(2)
                                          : "",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Center(
                                    child: Text(
                                      i < ashrEntries.length
                                          ? (ashrEntries[i].goldForUs - ashrEntries[i].goldForHim).toStringAsFixed(2)
                                          : "",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "بضاعة: ${totalGoodsColumn.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          "خياس: ${totalKheeshColumn.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          "خشر: ${totalAshrColumn.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
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