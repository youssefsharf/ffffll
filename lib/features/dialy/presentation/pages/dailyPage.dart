import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../main.dart'; // استيراد ValueNotifier
import '../../../../core/widgets/export.dart';
import '../../../../data/models/daily_entity.dart';
import '../../../debts/presentation/pages/debts.dart';
import '../../../office/presentation/pages/office.dart';
import '../../../workshop/presentation/pages/workshop.dart';
import 'info.dart';

class DailyPage extends StatefulWidget {
  final List<DailyEntry> initialEntries;
  final Color tableColor;

  const DailyPage({
    Key? key,
    required this.initialEntries,
    required this.tableColor,
    required String title,
  }) : super(key: key);

  @override
  _DailyPageState createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  List<DailyEntry> dailyEntries = [];
  bool isDataLoaded = false;
  final dataManager = DataManager();
  var _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _goldForUsController = TextEditingController();
  final _goldForHimController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _nameFilter = '';
  DailyEntry? _editingEntry;
  int? _editingIndex;

  // قائمة الخيارات للبيان
  final List<String> _noteOptions = ['بضاعة', 'خياس', 'خشر'];
  String _selectedNote = '';
  double cumulativeGoldForUs = 0.0;
  double cumulativeGoldForHim = 0.0;
  // Set لتخزين جميع الأسماء المدخلة سابقًا
  Set<String> nameSuggestions = {};

  // Set لتخزين الأسماء التي تم إدخال أرقامها
  Set<String> namesWithNumbers = {};

  double get totalGoldForUs =>
      dailyEntries.fold(0, (sum, entry) => sum + entry.goldForUs);

  double get totalGoldForHim =>
      dailyEntries.fold(0, (sum, entry) => sum + entry.goldForHim);

  @override
  void initState() {
    super.initState();
    dailyEntries = widget.initialEntries;
    _loadEntries();
    _loadNameSuggestions();
    _loadNamesWithNumbers();
    _loadTotals();
    _loadCumulativeGoldForUs(); // تحميل القيمة التراكمية المحفوظة
    _loadCumulativeGoldForHim(); // تحميل القيمة التراكمية المحفوظة
  }

