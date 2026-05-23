import 'dart:math' show min;
import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petpal/core/theme/app_theme.dart';

// ─── Data ──────────────────────────────────────────────────────────────────

class ProfileMenuItem {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const ProfileMenuItem({
    required this.icon,
    this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}

// ─── LuxuryHero ────────────────────────────────────────────────────────────

class LuxuryHero extends StatelessWidget {
  final String imageUrl;
  final Widget searchBar;
  final ScrollController scrollController;
  final String? profileImageUrl;
  final String? userName;
  final List<ProfileMenuItem> profileMenuItems;

  const LuxuryHero({
    super.key,
    required this.imageUrl,
    required this.searchBar,
    required this.scrollController,
    this.profileImageUrl,
    this.userName,
    this.profileMenuItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 420,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: scrollController,
                builder: (context, _) {
                  double offset = 0;
                  if (scrollController.hasClients) {
                    offset = scrollController.offset * 0.3;
                  }
                  return Stack(children: [
                    Positioned(
                      top: -offset, left: 0, right: 0, height: 630,
                      child: imageUrl.startsWith('assets/')
                          ? Image.asset(imageUrl, fit: BoxFit.cover)
                          : Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.transparent,
                              AppColors.surface.withValues(alpha: 0.9),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ]);
                },
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: AppSpacing.marginPage,
              right: AppSpacing.marginPage,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ProfileAvatar(
                    imageUrl: profileImageUrl,
                    name: userName,
                    menuItems: profileMenuItems,
                  ),
                  Text('PetPal',
                      style: AppTextStyles.headlineLg.copyWith(
                          color: Colors.white, fontStyle: FontStyle.italic)),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30), width: 1),
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: AppSpacing.marginPage,
              left: AppSpacing.marginPage,
              right: AppSpacing.marginPage,
              child: searchBar,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Avatar ─────────────────────────────────────────────────────────

class _ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? name;
  final List<ProfileMenuItem> menuItems;
  const _ProfileAvatar({this.imageUrl, this.name, required this.menuItems});

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlay;
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _overlay?.remove();
    _press.dispose();
    super.dispose();
  }

  void _open() {
    if (_overlay != null) return;
    HapticFeedback.lightImpact();
    _overlay = OverlayEntry(builder: (_) => _SideMenu(
      items: widget.menuItems,
      imageUrl: widget.imageUrl,
      name: widget.name,
      onDismiss: _close,
    ));
    Overlay.of(context).insert(_overlay!);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
  }

  String get _initial {
    final n = widget.name?.trim() ?? '';
    return n.isNotEmpty ? n.characters.first.toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.imageUrl?.isNotEmpty == true;
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) { _press.reverse(); _open(); },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.55),
                  blurRadius: 0, spreadRadius: 2),
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.50),
                  blurRadius: 14, offset: const Offset(0, 3)),
            ],
          ),
          child: ClipOval(
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _InitialCircle(initial: _initial),
                    errorWidget: (_, __, ___) => _InitialCircle(initial: _initial),
                  )
                : _InitialCircle(initial: _initial),
          ),
        ),
      ),
    );
  }
}

class _InitialCircle extends StatelessWidget {
  final String initial;
  const _InitialCircle({required this.initial});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: AppColors.velvetGradient),
    child: Center(
      child: Text(initial,
          style: const TextStyle(
              color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w800, height: 1)),
    ),
  );
}

// ─── Side Menu ─────────────────────────────────────────────────────────────

class _SideMenu extends StatefulWidget {
  final List<ProfileMenuItem> items;
  final String? imageUrl;
  final String? name;
  final VoidCallback onDismiss;
  const _SideMenu(
      {required this.items, this.imageUrl, this.name, required this.onDismiss});

  @override
  State<_SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<_SideMenu> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;

