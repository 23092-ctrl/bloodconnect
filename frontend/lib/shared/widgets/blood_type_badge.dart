import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BloodTypeBadge extends StatelessWidget {
  final String bloodType;
  final bool large;

  const BloodTypeBadge({super.key, required this.bloodType, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.bloodTypes[bloodType] ?? AppColors.primary;
    final size = large ? 48.0 : 36.0;
    final fontSize = large ? 16.0 : 13.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          bloodType,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
