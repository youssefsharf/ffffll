import 'package:flutter/material.dart';
import '../../../debts/presentation/pages/debts.dart';
import '../../../dialy/presentation/pages/dailyPage.dart';
import '../../../dialy/presentation/pages/info.dart';
import '../../../office/presentation/pages/office.dart';
import '../../../workshop/presentation/pages/workshop.dart';

class Square extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;

  const Square({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (title == "اليومية") {
          // إذا كان العنوان هو "اليومية"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DailyPage(
                title: title,
                initialEntries: const [],
                tableColor: color,
              ), // استبدل EmployeeDataGridSource بصفحة مناسبة
            ),
          );
        }
        if (title == "الورشة") {
          // إذا كان العنوان هو "الورشة"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkshopPage(
                title: title,
                tableColor: color,
                initialEntries: [],
              ),
            ),
          );
        }
        if (title == "الخزينة") {
          // إذا كان العنوان هو "المكتب"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfficePage(
                title: title,
                tableColor: color,
                initialEntries: [],
              ),
            ),
          );
        }
        if (title == "الذمم") {
          // إذا كان العنوان هو "الذمم"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DebtsPage(
                title: title,
                tableColor: color,
                initialEntries: [],
              ),
            ),
          );
        }
        if (title == "معلومات الزبائن") {
          // إذا كان العنوان هو "المكتب"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCustomerPage(
                name: '',
              ),
            ),
          );
        }
        // يمكنك إضافة المزيد من الصفحات هنا إذا لزم الأمر
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 57.0,
                color: Colors.white,
              ),
              const SizedBox(height: 8.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
