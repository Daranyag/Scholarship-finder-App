import 'package:flutter/material.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String text;

  const StatusBadge({
    super.key,
    required this.status,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'READY':
      case 'VERIFIED':
      case 'ELIGIBLE':
      case '✓ MATCHED':
      case 'UPLOADED':
        bgColor = AppTheme.success.withOpacity(0.1);
        textColor = AppTheme.success;
        icon = Icons.check_circle;
        break;
      case 'READY_WITH_VERIFICATION':
      case 'NEEDS_VERIFICATION':
      case '⚠ NEEDS VERIFICATION':
      case 'WARNING':
        bgColor = AppTheme.warning.withOpacity(0.1);
        textColor = AppTheme.warning;
        icon = Icons.warning;
        break;
      case 'MISSING_REQUIRED_DOCUMENTS':
      case 'NOT_READY':
      case 'NOT_ELIGIBLE':
      case '❌ DOES NOT MATCH':
      case 'ERROR':
      case 'MISSING':
        bgColor = AppTheme.error.withOpacity(0.1);
        textColor = AppTheme.error;
        icon = Icons.cancel;
        break;
      case 'INFO':
      case 'ⓘ MORE INFORMATION REQUIRED':
      default:
        bgColor = AppTheme.info.withOpacity(0.1);
        textColor = AppTheme.info;
        icon = Icons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
