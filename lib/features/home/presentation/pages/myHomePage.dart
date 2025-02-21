import 'package:flutter/material.dart';
import '../../../../main.dart'; // استيراد ValueNotifier
import '../widgets/square.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      valueListenable: totalForUsNotifier,
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
                        )
                      ],
                    ),
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
                  if (!isWide) SizedBox(width: 30),
                  const Text(
                    'Hisabat',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 1.5,
              children: [
                Square(
                  title: 'اليومية',
                  color: const Color(0xFF4A958D),
                  icon: Icons.calendar_today,
                ),
                Square(
                  title: 'الذمم',
                  color: const Color(0xFF63CCCA),
                  icon: Icons.account_balance,
                ),
                Square(
                  title: 'الورشة',
                  color: const Color(0xFF5DA399),
                  icon: Icons.build,
                ),
                Square(
                  title: 'الخزينة',
                  color: const Color(0xFF42858C),
                  icon: Icons.business,
                ),
                Square(
                  title: 'معلومات الزبائن',
                  color: const Color(0xFF42858C),
                  icon: Icons.info,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
