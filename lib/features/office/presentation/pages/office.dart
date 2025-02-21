import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/daily_entity.dart';


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
      officeEntries.sort((a, b) => b.date.compareTo(a.date));
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

  double get totalGoldForUs => filteredEntries.fold(0, (sum, entry) => sum + entry.goldForUs);
  double get totalGoldForHim => filteredEntries.fold(0, (sum, entry) => sum + entry.goldForHim);

  void _filterEntriesByName(String? name) {
    setState(() {
      filteredEntries = name == null || name.isEmpty ? officeEntries : officeEntries.where((entry) => entry.name == name).toList();
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _filterEntriesByDateRange(List<DateTime?> range) {
    setState(() {
      filteredEntries = range[0] != null && range[1] != null
          ? officeEntries.where((entry) => entry.date.isAfter(range[0]!) && entry.date.isBefore(range[1]!)).toList()
          : officeEntries;
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));
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

  Future<void> _createAndSharePdf(DailyEntry entry) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('الفاتورة:', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('الاسم: ${entry.name}', style: pw.TextStyle(fontSize: 16)),
        pw.Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(entry.date)}', style: pw.TextStyle(fontSize: 16)),
        pw.Text('البيان: ${entry.notes}', style: pw.TextStyle(fontSize: 16)),
        pw.Text('ذهب لنا: ${entry.goldForUs}', style: pw.TextStyle(fontSize: 16)),
        pw.Text('ذهب له: ${entry.goldForHim}', style: pw.TextStyle(fontSize: 16)),
      ],
    )));

    final Uint8List bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/invoice.pdf');
    await file.writeAsBytes(bytes);
    Share.shareXFiles([XFile(file.path)], text: 'إرسال الفاتورة');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          child: LayoutBuilder(
            builder: (context, constraints) {
             // bool isWide = constraints.maxWidth > 600;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[



                  const Text(
                    'الخزينة',
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
                      child: Text(selectedName == null ? "اختر الاسم" : selectedName!),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickDateRange,
                      child: Text(selectedDateRange[0] == null || selectedDateRange[1] == null
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
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      border: TableBorder.all(color: Colors.grey.shade400, width: 1, borderRadius: BorderRadius.circular(8)),
                      headingRowColor: MaterialStateProperty.all(widget.tableColor),
                      columns: [
                        DataColumn(label: buildCenteredText('الاسم', width: 100)),
                        DataColumn(label: buildCenteredText('التاريخ', width: 100)), // إضافة عمود التاريخ
                        DataColumn(label: buildCenteredText('البيان', width: 100)),
                        DataColumn(label: buildCenteredText('ذهب لنا', width: 80)),
                        DataColumn(label: buildCenteredText('ذهب له', width: 80)),
                        DataColumn(label: buildCenteredText('إرسال الفاتورة', width: 100)),
                      ],
                      rows: filteredEntries.map((entry) => DataRow(cells: [
                        DataCell(buildCenteredText(entry.name)),
                        DataCell(buildCenteredText(DateFormat('yyyy-MM-dd').format(entry.date))),
                        DataCell(buildCenteredText(entry.notes)),
                        DataCell(buildCenteredText(entry.goldForUs.toString())),
                        DataCell(buildCenteredText(entry.goldForHim.toString())),
                        DataCell(ElevatedButton(onPressed: () => _createAndSharePdf(entry), child: const Text('إرسال الفاتورة'))),
                      ])).toList(),
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
                        Text("مجموع ذهب لنا: ${totalGoldForUs.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 20),
                        Text("مجموع ذهب له: ${totalGoldForHim.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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