import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// Adaptive bottom tab bar.
///
/// **Light mode** — iOS-style floating white pill:
///   • White background, single soft shadow
///   • Active tab: filled accent circle behind the icon
///   • Label shown only for the active tab (fades in)
///   • No glass blur, no borders
///
/// **Dark mode** — original frosted glass pill (unchanged)
class AppTabBar extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.height = 64,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<AppTabItem> items;
  final double height;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillCtrl;
  late Animation<double> _pillPos;
  double _prevFraction = 0;

  @override
  void initState() {
    super.initState();
    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final count = widget.items.length;
    _prevFraction =
        count > 1 ? widget.selectedIndex / (count - 1) : 0;
    _pillPos = AlwaysStoppedAnimation(_prevFraction);
  }

  @override
  void didUpdateWidget(AppTabBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      final count = widget.items.length;
      final targetFraction =
          count > 1 ? widget.selectedIndex / (count - 1) : 0.0;
      _pillPos = Tween<double>(
        begin: _prevFraction,
        end: targetFraction,
      ).animate(
        CurvedAnimation(parent: _pillCtrl, curve: Curves.easeOutCubic),
      );
      _prevFraction = targetFraction;
      _pillCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? _LightTabBar(
            selectedIndex: widget.selectedIndex,
            onTap: widget.onTap,
            items: widget.items,
            height: widget.height,
            pillPos: _pillPos,
          )
        : _DarkTabBar(
            selectedIndex: widget.selectedIndex,
            onTap: widget.onTap,
            items: widget.items,
            height: widget.height,
            pillPos: _pillPos,
          );
  }
}

// ── Light mode tab bar ────────────────────────────────────────────────────────

class _LightTabBar extends StatelessWidget {
  const _LightTabBar({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    required this.height,
    required this.pillPos,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<AppTabItem> items;
  final double height;
  final Animation<double> pillPos;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final count = items.length;
    final pillDuration = AppMotion.duration(
      context,
      normalMs: 220,
      reducedMs: 0,
    );

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final resolvedHeight = height + ((textScale - 1) * 16).clamp(0.0, 12.0);

    return Container(
      height: resolvedHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final itemWidth = totalWidth / count;

            return AnimatedBuilder(
              animation: pillPos,
              builder: (context, _) {
                final pillLeft = pillPos.value * (totalWidth - itemWidth);

                return Stack(
                  children: [
                    // ── Active indicator: filled accent circle ────────────
                    AnimatedPositioned(
                      duration: pillDuration,
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Center(
                        child: Container(
                          width: 52,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                      ),
                    ),
                    // ── Tab buttons ───────────────────────────────────────
                    Row(
                      children: List.generate(count, (i) {
                        final item = items[i];
                        final selected = i == selectedIndex;
                        return Expanded(
                          child: _LightTabItem(
                            item: item,
                            selected: selected,
                            accent: accent,
                            onTap: () {
                              AppHaptics.lightImpact();
                              onTap(i);
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LightTabItem extends StatelessWidget {
  const _LightTabItem({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final AppTabItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? accent : const Color(0xFFC7C7CC);
    final itemDuration = AppMotion.duration(
      context,
      normalMs: 160,
      reducedMs: 0,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: itemDuration,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              selected ? item.selectedIcon : item.icon,
              key: ValueKey(selected),
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedOpacity(
            duration: itemDuration,
            opacity: selected ? 1.0 : 0.0,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accent,
                letterSpacing: -0.1,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark mode tab bar (original frosted glass pill, unchanged) ────────────────

class _DarkTabBar extends StatelessWidget {
  const _DarkTabBar({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    required this.height,
    required this.pillPos,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<AppTabItem> items;
  final double height;
  final Animation<double> pillPos;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final mutedColor = AppColors.textMuted;
    final count = items.length;
    final pillDuration = AppMotion.duration(
      context,
      normalMs: 180,
      reducedMs: 0,
    );
    final itemDuration = AppMotion.duration(
      context,
      normalMs: 140,
      reducedMs: 0,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final resolvedHeight = height + ((textScale - 1) * 18).clamp(0.0, 14.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16243D).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox(
          height: resolvedHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final itemWidth = totalWidth / count;

              return AnimatedBuilder(
                animation: pillPos,
                builder: (context, _) {
                  final pillLeft = pillPos.value * (totalWidth - itemWidth);
                  return Stack(
                    children: [
                      // Sliding pill background
                      Positioned(
                        left: pillLeft + 3,
                        top: 3,
                        bottom: 3,
                        width: itemWidth - 6,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.24),
                                accent.withValues(alpha: 0.12),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.34),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Tab buttons
                      Row(
                        children: List.generate(count, (i) {
                          final item = items[i];
                          final selected = i == selectedIndex;
                          final iconColor =
                              selected ? accent : mutedColor;
                          return Expanded(
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              onTap: () {
                                AppHaptics.lightImpact();
                                onTap(i);
                              },
                              child: AnimatedScale(
                                scale: selected ? 1.0 : 0.95,
                                duration: itemDuration,
                                curve: Curves.easeOutBack,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: itemDuration,
                                          child: Icon(
                                            selected
                                                ? item.selectedIcon
                                                : item.icon,
                                            key: ValueKey(selected),
                                            color: iconColor,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      height: 13,
                                      child: AnimatedOpacity(
                                        duration: itemDuration,
                                        opacity: selected ? 1 : 0,
                                        child: SizedBox(
                                          width: itemWidth - 8,
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: accent,
                                              height: 1.1,
                                              letterSpacing: -0.1,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Shared tab item definition ────────────────────────────────────────────────

class AppTabItem {
  const AppTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
