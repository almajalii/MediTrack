import 'package:flutter/material.dart';

class MyTextField {

  Widget buildTextField(
      String label,
      TextEditingController controller, {
        IconData? prefixIcon,
        String? Function(String?)? validator,
        bool obscureText = false,
        String? errorText,
        void Function(String)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Builder(
          builder: (context) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return TextFormField(
              controller: controller,
              obscureText: obscureText,
              validator: validator,
              onChanged: onChanged,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: label,
                errorText: errorText,
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
                fillColor: isDarkMode ? Color(0xFF2C2C2C) : Color(0xFFF2F4F8),
                filled: true,
                prefixIcon: prefixIcon != null
                    ? Icon(
                  prefixIcon,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Color(0xFF3C3C3C) : Color(0xFFC8D1DC),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Color(0xFF3C3C3C) : Color(0xFFC8D1DC),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Color(0xFF00B9E4) : Color(0xFF00B9E4),
                    width: 2,
                  ),
                ),
              ),
            );
          }
      ),
    );
  }
}