  Future<void> _loadCumulativeGoldForUs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cumulativeGoldForUs = prefs.getDouble('cumulativeGoldForUs') ?? 0.0;
    });
  }

  Future<void> _loadCumulativeGoldForHim() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cumulativeGoldForHim = prefs.getDouble('cumulativeGoldForHim') ?? 0.0;
    });
  }

  Future<void> _loadTotals() async {
    final prefs = await SharedPreferences.getInstance();
    totalForUsNotifier.value = prefs.getDouble('totalForUs') ?? 0.0;
    totalForHimNotifier.value = prefs.getDouble('totalForHim') ?? 0.0;
  }

  Future<void> _saveTotals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalForUs', totalGoldForUs);
    await prefs.setDouble('totalForHim', totalGoldForHim);
  }

  Future<void> _saveCumulativeGoldForUs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cumulativeGoldForUs', cumulativeGoldForUs);
  }

  Future<void> _saveCumulativeGoldForHim() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cumulativeGoldForHim', cumulativeGoldForHim);
  }

  void _updateNotifiers() {
    if (mounted) {
      totalForUsNotifier.value = totalGoldForUs;
      totalForHimNotifier.value = totalGoldForHim;
    }
  }

  Future<void> _loadEntries() async {
    setState(() => isDataLoaded = false);
    dailyEntries = await dataManager.loadEntries();
    nameSuggestions = dailyEntries.map((entry) => entry.name).toSet();
    setState(() => isDataLoaded = true);
    _updateNotifiers(); // تحديث القيم بعد تحميل الإدخالات
  }

  Future<void> _loadNameSuggestions() async {
    nameSuggestions = await loadNameSuggestions();
    setState(() {});
  }

  Future<void> _loadNamesWithNumbers() async {
    namesWithNumbers = await loadNamesWithNumbers();
    setState(() {});
  }

  Future<void> saveNameSuggestions(Set<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nameSuggestions', names.toList());
  }

  Future<void> saveNamesWithNumbers(Set<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('namesWithNumbers', names.toList());
  }

  Future<Set<String>> loadNameSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('nameSuggestions') ?? [];
    return names.toSet();
  }

  Future<Set<String>> loadNamesWithNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('namesWithNumbers') ?? [];
    return names.toSet();
  }

  Future<void> _exportData() async {
    // حساب القيم التراكمية بناءً على الإدخالات الحالية
    double totalGoldForUs = dailyEntries.fold(0, (sum, entry) => sum + entry.goldForUs);
    double totalGoldForHim = dailyEntries.fold(0, (sum, entry) => sum + entry.goldForHim);

    // تحديث القيم التراكمية
    setState(() {
      cumulativeGoldForUs += totalGoldForUs;
      cumulativeGoldForHim += totalGoldForHim;
    });

    // حفظ القيم التراكمية في SharedPreferences
    await _saveCumulativeGoldForUs();
    await _saveCumulativeGoldForHim();

    // تصدير البيانات إلى الصفحات الأخرى
    List<DailyEntry> workshopEntries =
    dailyEntries.where((entry) => entry.name == 'ورشة').toList();
    List<DailyEntry> otherEntries =
    dailyEntries.where((entry) => entry.name != 'ورشة').toList();

    if (workshopEntries.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkshopPage(
            title: 'الورشة',
            tableColor: widget.tableColor,
            initialEntries: workshopEntries,
          ),
        ),
      );
    }

    if (otherEntries.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DebtsPage(
            title: 'الذمم',
            tableColor: widget.tableColor,
            initialEntries: otherEntries,
          ),
        ),
      );
    }

    if (dailyEntries.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfficePage(
            title: 'الخزينة',
            tableColor: widget.tableColor,
            initialEntries: dailyEntries,
          ),
        ),
      );
    }

    // مسح الإدخالات بعد التصدير
    setState(() {
      dailyEntries.clear();
    });

    await dataManager.updateEntries(dailyEntries);
  }

  Future<void> _saveEntry() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الاسم مطلوب')),
      );
      return;
    }

    if (_selectedNote.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('البيان مطلوب')),
      );
      return;
    }

    double goldForUs = double.tryParse(_goldForUsController.text) ?? 0;
    double goldForHim = double.tryParse(_goldForHimController.text) ?? 0;

    if (goldForUs == 0 && goldForHim == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب إدخال قيمة على الأقل في "ذهب لنا" أو "ذهب له"')),
      );
      return;
    }

    bool nameExists = dailyEntries.any((entry) => entry.name == _nameController.text);
    bool hasNumber = namesWithNumbers.contains(_nameController.text);

    if (!nameExists && _nameController.text != 'ورشة' && !hasNumber) {
      final newCustomerData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddCustomerPage(
            name: _nameController.text,
          ),
        ),
      );

      if (newCustomerData != null) {
        _nameController.text = newCustomerData['name'];
        namesWithNumbers.add(_nameController.text);
        await saveNamesWithNumbers(namesWithNumbers);
      } else {
        return;
      }
    }

    final newEntry = DailyEntry(
      name: _nameController.text,
      notes: _selectedNote,
      goldForUs: goldForUs,
      goldForHim: goldForHim,
      date: _selectedDate,
      tableColor: widget.tableColor,
      customer: '',
    );

    if (_editingEntry != null && _editingIndex != null) {
      setState(() {
        dailyEntries[_editingIndex!] = newEntry;
        _editingEntry = null;
        _editingIndex = null;
      });
    } else {
      setState(() {
        dailyEntries.add(newEntry);
        nameSuggestions.add(newEntry.name);
      });
    }

    await dataManager.saveEntry(newEntry);
    await saveNameSuggestions(nameSuggestions);
    _updateNotifiers(); // تحديث القيم بعد الحفظ
    await _saveTotals(); // حفظ القيم التراكمية في SharedPreferences

    _nameController.clear();
    _selectedNote = '';
    _goldForUsController.clear();
    _goldForHimController.clear();
  }

  @override
  Widget build(BuildContext context) {
    List<DailyEntry> filteredEntries = dailyEntries
        .where((entry) => _nameFilter.isEmpty || entry.name.contains(_nameFilter))
        .toList();

    filteredEntries.sort((a, b) => a.date.compareTo(b.date));
    filteredEntries = filteredEntries.reversed.toList();

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
              )],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 600;
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: Text(
                      'لنا: ${cumulativeGoldForUs.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      'له: ${cumulativeGoldForHim.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Text(
                    'اليومية',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _nameFilter = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'ابحث بالاسم',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isDataLoaded)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 22,
                            horizontalMargin: 10,
                            headingRowHeight: 60,
                            dataRowHeight: 70,
                            headingTextStyle: TextStyle(
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
                                  label: buildCenteredText('الاسم', width: 150)),
                              DataColumn(
                                  label: buildCenteredText('التاريخ', width: 100)),
                              DataColumn(
                                  label: buildCenteredText('البيان', width: 150)),
                              DataColumn(label: buildCenteredText('ذهب لنا')),
                              DataColumn(label: buildCenteredText('ذهب له')),
                              DataColumn(label: buildCenteredText('الإجراءات')),
                            ],
                            rows: [
                              DataRow(cells: [
                                DataCell(Center(
                                    child: Autocomplete<String>(
                                      optionsBuilder: (TextEditingValue value) {
                                        if (value.text.isEmpty) {
                                          return [];
                                        }
                                        return nameSuggestions
                                            .where((name) => name
                                            .toLowerCase()
                                            .contains(value.text.toLowerCase()))
                                            .toList();
                                      },
                                      onSelected: (String selectedName) {
                                        _nameController.text = selectedName;
                                      },
                                      fieldViewBuilder: (context, controller,
                                          focusNode, onFieldSubmitted) {
                                        _nameController = controller;
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: InputDecoration(
                                            labelText: 'الاسم',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 16),
                                          ),
                                        );
                                      },
                                      optionsViewBuilder:
                                          (context, onSelected, options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4.0,
                                            child: SizedBox(
                                              height: 200,
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: options.length,
                                                itemBuilder: (context, index) {
                                                  final option =
                                                  options.elementAt(index);
                                                  return ListTile(
                                                    title: Text(option),
                                                    onTap: () {
                                                      onSelected(option);
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ))),
                                DataCell(
                                  GestureDetector(
                                    onTap: () async {
                                      final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null &&
                                          picked != _selectedDate) {
                                        setState(() {
                                          _selectedDate = picked;
                                        });
                                      }
                                    },
                                    child: Center(
                                        child: buildCenteredText(
                                            DateFormat('yyyy-MM-dd')
                                                .format(_selectedDate))),
                                  ),
                                ),
                                DataCell(Center(
                                  child: DropdownButton<String>(
                                    value: _selectedNote.isEmpty
                                        ? null
                                        : _selectedNote,
                                    hint: Text("اختر البيان"),
                                    items: _noteOptions
                                        .map((value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Center(child: Text(value)),
                                    ))
                                        .toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedNote = newValue!;
                                      });
                                    },
                                  ),
                                )),
                                DataCell(Center(
                                    child: buildTextField(
                                        _goldForUsController, 'ذهب لنا',
                                        isNumber: true))),
                                DataCell(Center(
                                    child: buildTextField(
                                        _goldForHimController, 'ذهب له',
                                        isNumber: true))),
                                DataCell(Center(
                                    child: ElevatedButton(
                                      onPressed: _saveEntry,
                                      child: Text(
                                          _editingEntry != null ? 'حفظ' : 'إضافة'),
                                    ))),
                              ]),
                              ...filteredEntries.map((entry) {
                                return DataRow(cells: [
                                  DataCell(buildCenteredText(entry.name)),
                                  DataCell(buildCenteredText(
                                      DateFormat('yyyy-MM-dd').format(entry.date))),
                                  DataCell(buildCenteredText(entry.notes)),
                                  DataCell(buildCenteredText(
                                      entry.goldForUs.toString())),
                                  DataCell(buildCenteredText(
                                      entry.goldForHim.toString())),
                                  DataCell(Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          setState(() {
                                            _editingEntry = entry;
                                            _editingIndex =
                                                dailyEntries.indexOf(entry);
                                            _nameController.text = entry.name;
                                            _selectedNote = entry.notes;
                                            _goldForUsController.text =
                                                entry.goldForUs.toString();
                                            _goldForHimController.text =
                                                entry.goldForHim.toString();
                                            _selectedDate = entry.date;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            dailyEntries.remove(entry);
                                            dataManager.updateEntries(dailyEntries);
                                          });
                                        },
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              "مجموع ذهب لنا: ${totalGoldForUs.toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 20),
                          Text(
                              "مجموع ذهب له: ${totalGoldForHim.toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _exportData,
                    child: Text("تصدير البيانات"),
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

