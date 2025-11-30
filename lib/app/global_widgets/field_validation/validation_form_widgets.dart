import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/values/app_colors.dart';

// Custom Text Input Formatter for Name Fields (Only Letters + Auto Capitalize)
class NameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only letters and spaces
    String filteredText = newValue.text.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
    
    // Auto capitalize first letter of each word
    String capitalizedText = filteredText
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
    
    return TextEditingValue(
      text: capitalizedText,
      selection: TextSelection.collapsed(offset: capitalizedText.length),
    );
  }
}

// Custom Text Input Formatter for Tamil Text
class TamilInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow Tamil Unicode range (U+0B80 to U+0BFF) and spaces
    String filteredText = newValue.text.replaceAll(RegExp(r'[^\u0B80-\u0BFF\s]'), '');
    
    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}

// Custom Text Input Formatter for Phone Numbers
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits and limit to 10 digits
    String filteredText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (filteredText.length > 10) {
      filteredText = filteredText.substring(0, 10);
    }
    
    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}

// Validated Name Text Field Widget
class ValidatedNameTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final String? Function(String?)? additionalValidator;

  const ValidatedNameTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.iconColor = kPrimaryColor,
    this.additionalValidator,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      inputFormatters: [NameInputFormatter()],
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (value.trim().length < 2) {
          return '$label must be at least 2 characters';
        }
        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
          return '$label can only contain letters';
        }
        return additionalValidator?.call(value);
      },
    );
  }
}

// Validated Tamil Text Field Widget
class ValidatedTamilTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final String? Function(String?)? additionalValidator;

  const ValidatedTamilTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.iconColor = kPrimaryColor,
    this.additionalValidator,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      inputFormatters: [TamilInputFormatter()],
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        hintText: 'தமிழில் தட்டச்சு செய்யவும்',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        hintStyle: TextStyle(color: kSecondaryColor.withOpacity(0.6)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (value.trim().length < 2) {
          return '$label must be at least 2 characters';
        }
        // Check if the text contains Tamil characters
        if (!RegExp(r'[\u0B80-\u0BFF\s]+$').hasMatch(value.trim())) {
          return '$label must contain only Tamil characters';
        }
        return additionalValidator?.call(value);
      },
    );
  }
}

// Validated Phone Number Text Field Widget
class ValidatedPhoneTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final String? Function(String?)? additionalValidator;

  const ValidatedPhoneTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.iconColor = kPrimaryColor,
    this.additionalValidator,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      inputFormatters: [PhoneInputFormatter()],
      keyboardType: TextInputType.phone,
      maxLength: 10,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        hintText: '9876543210',
        counterText: '', // Hide the counter
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        hintStyle: TextStyle(color: kSecondaryColor.withOpacity(0.6)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        if (value.length != 10) {
          return '$label must be exactly 10 digits';
        }
        if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
          return 'Enter a valid Indian mobile number';
        }
        return additionalValidator?.call(value);
      },
    );
  }
}

// Validated Date Field Widget with dd MMM yyyy format
class ValidatedDateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String? Function(String?)? additionalValidator;

  const ValidatedDateField({
    required this.label,
    required this.controller,
    required this.onTap,
    this.icon = Icons.date_range,
    this.iconColor = kPrimaryColor,
    this.additionalValidator,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        hintText: 'DD MMM YYYY (e.g., 15 Jan 2024)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        hintStyle: TextStyle(color: kSecondaryColor.withOpacity(0.6)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        
        try {
          // Try to parse the date to ensure it's valid
          DateFormat('dd MMM yyyy').parse(value);
          return additionalValidator?.call(value);
        } catch (e) {
          return 'Please select a valid date';
        }
      },
    );
  }
}

// Helper function to format date to dd MMM yyyy
String formatDateToDDMMMYYYY(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

// Helper function to show date picker and format result
Future<void> showFormattedDatePicker({
  required BuildContext context,
  required TextEditingController controller,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(1950),
    lastDate: lastDate ?? DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimaryColor,
            onPrimary: kLightColor,
            surface: kLightColor,
            onSurface: kSecondaryColor,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    controller.text = formatDateToDDMMMYYYY(picked);
  }
}

// Validated Dropdown Widget
class ValidatedDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final IconData icon;
  final Color iconColor;
  final String Function(T) itemLabel;
  final String? Function(T?)? validator;

  const ValidatedDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
    required this.itemLabel,
    this.iconColor = kPrimaryColor,
    this.validator,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item)),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: kSecondaryColor),
        ),
        labelStyle: const TextStyle(color: kSecondaryColor),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null) {
          return 'Please select $label';
        }
        return validator?.call(value);
      },
    );
  }
}