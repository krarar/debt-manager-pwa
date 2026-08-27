import 'package:flutter/material.dart';

class QistiBackground extends StatelessWidget {
  const QistiBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IgnorePointer(
      child: Opacity(
        opacity: isDark ? 0.10 : 0.08,
        child: Align(
          alignment: Alignment.centerRight,
          child: Transform.translate(
            offset: const Offset(40, 0),
            child: Image.asset(
              'assets/images/qisti_logo.png',
              width: 460,
              height: 460,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.account_balance_wallet_rounded,
                size: 260,
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
