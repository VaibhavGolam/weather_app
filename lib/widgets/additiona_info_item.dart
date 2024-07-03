import 'package:flutter/material.dart';

class AddtionalInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const AddtionalInfoItem(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
          ),
          const SizedBox(
            height: 4,
          ),
          Text(label),
          const SizedBox(
            height: 4,
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 4,
          ),
        ],
      ),
    );
  }
}
