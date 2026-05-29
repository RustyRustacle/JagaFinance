import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.danger.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  (Color, Color, String) _statusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'FINALIZED':
      case 'CONFIRMED':
        return (const Color(0xFFD1FAE5), const Color(0xFF059669), 'Selesai');
      case 'PROCESSING':
        return (const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Diproses');
      case 'FAILED':
      case 'REJECTED':
      case 'VOID':
        return (const Color(0xFFFEE2E2), const Color(0xFFDC2626), 'Gagal');
      case 'UPLOADED':
        return (const Color(0xFFDBEAFE), const Color(0xFF2563EB), 'Terunggah');
      case 'DRAFT':
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), 'Draft');
      default:
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), status);
    }
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

class AmountText extends StatelessWidget {
  final double amount;
  final String currency;
  final bool showDecimal;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const AmountText({
    super.key,
    required this.amount,
    this.currency = 'IDR',
    this.showDecimal = false,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.color,
  });

  String _format(double n) {
    if (currency == 'IDR') {
      final formatter = NumberFormat.decimalPattern('id');
      return showDecimal ? formatter.format(n) : formatter.format(n.round());
    }
    final formatter = NumberFormat.decimalPattern('en');
    return showDecimal ? formatter.format(n) : formatter.format(n.round());
  }

  @override
  Widget build(BuildContext context) {
    final prefix = currency == 'IDR' ? 'Rp ' : '\$ ';
    return Text(
      '$prefix${_format(amount)}',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppTheme.textPrimary,
      ),
    );
  }
}
