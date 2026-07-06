import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/pets/domain/entities/pet.dart';
import 'package:petpal/features/pets/presentation/providers/pets_provider.dart';

// My Pets — standalone screen (navigated to from side menu)
// ═══════════════════════════════════════════════════════════════════════════

class MyPetsScreen extends ConsumerWidget {
  const MyPetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text('החיות שלי', style: AppTextStyles.headlineSm),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.divider),
          ),
        ),
        body: const _MyPetsTab(standalone: true),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// החיות שלי Tab
// ═══════════════════════════════════════════════════════════════════════════

class _MyPetsTab extends ConsumerWidget {
  final bool standalone;
  const _MyPetsTab({this.standalone = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(userPetsProvider);

    return petsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (pets) {
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewPadding.bottom +
                  (standalone ? 16 : 84)),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.70,
          ),
          itemCount: pets.length + 1,
          itemBuilder: (context, i) {
            if (i == pets.length) {
              return _AddPetCard(
                onTap: () => _showPetForm(context, ref, null),
              );
            }
            return _PetCard(
              pet: pets[i],
              onTap: () => _showPetDetail(context, ref, pets[i]),
            );
          },
        );
      },
    );
  }

  void _showPetForm(BuildContext context, WidgetRef ref, Pet? pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _PetFormSheet(ref: ref, pet: pet),
      ),
    );
  }

  void _showPetDetail(BuildContext context, WidgetRef ref, Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (sheetCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: _PetDetailSheet(
          pet: pet,
          ref: ref,
          onEdit: () {
            Navigator.of(sheetCtx).pop();
            _showPetForm(context, ref, pet);
          },
        ),
      ),
    );
  }
}

// ─── Pet Card ──────────────────────────────────────────────────────────────

class _PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  const _PetCard({required this.pet, this.onTap});

  Color get _typeColor {
    return switch (pet.type) {
      'כלב' => AppColors.smartBlue,
      'חתול' => AppColors.sapphire,
      'ציפור' => const Color(0xFF2E7D32),
      'ארנב' => const Color(0xFF6A1B9A),
      _ => AppColors.blueSlate,
    };
  }

  IconData get _typeIcon {
    return switch (pet.type) {
      'כלב' => Icons.pets_rounded,
      'חתול' => Icons.catching_pokemon_rounded,
      'ציפור' => Icons.flutter_dash_rounded,
      _ => Icons.cruelty_free_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.prussianBlue3.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo ────────────────────────────────────────────────────
            Expanded(
              flex: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: pet.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _PetPlaceholder(color: color),
                          errorWidget: (_, __, ___) =>
                              _PetPlaceholder(color: color),
                        )
                      : _PetPlaceholder(color: color),

                  // Bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Gender badge — top left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _PhotoBadge(
                      label: pet.gender,
                      bgColor: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),

                  // Vaccinated badge — top right
                  if (pet.isVaccinated)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _PhotoBadge(
                        label: 'מחוסן',
                        icon: Icons.verified_rounded,
                        bgColor:
                            AppColors.success.withValues(alpha: 0.85),
                      ),
                    ),

                  // Type badge — bottom right (on gradient)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _PhotoBadge(
                      label: pet.type,
                      icon: _typeIcon,
                      bgColor: color,
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (pet.breed.isNotEmpty)
                      Text(
                        pet.breed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (pet.ageYears != null || pet.weightKg != null)
                      Row(
                        children: [
                          if (pet.ageYears != null) ...[
                            _InfoChip(
                              icon: Icons.cake_outlined,
                              label: '${pet.ageYears} שנ\'',
                            ),
                            if (pet.weightKg != null) const SizedBox(width: 5),
                          ],
                          if (pet.weightKg != null)
                            _InfoChip(
                              icon: Icons.monitor_weight_outlined,
                              label: '${_fmtWeight(pet.weightKg!)} ק"ג',
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtWeight(double w) =>
      w == w.truncateToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
}

class _PetPlaceholder extends StatelessWidget {
  final Color color;
  const _PetPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.pets_rounded,
            size: 48, color: color.withValues(alpha: 0.40)),
      ),
    );
  }
}

// ─── Photo Badge ───────────────────────────────────────────────────────────

