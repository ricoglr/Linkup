import 'package:flutter/material.dart';

class AnimatedTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Function(String?) onSaved;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType keyboardType;
  final String? initialValue;

  const AnimatedTextField({
    Key? key,
    required this.label,
    required this.icon,
    required this.onSaved,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.initialValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: InputBorder.none,
          ),
          maxLines: maxLines,
          onSaved: onSaved,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
        ),
      ),
    );
  }
}
