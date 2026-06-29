import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_header_bar.dart';
import 'package:petpal/core/widgets/filter_button.dart';
import 'package:petpal/core/widgets/luxury_lost_found_card.dart';
import 'package:petpal/core/widgets/lost_found_toggle_bar.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_controller.dart';

class LostFoundFeedScreen extends ConsumerStatefulWidget {
  const LostFoundFeedScreen({super.key});

  @override
  ConsumerState<LostFoundFeedScreen> createState() =>
      _LostFoundFeedScreenState();
}

class _LostFoundFeedScreenState extends ConsumerState<LostFoundFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterSheet(LostFoundState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialState: state,
        onApply: (f) {
          final n = ref.read(lostFoundControllerProvider.notifier);
          n.setPetType(f.petType);
          n.setArea(f.area);
          n.setColor(f.color);
          n.setSize(f.size);
          n.setGender(f.gender);
          n.setDateRange(f.dateRange);
          n.setActiveOnly(f.activeOnly);
          n.setHasImageOnly(f.hasImageOnly);
        },
        onClear: () =>
            ref.read(lostFoundControllerProvider.notifier).clearFilters(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lostFoundControllerProvider);
    final postsAsync = ref.watch(filteredLostFoundPostsProvider);
    final photoUrl =
        ref.watch(authStateChangesProvider).asData?.value?.photoURL;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            AppHeaderBar.sliver(title: 'אבודים'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FilterButton(
                          activeCount: state.hasActiveFilters ? 1 : 0,
                          onTap: () => _showFilterSheet(state),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _buildCreateCTA(photoUrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LostFoundToggleBar(
                            selectedIndex: state.selectedTabIndex,
                            onTabChanged: (i) => ref
                                .read(lostFoundControllerProvider.notifier)
                                .setTab(i),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => ref
                              .read(lostFoundControllerProvider.notifier)
                              .toggleMyReportsOnly(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: state.showMyReportsOnly
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: state.showMyReportsOnly
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (state.showMyReportsOnly
                                          ? AppColors.primary
                                          : Colors.black)
                                      .withValues(
                                          alpha: state.showMyReportsOnly
                                              ? 0.25
                                              : 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  state.showMyReportsOnly
                                      ? Icons.person_rounded
                                      : Icons.person_outline_rounded,
                                  size: 16,
                                  color: state.showMyReportsOnly
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'הדיווחים שלי',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: state.showMyReportsOnly
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Active filter chips
                    if (state.hasActiveFilters) ...[
                      const SizedBox(height: 10),
                      _buildActiveFilterChips(state),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildGridFeed(postsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCTA(String? photoUrl) {
    return GestureDetector(
      onTap: () => context.push('/lost-found/create'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'דווח על אבידה או מציאה...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(LostFoundState state) {
    final n = ref.read(lostFoundControllerProvider.notifier);
    final chips = <Widget>[];

    void add(String label, VoidCallback onRemove) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 8));
      chips.add(_ActiveChip(label: label, onRemove: onRemove));
    }

    if (state.selectedPetType != null) {
      add(state.selectedPetType!, () => n.setPetType(null));
    }
    if (state.selectedArea != null) {
      add(state.selectedArea!, () => n.setArea(null));
    }
    if (state.selectedColor != null) {
      add(state.selectedColor!, () => n.setColor(null));
    }
    if (state.selectedSize != null) {
      add(state.selectedSize!, () => n.setSize(null));
    }
    if (state.selectedGender != null) {
      add(state.selectedGender!, () => n.setGender(null));
    }
    if (state.selectedDateRange != null) {
      final label = state.selectedDateRange == '24h'
          ? '24 שעות'
          : state.selectedDateRange == 'week'
              ? 'שבוע אחרון'
              : 'חודש אחרון';
      add(label, () => n.setDateRange(null));
    }
    if (state.showActiveOnly) add('פעיל בלבד', () => n.setActiveOnly(false));
    if (state.hasImageOnly) add('עם תמונה', () => n.setHasImageOnly(false));
    if (state.showMyReportsOnly) {
      add('הדיווחים שלי', () => n.toggleMyReportsOnly());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _buildGridFeed(AsyncValue<List<LostFoundPost>> postsAsync) {
    return postsAsync.when(
      loading: () => const SliverFillRemaining(
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('שגיאה בטעינה: $e')),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const SliverFillRemaining(child: _EmptyState());
        }
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(context).viewPadding.bottom + 84),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 80)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: LuxuryLostFoundCard(
                    post: posts[index],
                    onTap: () =>
                        context.push('/lost-found/detail', extra: posts[index]),
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        );
      },
    );
  }

}

// ── Active filter chip ─────────────────────────────────────────────────────
class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Filter result ──────────────────────────────────────────────────────────
class _FilterResult {
  final String? petType;
  final String? area;
  final String? color;
  final String? size;
  final String? gender;
  final String? dateRange;
  final bool activeOnly;
  final bool hasImageOnly;

  const _FilterResult({
    this.petType,
    this.area,
    this.color,
    this.size,
    this.gender,
    this.dateRange,
    this.activeOnly = false,
    this.hasImageOnly = false,
  });
}

// ── Filter bottom sheet ────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final LostFoundState initialState;
  final void Function(_FilterResult) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.initialState,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _petType;
  String? _area;
  String? _color;
  String? _size;
  String? _gender;
  String? _dateRange;
  bool _activeOnly = false;
  bool _hasImageOnly = false;

  final _areaController = TextEditingController();
  final _colorController = TextEditingController();

  static const _petTypes = [
    ('כלב', Icons.directions_walk_rounded),
    ('חתול', Icons.pets_rounded),
    ('ציפור', Icons.flutter_dash_rounded),
    ('ארנב', Icons.cruelty_free_rounded),
    ('אחר', Icons.more_horiz_rounded),
  ];

  static const _quickAreas = [
    'תל אביב',
    'ירושלים',
    'חיפה',
    'ראשון לציון',
    'פתח תקווה',
    'אשדוד',
    'נתניה',
    'באר שבע',
    'רמת גן',
    'הרצליה',
    'הוד השרון',
    'כפר סבא',
  ];

  static const _sizes = ['קטן', 'בינוני', 'גדול'];
  static const _genders = ['זכר', 'נקבה'];
  static const _dateRanges = [
    ('24 שעות', '24h'),
    ('שבוע אחרון', 'week'),
    ('חודש אחרון', 'month'),
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.initialState;
    _petType = s.selectedPetType;
    _area = s.selectedArea;
    _color = s.selectedColor;
    _size = s.selectedSize;
    _gender = s.selectedGender;
    _dateRange = s.selectedDateRange;
    _activeOnly = s.showActiveOnly;
    _hasImageOnly = s.hasImageOnly;
    _areaController.text = s.selectedArea ?? '';
    _colorController.text = s.selectedColor ?? '';
  }

  @override
  void dispose() {
    _areaController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _selectableChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textFilterField({
    required TextEditingController controller,
    required String hint,
    required void Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.textMuted, fontWeight: FontWeight.w400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: AppColors.border, height: 1),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title + clear
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'סינון',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'נקה הכל',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Pet type ──────────────────────────────────────────────
              _sectionTitle('סוג חיה'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _petTypes.map((e) {
                  final selected = _petType == e.$1;
                  return _selectableChip(
                    e.$1,
                    selected,
                    () => setState(() => _petType = selected ? null : e.$1),
                    icon: e.$2,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 20),

              // ── Area ──────────────────────────────────────────────────
              _sectionTitle('אזור / עיר'),
              _textFilterField(
                controller: _areaController,
                hint: 'הזן עיר או שכונה...',
                onChanged: (v) => setState(() => _area = v.isEmpty ? null : v),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAreas.map((city) {
                  final selected = _area == city;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _area = selected ? null : city;
                      _areaController.text = selected ? '' : city;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        city,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 20),

              // ── Color ─────────────────────────────────────────────────
              _sectionTitle('צבע'),
              _textFilterField(
                controller: _colorController,
                hint: 'לבן, שחור, חום...',
                onChanged: (v) => setState(() => _color = v.isEmpty ? null : v),
              ),
              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 20),

              // ── Size ──────────────────────────────────────────────────
              _sectionTitle('גודל'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sizes.map((s) {
                  final selected = _size == s;
                  return _selectableChip(
                    s,
                    selected,
                    () => setState(() => _size = selected ? null : s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 20),

              // ── Gender ────────────────────────────────────────────────
              _sectionTitle('מין'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genders.map((g) {
                  final selected = _gender == g;
                  return _selectableChip(
                    g,
                    selected,
                    () => setState(() => _gender = selected ? null : g),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _divider(),
              const SizedBox(height: 20),

              // ── Date range ────────────────────────────────────────────
              _sectionTitle('תאריך דיווח'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dateRanges.map((d) {
                  final selected = _dateRange == d.$2;
                  return _selectableChip(
                    d.$1,
                    selected,
                    () => setState(() => _dateRange = selected ? null : d.$2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _divider(),
              const SizedBox(height: 8),

              // ── Active only ───────────────────────────────────────────
              _toggleRow(
                'פעיל בלבד (לא נמצא/הוחזר)',
                _activeOnly,
                (v) => setState(() => _activeOnly = v),
              ),
              _divider(),
              const SizedBox(height: 8),

              // ── Has image only ─────────────────────────────────────────
              _toggleRow(
                'עם תמונה בלבד',
                _hasImageOnly,
                (v) => setState(() => _hasImageOnly = v),
              ),
              const SizedBox(height: 28),

              // Apply button
              GestureDetector(
                onTap: () {
                  widget.onApply(_FilterResult(
                    petType: _petType,
                    area: _area,
                    color: _color,
                    size: _size,
                    gender: _gender,
                    dateRange: _dateRange,
                    activeOnly: _activeOnly,
                    hasImageOnly: _hasImageOnly,
                  ));
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'החל סינון',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets_rounded, size: 64, color: AppColors.border),
            const SizedBox(height: 32),
            Text('לא נמצאו דיווחים', style: AppTextStyles.headlineSm),
            const SizedBox(height: 12),
            const Text(
              'הקהילה שלנו עדיין לא דיווחה על מקרים באזור זה.\nנסה לשנות את הסינון.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
