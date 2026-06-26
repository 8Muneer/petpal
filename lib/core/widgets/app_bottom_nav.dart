import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petpal/core/theme/app_theme.dart';

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<AppNavItem> items;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pillAnim;
  int _fromIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pillAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _fromIndex = oldWidget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final systemBottom = MediaQuery.of(context).padding.bottom;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final n = widget.items.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 12 + systemBottom),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.prussianBlue3.withValues(alpha: 0.13),
              blurRadius: 36,
              spreadRadius: -4,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.09),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemWidth = totalWidth / n;
                final clampedFrom = _fromIndex.clamp(0, n - 1);
                final clampedTo = widget.currentIndex.clamp(0, n - 1);
                final effectiveFrom =
                    isRtl ? (n - 1 - clampedFrom) : clampedFrom;
                final effectiveTo =
                    isRtl ? (n - 1 - clampedTo) : clampedTo;

                return Stack(
                  children: [
                    // ── Glow layer behind pill ─────────────────────────────
                    AnimatedBuilder(
                      animation: _pillAnim,
                      builder: (context, _) {
                        final x = Tween<double>(
                          begin: effectiveFrom * itemWidth,
                          end: effectiveTo * itemWidth,
                        ).evaluate(_pillAnim);
                        return Positioned(
                          left: x + 4,
                          top: 4,
                          width: itemWidth - 8,
                          height: 64,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sapphire.withValues(alpha: 0.30),
                                  blurRadius: 22,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // ── Sliding gradient pill ──────────────────────────────
                    AnimatedBuilder(
                      animation: _pillAnim,
                      builder: (context, child) {
                        final x = Tween<double>(
                          begin: effectiveFrom * itemWidth,
                          end: effectiveTo * itemWidth,
                        ).evaluate(_pillAnim);
                        return Positioned(
                          left: x + 8,
                          top: 8,
                          width: itemWidth - 16,
                          height: 56,
                          child: child!,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.velvetGradient,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        // Subtle inner top-highlight
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ── Nav items ──────────────────────────────────────────
                    Row(
                      children: List.generate(n, (i) {
                        return _NavItem(
                          item: widget.items[i],
                          isActive: i == widget.currentIndex,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onChanged(i);
                          },
                          itemWidth: itemWidth,
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final AppNavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final double itemWidth;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.18 : 1.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      key: ValueKey(isActive),
                      size: 21,
                      color: isActive ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Label ─────────────────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : AppColors.textMuted.withValues(alpha: 0.65),
                letterSpacing: isActive ? 0.3 : 0,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
