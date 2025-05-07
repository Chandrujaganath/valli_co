// lib/widgets/status_indicator.dart
import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    switch (status) {
      case 'On Time':
        indicatorColor = Colors.green;
        break;
      case 'Delayed':
        indicatorColor = Colors.red;
        break;
      default:
        indicatorColor = Colors.grey;
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(status, style: TextStyle(color: indicatorColor)),
      ],
    );
  }
}
