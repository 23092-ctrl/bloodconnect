import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';
import '../../core/constants/app_colors.dart';

/// Barre compacte avec boutons langue (FR/EN) et thème clair/sombre.
/// [compact] = true → utilisé dans un AppBar actions (pas de padding externe).
class TopSettingsBar extends StatelessWidget {
  final bool compact;
  const TopSettingsBar({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final isDark = settings.isDark;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Toggle langue ────────────────────────────────────────────────
        _LangToggle(settings: settings),
        const SizedBox(width: 4),
        // ── Toggle thème ─────────────────────────────────────────────────
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              size: 22,
            ),
          ),
          tooltip: isDark ? 'Mode clair' : 'Mode sombre',
          onPressed: () => settings.toggleTheme(),
        ),
        if (!compact) const SizedBox(width: 4),
      ],
    );

    if (compact) return row;

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4),
      child: Align(alignment: Alignment.centerRight, child: row),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final SettingsController settings;
  const _LangToggle({required this.settings});

  @override
  Widget build(BuildContext context) {
    final current = settings.locale.languageCode;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['fr', 'en'].map((code) {
          final selected = current == code;
          return GestureDetector(
            onTap: () => settings.setLocale(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
