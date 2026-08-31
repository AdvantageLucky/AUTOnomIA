import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Aviso de privacidad -- se abre desde Ajustes. Texto estático, sin
/// ViewModel: no hay nada que cargar ni que cambie en tiempo de ejecución.
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.t(context, 'privacy_policy'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryOrange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.t(context, 'privacy_policy_draft_notice'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textDimmed : const Color(0xFF8A8BA8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.t(context, 'privacy_policy_body'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