  late final Animation<double> _barrierFade;
  late final Animation<Offset> _panelSlide;
  late final Animation<double> _panelFade;
  late final List<Animation<double>> _itemAnims;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));

    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _barrierFade = CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut));

    _panelSlide = Tween<Offset>(
            begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _enter,
            curve: const Interval(0.0, 0.78,
                curve: Cubic(0.16, 1, 0.3, 1)))); // easeOutExpo

    _panelFade = CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut));

    _itemAnims = List.generate(
      widget.items.length,
      (i) => CurvedAnimation(
        parent: _enter,
        curve: Interval(0.40 + i * 0.09, 0.82 + i * 0.09,
            curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _enter.forward();
    _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _pulse.stop();
    _enter.duration = const Duration(milliseconds: 240);
    await _enter.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final panelW = min(300.0, screen.width * 0.82);
    final top = MediaQuery.of(context).padding.top;

    return Material(
      type: MaterialType.transparency,
      child: Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          // ── Blurred barrier ─────────────────────────────────────────
          Positioned.fill(
            child: FadeTransition(
              opacity: _barrierFade.drive(Tween(begin: 0.0, end: 1.0)),
              child: GestureDetector(
                onTap: _dismiss,
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                      color: AppColors.prussianBlue3.withValues(alpha: 0.45)),
                ),
              ),
            ),
          ),

          // ── Panel ───────────────────────────────────────────────────
          Positioned(
            top: 0, right: 0, bottom: 0,
            width: panelW,
            child: FadeTransition(
              opacity: _panelFade,
              child: SlideTransition(
                position: _panelSlide,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    bottomLeft: Radius.circular(32),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.97),
                            Colors.white.withValues(alpha: 0.93),
                            AppColors.surface.withValues(alpha: 0.95),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.prussianBlue3
                                .withValues(alpha: 0.30),
                            blurRadius: 60,
                            offset: const Offset(-16, 0),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: AppColors.prussianBlue3
                                .withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(-4, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildHeader(top, panelW),
                          const SizedBox(height: 8),
                          Expanded(child: _buildItems()),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(double statusBarH, double panelW) {
    final hasPhoto = widget.imageUrl?.isNotEmpty == true;
    final name = widget.name?.trim() ?? '';

    return SizedBox(
      width: panelW,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gradient base
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.prussianBlue2,
                    AppColors.regalNavy,
                    AppColors.sapphire,
                  ],
                  stops: [0.0, 0.52, 1.0],
                ),
              ),
            ),
          ),

          // Decorative large circle — top-right
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Decorative smaller circle — bottom-left
          Positioned(
            bottom: -30, left: -20,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.smartBlue.withValues(alpha: 0.18),
              ),
            ),
          ),

          // Fine grid shimmer
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // Content
          Padding(
            padding:
                EdgeInsets.fromLTRB(22, statusBarH + 14, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Avatar with pulsing glow
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white
                                    .withValues(alpha: _pulseAnim.value * 0.28),
                                blurRadius: 24,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        // White ring
                        Container(
                          width: 80, height: 80,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white
                                    .withValues(alpha: 0.9),
                                Colors.white
                                    .withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: child,
                        ),
                      ],
                    );
                  },
                  child: ClipOval(
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _HeaderInitial(name: name),
                          )
                        : _HeaderInitial(name: name),
                  ),
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  name.isNotEmpty ? name : 'משתמש',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    height: 1.1,
                    shadows: [
                      Shadow(
                          blurRadius: 12,
                          color: Colors.black38,
                          offset: Offset(0, 2))
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                // Tag chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets_rounded,
                          color: Colors.white, size: 11),
                      SizedBox(width: 5),
                      Text('PetPal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Items ─────────────────────────────────────────────────────────────────

  Widget _buildItems() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: List.generate(widget.items.length, (i) {
        final item = widget.items[i];
        final color = item.iconColor ?? AppColors.primary;
        return _AnimatedItem(
          animation: _itemAnims[i],
          child: _MenuTile(
            item: item,
            accentColor: color,
            onTap: () async {
              HapticFeedback.selectionClick();
              await _dismiss();
              item.onTap();
            },
          ),
        );
      }),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
        child: Row(
          children: [
            Container(
              width: 26, height: 26,
              decoration: const BoxDecoration(
                  gradient: AppColors.velvetGradient,
                  shape: BoxShape.circle),
              child: const Icon(Icons.pets_rounded,
                  color: Colors.white, size: 13),
            ),
            const SizedBox(width: 8),
            Text('PetPal v1.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Tile ──────────────────────────────────────────────────────────────

class _MenuTile extends StatefulWidget {
  final ProfileMenuItem item;
  final Color accentColor;
  final VoidCallback onTap;
  const _MenuTile(
      {required this.item, required this.accentColor, required this.onTap});

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tap;
  late final Animation<double> _scale;
  late final Animation<Color?> _bg;

  @override
  void initState() {
    super.initState();
    _tap = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _tap, curve: Curves.easeInOut));
    _bg = ColorTween(
      begin: Colors.transparent,
      end: widget.accentColor.withValues(alpha: 0.07),
    ).animate(CurvedAnimation(parent: _tap, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tap.forward(),
      onTapUp: (_) { _tap.reverse(); widget.onTap(); },
      onTapCancel: () => _tap.reverse(),
      child: AnimatedBuilder(
        animation: _tap,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: _bg.value,
              borderRadius: BorderRadius.circular(18),
            ),
            child: child,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.6),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.pureWhite,
                AppColors.surface,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.prussianBlue3.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gradient icon container
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accentColor,
                      widget.accentColor.withValues(alpha: 0.70),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.38),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.item.icon,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.1,
                        )),
                    if (widget.item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.item.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted
                                .withValues(alpha: 0.8),
                          )),
                    ],
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.chevron_left_rounded,
                    size: 18,
                    color: AppColors.textMuted.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated item wrapper ──────────────────────────────────────────────────

class _AnimatedItem extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _AnimatedItem({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0.08, 0), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }
}

// ─── Header Initials ────────────────────────────────────────────────────────

class _HeaderInitial extends StatelessWidget {
  final String name;
  const _HeaderInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.velvetGradient),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white, fontSize: 26,
              fontWeight: FontWeight.w900, height: 1),
        ),
      ),
    );
  }
}

// ─── Dot Grid Painter ────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    const r = 1.2;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}
