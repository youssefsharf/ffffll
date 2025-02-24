import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart'; // استيراد ValueNotifier
import '../widgets/square.dart';

class PersistentValueNotifier<T> extends ValueNotifier<T> {
  final String key;

  PersistentValueNotifier(this.key, T defaultValue) : super(defaultValue) {
    _loadValue();
  }

  Future<void> _loadValue() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      if (T == double) {
        value = prefs.getDouble(key) as T;
      } else if (T == int) {
        value = prefs.getInt(key) as T;
      } else if (T == bool) {
        value = prefs.getBool(key) as T;
      } else if (T == String) {
        value = prefs.getString(key) as T;
      }
    }
  }

  @override
  set value(T newValue) {
    super.value = newValue;
    _saveValue(newValue);
  }

  Future<void> _saveValue(T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }
}

final totalForUsNotifier = PersistentValueNotifier<double>('totalForUs', 0.0);
final totalForHimNotifier = PersistentValueNotifier<double>('totalForHim', 0.0);
final cumulativeGoldForUsNotifier = PersistentValueNotifier<double>('cumulativeGoldForUs', 0.0);
final cumulativeGoldForHimNotifier = PersistentValueNotifier<double>('cumulativeGoldForHim', 0.0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await totalForUsNotifier._loadValue();
  await totalForHimNotifier._loadValue();
  await cumulativeGoldForUsNotifier._loadValue();
  await cumulativeGoldForHimNotifier._loadValue();
  runApp(MyApp());
}

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
              )],
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
                        )
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