class _PhotoBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color bgColor;
  const _PhotoBadge({required this.label, this.icon, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Pet Card ──────────────────────────────────────────────────────────

class _AddPetCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'הוסף חיה',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'כלב, חתול ועוד',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pet Detail Sheet ──────────────────────────────────────────────────────

class _PetDetailSheet extends StatefulWidget {
  final Pet pet;
  final WidgetRef ref;
  final VoidCallback onEdit;
  const _PetDetailSheet(
      {required this.pet, required this.ref, required this.onEdit});

  @override
  State<_PetDetailSheet> createState() => _PetDetailSheetState();
}

class _PetDetailSheetState extends State<_PetDetailSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  Pet get pet => widget.pet;
  WidgetRef get ref => widget.ref;
  VoidCallback get onEdit => widget.onEdit;

  Color get _typeColor => switch (pet.type) {
        'כלב' => AppColors.smartBlue,
        'חתול' => AppColors.sapphire,
        'ציפור' => const Color(0xFF2E7D32),
        'ארנב' => const Color(0xFF6A1B9A),
        _ => AppColors.blueSlate,
      };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _fade(Widget child, {required double start, required double end}) =>
      FadeTransition(
        opacity: CurvedAnimation(
            parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOut)),
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: _ctrl,
                      curve: Interval(start, end, curve: Curves.easeOutCubic))),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final color = _typeColor;

    return Container(
      height: screenH * 0.93,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Hero photo ────────────────────────────────────────────────
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: pet.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _PetPlaceholder(color: color),
                        errorWidget: (_, __, ___) =>
                            _PetPlaceholder(color: color),
                      )
                    : _PetPlaceholder(color: color),

                // Multi-stop gradient for drama
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0.0, 0.35, 0.62, 1.0],
                      ),
                    ),
                  ),
                ),

                // Handle bar (on top of photo)
                const Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 36,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                ),

                // Frosted close button
                Positioned(
                  top: 44,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),

                // Name + breed overlay
                Positioned(
                  bottom: 18,
                  right: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.1,
                          shadows: [
                            Shadow(
                                blurRadius: 16,
                                color: Colors.black54,
                                offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      if (pet.breed.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          pet.breed,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(blurRadius: 8, color: Colors.black45),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 22, 20, 28 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  _fade(
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _GlowBadge(
                          label: pet.type,
                          gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.70)]),
                        ),
                        _GlowBadge(
                          label: pet.gender,
                          gradient: const LinearGradient(colors: [
                            AppColors.blueSlate,
                            AppColors.twilightIndigo,
                          ]),
                        ),
                        if (pet.isVaccinated)
                          const _GlowBadge(
                            label: 'מחוסן',
                            icon: Icons.verified_rounded,
                            gradient: LinearGradient(colors: [
                              AppColors.success,
                              Color(0xFF2E9E69),
                            ]),
                          ),
                      ],
                    ),
                    start: 0.0,
                    end: 0.45,
                  ),

                  const SizedBox(height: 22),

                  // Stats grid
                  _fade(
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        _StatTile(
                          icon: Icons.cake_outlined,
                          iconColor: AppColors.smartBlue,
                          label: 'גיל',
                          value: pet.ageYears != null
                              ? '${pet.ageYears} שנים'
                              : 'לא ידוע',
                          hasValue: pet.ageYears != null,
                        ),
                        _StatTile(
                          icon: Icons.monitor_weight_outlined,
                          iconColor: AppColors.sapphire,
                          label: 'משקל',
                          value: pet.weightKg != null
                              ? '${_fmtW(pet.weightKg!)} ק"ג'
                              : 'לא ידוע',
                          hasValue: pet.weightKg != null,
                        ),
                        _StatTile(
                          icon: Icons.palette_outlined,
                          iconColor: AppColors.blueSlate,
                          label: 'צבע',
                          value: pet.color?.isNotEmpty == true
                              ? pet.color!
                              : 'לא ידוע',
                          hasValue: pet.color?.isNotEmpty == true,
                        ),
                        _StatTile(
                          icon: Icons.vaccines_rounded,
                          iconColor: pet.isVaccinated
                              ? AppColors.success
                              : AppColors.textMuted,
                          label: 'חיסונים',
                          value: pet.isVaccinated ? 'מחוסן ✓' : 'לא מחוסן',
                          hasValue: pet.isVaccinated,
                          valueColor:
                              pet.isVaccinated ? AppColors.success : null,
                        ),
                      ],
                    ),
                    start: 0.10,
                    end: 0.55,
                  ),

                  // Microchip card
                  if (pet.microchipId?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _fade(
                      _InfoTile(
                        icon: Icons.memory_rounded,
                        iconColor: AppColors.regalNavy,
                        label: 'מספר שבב',
                        value: pet.microchipId!,
                      ),
                      start: 0.20,
                      end: 0.60,
                    ),
                  ],

                  // Medical notes card
                  if (pet.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _fade(
                      _NotesTile(notes: pet.notes!),
                      start: 0.30,
                      end: 0.70,
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Primary action — Edit
                  _fade(
                    _PressableButton(
                      label: 'ערוך פרטים',
                      icon: Icons.edit_rounded,
                      gradient: AppColors.velvetGradient,
                      shadowColor: AppColors.primary.withValues(alpha: 0.45),
                      onTap: onEdit,
                    ),
                    start: 0.38,
                    end: 0.82,
                  ),

                  const SizedBox(height: 12),

                  // Destructive action — Delete
                  _fade(
                    Center(
                      child: GestureDetector(
                        onTap: () => _confirmDelete(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.20),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 16, color: AppColors.error),
                              SizedBox(width: 7),
                              Text('מחק חיה',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    start: 0.46,
                    end: 0.90,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('מחיקת ${pet.name}',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          content: const Text(
            'פעולה זו אינה ניתנת לביטול.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                Navigator.pop(context);
                await ref.read(petsNotifierProvider.notifier).deletePet(pet.id);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('מחק',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtW(double w) =>
      w == w.truncateToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
}

// ── Detail UI helpers ───────────────────────────────────────────────────────

class _GlowBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final LinearGradient gradient;
  const _GlowBadge({required this.label, this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.38),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              )),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool hasValue;
  final Color? valueColor;
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.hasValue,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final vColor =
        valueColor ?? (hasValue ? AppColors.textPrimary : AppColors.textMuted);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.prussianBlue3.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: vColor)),
              const SizedBox(height: 1),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.prussianBlue3.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesTile extends StatelessWidget {
  final String notes;
  const _NotesTile({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.prussianBlue3.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notes_rounded,
                    size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text('הערות רפואיות',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(notes,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.6)),
        ],
      ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;
  const _PressableButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.955)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 9),
                Text(widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pet Form Sheet (Add + Edit) ───────────────────────────────────────────

class _PetFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final Pet? pet; // null = add mode
  const _PetFormSheet({required this.ref, this.pet});

  @override
  State<_PetFormSheet> createState() => _PetFormSheetState();
}

class _PetFormSheetState extends State<_PetFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _microchipCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _weightCtrl;

  File? _imageFile;
  String? _existingImageUrl;
  late String _type;
  late String _gender;
  late bool _isVaccinated;
  bool _saving = false;

  bool get _isEdit => widget.pet != null;

  static const _types = ['כלב', 'חתול', 'ציפור', 'ארנב', 'אחר'];
  static const _genders = ['זכר', 'נקבה'];

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _breedCtrl = TextEditingController(text: p?.breed ?? '');
    _colorCtrl = TextEditingController(text: p?.color ?? '');
    _microchipCtrl = TextEditingController(text: p?.microchipId ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    _ageCtrl = TextEditingController(text: p?.ageYears?.toString() ?? '');
    _weightCtrl = TextEditingController(
        text: p?.weightKg != null ? _fmtW(p!.weightKg!) : '');
    _type = p?.type ?? 'כלב';
    _gender = p?.gender ?? 'זכר';
    _isVaccinated = p?.isVaccinated ?? false;
    _existingImageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _breedCtrl,
      _colorCtrl,
      _microchipCtrl,
      _notesCtrl,
      _ageCtrl,
      _weightCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmtW(double w) =>
      w == w.truncateToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800);
    if (xFile != null) setState(() => _imageFile = File(xFile.path));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final ageYears = int.tryParse(_ageCtrl.text.trim());
      final weightKg = double.tryParse(_weightCtrl.text.trim());
      final notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      final color =
          _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim();
      final chip = _microchipCtrl.text.trim().isEmpty
          ? null
          : _microchipCtrl.text.trim();

      if (_isEdit) {
        await widget.ref.read(petsNotifierProvider.notifier).editPet(
              petId: widget.pet!.id,
              name: name,
              type: _type,
              breed: _breedCtrl.text.trim(),
              gender: _gender,
              notes: notes,
              ageYears: ageYears,
              weightKg: weightKg,
              color: color,
              isVaccinated: _isVaccinated,
              microchipId: chip,
              imageFile: _imageFile,
              existingImageUrl: _existingImageUrl,
            );
      } else {
        await widget.ref.read(petsNotifierProvider.notifier).addPet(
              name: name,
              type: _type,
              breed: _breedCtrl.text.trim(),
              gender: _gender,
              notes: notes,
              ageYears: ageYears,
              weightKg: weightKg,
              color: color,
              isVaccinated: _isVaccinated,
              microchipId: chip,
              imageFile: _imageFile,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בשמירה, נסה שוב'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  DecorationImage? get _avatarImage {
    if (_imageFile != null) {
      return DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover);
    }
    if (_existingImageUrl?.isNotEmpty == true) {
      return DecorationImage(
          image: CachedNetworkImageProvider(_existingImageUrl!),
          fit: BoxFit.cover);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title + subtitle
            Text(
              _isEdit ? 'ערוך פרטי חיה' : 'הוסף חיה חדשה',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isEdit
                  ? 'עדכן את הפרטים הרצויים ולחץ שמור'
                  : 'הזן את פרטי החיה כדי להוסיפה לפרופיל שלך',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Photo picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pureWhite,
                        border: Border.all(color: AppColors.border, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.prussianBlue3.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: _avatarImage,
                      ),
                      child: _avatarImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pets_rounded,
                                    size: 30, color: AppColors.textMuted),
                                SizedBox(height: 4),
                                Text(
                                  'הוסף תמונה',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Section: basic info ───────────────────────────────────────
            _sectionHeader('פרטים בסיסיים'),
            const SizedBox(height: 14),

            // Type
            const _FormLabel('סוג חיה'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final active = t == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.border,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Gender
            const _FormLabel('מין'),
            const SizedBox(height: 8),
            Row(
              children: _genders.map((g) {
                final active = g == _gender;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin:
                          EdgeInsets.only(left: g == _genders.last ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Name
            _labeledField(
              label: 'שם החיה',
              ctrl: _nameCtrl,
              hint: 'לדוגמה: בוב, לונה...',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),

            // Breed
            _labeledField(
              label: 'גזע',
              ctrl: _breedCtrl,
              hint: 'לברדור, מעורב... (אופציונלי)',
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 26),

            // ── Section: measurements ─────────────────────────────────────
            _sectionHeader('מידות ומראה'),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _labeledField(
                    label: 'גיל (שנים)',
                    ctrl: _ageCtrl,
                    hint: '3',
                    icon: Icons.cake_outlined,
                    numeric: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _labeledField(
                    label: 'משקל (ק"ג)',
                    ctrl: _weightCtrl,
                    hint: '12.5',
                    icon: Icons.monitor_weight_outlined,
                    numeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _labeledField(
              label: 'צבע / סימנים',
              ctrl: _colorCtrl,
              hint: 'כחול, שחור ולבן...',
              icon: Icons.palette_outlined,
            ),
            const SizedBox(height: 26),

            // ── Section: health ───────────────────────────────────────────
            _sectionHeader('בריאות'),
            const SizedBox(height: 14),

            // Vaccinated toggle
            GestureDetector(
              onTap: () => setState(() => _isVaccinated = !_isVaccinated),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _isVaccinated
                      ? AppColors.success.withValues(alpha: 0.07)
                      : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isVaccinated
                        ? AppColors.success.withValues(alpha: 0.35)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isVaccinated
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.vaccines_rounded,
                        size: 20,
                        color: _isVaccinated
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'מחוסן / מחוסנת',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isVaccinated
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _isVaccinated
                                ? 'החיה מחוסנת'
                                : 'לחץ לסימון כמחוסן',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isVaccinated,
                      onChanged: (v) => setState(() => _isVaccinated = v),
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _labeledField(
              label: 'מספר שבב',
              ctrl: _microchipCtrl,
              hint: '123456789 (אופציונלי)',
              icon: Icons.memory_rounded,
            ),
            const SizedBox(height: 12),

            // Notes
            const _FormLabel('הערות רפואיות'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _notesCtrl,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'אלרגיות, תרופות, מגבלות... (אופציונלי)',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  hintTextDirection: TextDirection.rtl,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 54,
                decoration: BoxDecoration(
                  gradient: _saving ? null : AppColors.primaryGradient,
                  color: _saving ? AppColors.border : null,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: _saving
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isEdit
                                  ? Icons.save_rounded
                                  : Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEdit ? 'שמור שינויים' : 'הוסף חיה',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(color: AppColors.divider, height: 1),
        ),
      ],
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool numeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: ctrl,
            textDirection: TextDirection.rtl,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              hintTextDirection: TextDirection.rtl,
              prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}
