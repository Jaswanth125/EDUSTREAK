import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;
  final FontWeight textWeight;
  final double spacing;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showText = false,
    this.textColor,
    this.textWeight = FontWeight.w700,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/edustreak_logo.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          'ES',
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (!showText) {
      return logo;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        SizedBox(width: spacing),
        Text(
          'EduStreak',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: textWeight,
            color: textColor ?? AppTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
