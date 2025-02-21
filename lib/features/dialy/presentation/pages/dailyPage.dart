import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
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
    _updateNotifiers(); // تحديث القيم عند التحميل الأولي
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
    // فلترة الإدخالات بناءً على الاسم
    List<DailyEntry> workshopEntries =
        dailyEntries.where((entry) => entry.name == 'ورشة').toList();
    List<DailyEntry> otherEntries =
        dailyEntries.where((entry) => entry.name != 'ورشة').toList();

    // نقل البيانات التي تساوي "ورشة" إلى صفحة الورشة
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

    // نقل البيانات التي لا تساوي "ورشة" إلى صفحة الذمم
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

    // نقل جميع البيانات إلى صفحة الخزينة
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

    // إزالة الإدخالات التي تم نقلها من القائمة الأصلية
    setState(() {
      dailyEntries.clear();
    });

    // تحديث الإدخالات في dataManager
    await dataManager.updateEntries(dailyEntries);
  }

  void _updateNotifiers() {
    totalForUsNotifier.value = totalGoldForUs;
    totalForHimNotifier.value = totalGoldForHim;
  }

  Future<void> _saveEntry() async {
    // التحقق من أن حقل "البيان" غير فارغ
    if (_selectedNote.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('البيان مطلوب')),
      );
      return;
    }

    // تحويل حقلي "ذهب لنا" و "ذهب له" إلى أرقام، وإذا كانت فارغة أو غير صالحة، تعيينها إلى صفر
    double goldForUs = double.tryParse(_goldForUsController.text) ?? 0;
    double goldForHim = double.tryParse(_goldForHimController.text) ?? 0;

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

    _nameController.clear();
    _selectedNote = '';
    _goldForUsController.clear();
    _goldForHimController.clear();
  }
  @override
  Widget build(BuildContext context) {
    List<DailyEntry> filteredEntries = dailyEntries
        .where(
            (entry) => _nameFilter.isEmpty || entry.name.contains(_nameFilter))
        .toList();

    filteredEntries.sort((a, b) => a.date.compareTo(b.date));
    filteredEntries = filteredEntries.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Container(
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 600;
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: ValueListenableBuilder<double>(
                      valueListenable: totalForUsNotifier,
                      builder: (context, value, child) {
                        return Text(
                          'لنا: ${value.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: ValueListenableBuilder<double>(
                      valueListenable: totalForHimNotifier,
                      builder: (context, value, child) {
                        return Text(
                          'له: ${value.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                  if (isWide) const SizedBox(width: 230),
                  if (!isWide) SizedBox(width: 10),
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
        backgroundColor: widget.tableColor,
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
                                  label:
                                      buildCenteredText('الاسم', width: 150)),
                              DataColumn(
                                  label:
                                      buildCenteredText('التاريخ', width: 100)),
                              DataColumn(
                                  label:
                                      buildCenteredText('البيان', width: 150)),
                              DataColumn(label: buildCenteredText('ذهب لنا')),
                              DataColumn(label: buildCenteredText('ذهب له')),
                              DataColumn(label: buildCenteredText('الإجراءات')),
                            ],
                            rows: [
                              DataRow(cells: [
                                DataCell(Center(
                                    child: Autocomplete<String>(
                                  optionsBuilder: (TextEditingValue value) {
                                    // عرض الأسماء التي تحتوي على الحروف المدخلة
                                    if (value.text.isEmpty) {
                                      return []; // لا تعرض أي اقتراحات إذا كان الحقل فارغًا
                                    }
                                    return nameSuggestions
                                        .where((name) => name
                                            .toLowerCase()
                                            .contains(value.text.toLowerCase()))
                                        .toList();
                                  },
                                  onSelected: (String selectedName) {
                                    _nameController.text =
                                        selectedName; // تعبئة الحقل بالاسم المختار
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
                                          height:
                                              200, // ارتفاع القائمة المقترحة
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: options.length,
                                            itemBuilder: (context, index) {
                                              final option =
                                                  options.elementAt(index);
                                              return ListTile(
                                                title: Text(option),
                                                onTap: () {
                                                  onSelected(
                                                      option); // اختيار الاسم
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
                                      final DateTime? picked =
                                          await showDatePicker(
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
                                        .map((value) =>
                                            DropdownMenuItem<String>(
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
                                      DateFormat('yyyy-MM-dd')
                                          .format(entry.date))),
                                  DataCell(buildCenteredText(entry.notes)),
                                  DataCell(buildCenteredText(
                                      entry.goldForUs.toString())),
                                  DataCell(buildCenteredText(
                                      entry.goldForHim.toString())),
                                  DataCell(Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
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
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            dailyEntries.remove(entry);
                                            dataManager
                                                .updateEntries(dailyEntries);
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

Widget buildCenteredText(String text, {double width = 100}) {
  return SizedBox(
    width: width,
    child: Center(child: Text(text)),
  );
}

Widget buildTextField(TextEditingController controller, String labelText,
    {bool isNumber = false}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
  );
}
