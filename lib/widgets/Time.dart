import 'package:flutter/material.dart';
import 'package:meditrack/style/colors.dart';

class ExpiryDatePicker extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String dateFormat;
  final void Function(DateTime)? onDateChanged;
  final DateTime? initialDate;

  const ExpiryDatePicker({
    Key? key,
    required this.controller,
    this.labelText = 'Expiry Date',
    this.dateFormat = 'yyyy-mm-dd',
    this.onDateChanged,
    this.initialDate,
  }) : super(key: key);

  @override
  _ExpiryDatePickerState createState() => _ExpiryDatePickerState();
}

class _ExpiryDatePickerState extends State<ExpiryDatePicker> {
  DateTime? selectedDate;

  String formatDate(DateTime date) {
    switch (widget.dateFormat) {
      case 'dd-mm-yyyy':
        return '${date.day.toString().padLeft(2, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.year}';
      case 'yyyy-mm-dd':
      default:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _openPicker() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? widget.initialDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    primaryContainer: AppColors.primary,
                    onPrimaryContainer: Colors.white,
                    surface: const Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                    surfaceContainerHigh: const Color(0xFF1E1E1E),
                    secondaryContainer: AppColors.primary.withValues(alpha: 0.2),
                    onSecondaryContainer: AppColors.primary,
                    outline: const Color(0xFF3C3C3C),
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    primaryContainer: AppColors.primary,
                    onPrimaryContainer: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.darkBlue,
                    surfaceContainerHigh: Colors.white,
                    secondaryContainer: AppColors.primary.withValues(alpha: 0.12),
                    onSecondaryContainer: AppColors.primary,
                    outline: const Color(0xFFC8D1DC),
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor:
                  isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        widget.controller.text = formatDate(picked);
        widget.onDateChanged?.call(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDarkMode ? const Color(0xFF3C3C3C) : const Color(0xFFC8D1DC);
    final hasValue = widget.controller.text.isNotEmpty;

    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      onTap: _openPicker,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
        hintText: 'Tap to select a date',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightGray,
        prefixIcon: Icon(
          Icons.calendar_month_outlined,
          color: hasValue ? AppColors.primary : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          size: 20,
        ),
        suffixIcon: hasValue
            ? Icon(Icons.check_circle, color: AppColors.success, size: 18)
            : Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasValue ? AppColors.primary.withValues(alpha: 0.5) : borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
