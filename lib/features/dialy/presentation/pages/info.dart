import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCustomerPage extends StatefulWidget {
  final String name;

  const AddCustomerPage({Key? key, required this.name}) : super(key: key);

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> savedCustomers = [];
  List<Map<String, String>> filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _loadSavedCustomers();
  }

  // تحميل العملاء المحفوظين من SharedPreferences
  Future<void> _loadSavedCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? customers = prefs.getStringList('savedCustomers');

    if (customers != null) {
      setState(() {
        savedCustomers = customers.map((customer) {
          final data = customer.split(',');
          return {
            'name': data[0],
            'phone': data[1],
          };
        }).toList();
        filteredCustomers = savedCustomers;
      });
    }
  }

  // حفظ العميل الجديد في SharedPreferences
  Future<void> _saveCustomer() async {
    final prefs = await SharedPreferences.getInstance();

    // إضافة العميل الجديد إلى القائمة
    savedCustomers.add({
      'name': _nameController.text,
      'phone': _phoneController.text,
    });

    // حفظ القائمة في SharedPreferences
    List<String> customers = savedCustomers
        .map((customer) => '${customer['name']},${customer['phone']}')
        .toList();

    await prefs.setStringList('savedCustomers', customers);

    // إرجاع البيانات بعد حفظ العميل
    Navigator.pop(context, {
      'name': _nameController.text,
      'phone': _phoneController.text,
    });
  }

  // تصفية العملاء بناءً على نص البحث
  void _filterCustomers(String query) {
    setState(() {
      filteredCustomers = savedCustomers
          .where((customer) =>
          customer['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // عكس القائمة لعرض الأحدث أولاً
    final reversedCustomers = filteredCustomers.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة عميل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty &&
                      _phoneController.text.isNotEmpty) {
                    _saveCustomer();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('الرجاء ملء جميع الحقول')),
                    );
                  }
                },
                child: Text('حفظ'),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'بحث عن عميل',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: _filterCustomers, // تحديث القائمة عند تغيير نص البحث
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'العملاء المحفوظين',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            // عرض العملاء المحفوظين في بطاقات
            Expanded(
              child: ListView.builder(
                itemCount: reversedCustomers.length,
                itemBuilder: (context, index) {
                  final customer = reversedCustomers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        'الاسم: ${customer['name']}',
                        textDirection: TextDirection.rtl,
                      ),
                      subtitle: Text(
                        'رقم الهاتف: ${customer['phone']}',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}