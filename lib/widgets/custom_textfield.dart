import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Function(String?)? onSaved;
  final Function(String)? onChanged;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.controller,
    this.suffixIcon,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 15,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey.shade600)
            : null,
        border: _buildBorder(),
        enabledBorder: _buildBorder(color: Colors.grey.shade300),
        focusedBorder: _buildBorder(color: Colors.grey.shade500),
      ),
    );
  }

  OutlineInputBorder _buildBorder({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: color ?? Colors.grey.shade300,
        width: 1,
      ),
    );
  }
}
