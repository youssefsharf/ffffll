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

/// Builds a centered text widget with a given width.
Widget buildCenteredText(String text, {double width = 100}) {
  return SizedBox(
    width: width,
    child: Center(child: Text(text)),
  );
}

/// Builds a customizable action button.
