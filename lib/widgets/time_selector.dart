import 'package:flutter/material.dart';

class TimeSelector extends StatelessWidget {
  final String label;
  final TimeOfDay? initialTime;
  final Function(TimeOfDay?) onTimeSelected;

  const TimeSelector({
    Key? key,
    required this.label,
    required this.onTimeSelected,
    this.initialTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: initialTime ?? TimeOfDay.now(),
        );
        onTimeSelected(selectedTime);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          initialTime != null
              ? '${initialTime!.hour}:${initialTime!.minute.toString().padLeft(2, '0')}'
              : 'Bir saat seçin',
        ),
      ),
    );
  }
}
