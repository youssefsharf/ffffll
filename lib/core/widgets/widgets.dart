import 'package:flutter/material.dart';

/// Builds a customizable text field.
Widget buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

Widget buildCenteredText(String text, {double? width}) {
  return Container(
    width: width, // عرض اختياري
    alignment: Alignment.center, // توسيط النص
    child: Text(
      text,
      style: const TextStyle(fontSize: 16),
    ),
  );
}

/// Builds a customizable action button.
