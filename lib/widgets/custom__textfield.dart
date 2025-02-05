import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final bool obsureText;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Function(String?)? onSaved;
  final IconData? icon; // Yeni eklendi
  final TextInputType? keyboardType; // Yeni eklendi

  const CustomTextField({
    super.key,
    required this.labelText,
    required this.hintText,
    this.obsureText = false,
    this.controller,
    this.suffixIcon,
    this.validator,
    this.onSaved,
    this.icon, // Yeni eklendi
    this.keyboardType, // Yeni eklendi
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obsureText,
      validator: validator,
      onSaved: onSaved,
      keyboardType: keyboardType, // Yeni eklendi
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
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.grey.shade600)
            : null, // Yeni eklendi
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
