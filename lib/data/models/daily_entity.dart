import 'dart:ui';

class DailyEntry {
  String name;
  DateTime date;
  String notes;
  double goldForUs;
  double goldForHim;
  String customer;
  Color tableColor;
  String customerInfo;
  // إضافة حقل جديد

  DailyEntry({
    required this.name,
    required this.date,
    required this.notes,
    required this.goldForUs,
    required this.goldForHim,
    required this.customer,
    required this.tableColor,
    this.customerInfo = '', // قيمة افتراضية
  });

  // تحويل الكائن إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'notes': notes,
      'goldForUs': goldForUs,
      'goldForHim': goldForHim,
      'customer': customer,
      'tableColor': tableColor.value.toString(),
      'customerInfo': customerInfo, // إضافة customerInfo إلى JSON
    };
  }

  // تحويل JSON إلى كائن
  factory DailyEntry.fromJson(Map<String, dynamic> json) {
    return DailyEntry(
      name: json['name'] ?? '',
      date: DateTime.parse(json['date']),
      notes: json['notes'] ?? '',
      goldForUs: json['goldForUs'] ?? 0.0,
      goldForHim: json['goldForHim'] ?? 0.0,
      customer: json['customer'] ?? '',
      tableColor: Color(int.parse(json['tableColor'] ?? '0')),
      customerInfo: json['customerInfo'] ?? '', // إضافة customerInfo من JSON
    );
  }
}