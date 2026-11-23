import 'package:flutter/material.dart';

import '../services/role.dart';
import '../theme.dart';

/// Dos tarjetas para elegir cómo entrar: Remitente o Viajero.
class RoleSelector extends StatelessWidget {
  final AppRole value;
  final ValueChanged<AppRole> onChanged;
  final bool dark;
  const RoleSelector({super.key, required this.value, required this.onChanged, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in AppRole.values) ...[
          if (r != AppRole.values.first) const SizedBox(width: 12),
          Expanded(child: _RoleCard(role: r, selected: r == value, dark: dark, onTap: () => onChanged(r))),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final AppRole role;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  const _RoleCard({required this.role, required this.selected, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? null
        : (dark ? Colors.white.withValues(alpha: 0.06) : Colors.white);
    final border = selected ? AppColors.royal : (dark ? Colors.white.withValues(alpha: 0.16) : AppColors.line);
    final fg = selected || dark ? Colors.white : AppColors.navy;
    final sub = selected || dark ? Colors.white.withValues(alpha: 0.72) : AppColors.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: '${role.label}: ${role.tagline}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: bg,
            gradient: selected
                ? const LinearGradient(colors: [AppColors.royal, Color(0xFF1E4FD6)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: selected ? 2 : 1),
            boxShadow: selected ? [BoxShadow(color: AppColors.royal.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))] : null,
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white.withValues(alpha: 0.2) : (dark ? Colors.white.withValues(alpha: 0.08) : AppColors.skySoft),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(role.icon, color: selected || dark ? Colors.white : AppColors.royal, size: 22),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(role.label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16.5)),
                const SizedBox(height: 2),
                Text(role.tagline, style: TextStyle(color: sub, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
