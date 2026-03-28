import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';

class CreateWalkServiceScreen extends ConsumerStatefulWidget {
  final WalkService? service; // null = create, non-null = edit
  const CreateWalkServiceScreen({super.key, this.service});

  @override
  ConsumerState<CreateWalkServiceScreen> createState() =>
      _CreateWalkServiceScreenState();
}

class _CreateWalkServiceScreenState
    extends ConsumerState<CreateWalkServiceScreen> {
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();
  final _bioController = TextEditingController();
  final _customDurationController = TextEditingController();

  String _priceType = 'קבוע'; // 'קבוע' | 'לשעה' | 'לפי הסכמה'
  String _duration = 'שעה';
  final Set<String> _petTypes = {'כלב'};
  final Set<String> _availableDays = {};
  bool _isPublishing = false;

  static const _priceTypes = ['קבוע', 'לשעה', 'לפי הסכמה'];
  static const _durations = ['30 דקות', 'שעה', 'שעה וחצי', 'שעתיים', 'גמיש', 'אחר'];
  static const _allPetTypes = ['כלב', 'חתול', 'אחר'];
  static const _days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];

  bool get _isEditMode => widget.service != null;
  bool get _allDaysSelected => _availableDays.length == _days.length;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    if (s != null) {
      _areaController.text = s.area;
      // Strip ₪ so the user edits the raw number
      _priceController.text = s.priceType == 'לפי הסכמה'
          ? ''
          : s.priceText.replaceAll('₪', '').trim();
      _bioController.text = s.bio ?? '';
      _priceType = s.priceType;
      if (_durations.contains(s.duration)) {
        _duration = s.duration;
      } else {
        _duration = 'אחר';
        _customDurationController.text = s.duration;
      }
      _petTypes
        ..clear()
        ..addAll(s.petTypes.isNotEmpty ? s.petTypes : ['כלב']);
      _availableDays
        ..clear()
        ..addAll(s.availableDays);
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _priceController.dispose();
    _bioController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final area = _areaController.text.trim();
    final rawPrice = _priceController.text.trim();
    final priceText = _priceType == 'לפי הסכמה'
        ? 'לפי הסכמה'
        : (rawPrice.contains('₪') ? rawPrice : '$rawPrice₪');
    final effectiveDuration = _duration == 'אחר'
        ? _customDurationController.text.trim()
        : _duration;

    if (area.isEmpty) {
      _showSnack('יש להזין אזור / עיר', isError: true);
      return;
    }
    if (_priceType != 'לפי הסכמה' && rawPrice.isEmpty) {
      _showSnack('יש להזין מחיר', isError: true);
      return;
    }
    if (_duration == 'אחר' && effectiveDuration.isEmpty) {
      _showSnack('יש להזין משך מותאם', isError: true);
      return;
    }
    if (_petTypes.isEmpty) {
      _showSnack('יש לבחור לפחות סוג חיה אחד', isError: true);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bio = _bioController.text.trim();
      final data = {
        'providerUid': user.uid,
        'providerName': user.displayName ?? user.email ?? '',
        'providerPhotoUrl': user.photoURL,
        'area': area,
        'priceText': priceText,
        'priceType': _priceType,
        'bio': bio.isNotEmpty ? bio : null,
        'duration': effectiveDuration,
        'petTypes': _petTypes.toList(),
        'availableDays': _availableDays.toList(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final datasource = ref.read(walkDatasourceProvider);
      if (_isEditMode) {
        await datasource.updateWalkService(widget.service!.id, data);
      } else {
        await datasource.createWalkService(data);
      }

      if (!mounted) return;
      context.pop();
      _showSnack(_isEditMode ? 'השירות עודכן בהצלחה' : 'השירות פורסם בהצלחה');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      _showSnack('שגיאה בשמירת השירות', isError: true);
    }
  }

  void _toggleAllDays() {
    setState(() {
      if (_allDaysSelected) {
        _availableDays.clear();
      } else {
        _availableDays.addAll(_days);
      }
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFFB7185) : const Color(0xFF0F766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PetPalScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: const Color(0xFF0F172A),
                    ),
                    Expanded(
                      child: Text(
                        _isEditMode
                            ? 'עריכת שירות טיולים'
                            : 'פרסם שירות טיולים',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  children: [
                    // ── Location ─────────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.location_on_rounded, title: 'מיקום'),
                    const SizedBox(height: 8),
                    GlassCard(
                      useBlur: true,
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _areaController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'לדוגמה: תל אביב, רמת גן',
                          hintStyle: TextStyle(
                            color: const Color(0xFF64748B).withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                          prefixIcon: const Icon(Icons.location_on_rounded,
                              color: Color(0xFF0F766E)),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Pricing ───────────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'תמחור'),
                    const SizedBox(height: 8),
                    GlassCard(
                      useBlur: true,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Price type chips
                          Row(
                            children: _priceTypes.map((type) {
                              final selected = _priceType == type;
                              IconData icon;
                              switch (type) {
                                case 'קבוע':
                                  icon = Icons.tag_rounded;
                                  break;
                                case 'לשעה':
                                  icon = Icons.access_time_rounded;
                                  break;
                                default:
                                  icon = Icons.handshake_outlined;
                              }
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        setState(() => _priceType = type),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        color: selected
                                            ? const Color(0xFF0F766E)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: selected
                                              ? const Color(0xFF0F766E)
                                              : const Color(0xFF64748B)
                                                  .withOpacity(0.25),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(icon,
                                              size: 16,
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFF64748B)),
                                          const SizedBox(height: 4),
                                          Text(
                                            type,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          // Price input or negotiable note
                          if (_priceType != 'לפי הסכמה')
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color:
                                    const Color(0xFF0F766E).withOpacity(0.06),
                              ),
                              child: TextField(
                                controller: _priceController,
                                textDirection: TextDirection.rtl,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  hintText: _priceType == 'קבוע'
                                      ? '₪80 לטיול'
                                      : '₪50 לשעה',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF64748B)
                                        .withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        start: 14, end: 4),
                                    child: Align(
                                      widthFactor: 1,
                                      heightFactor: 1,
                                      child: Text('₪',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F766E),
                                          )),
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color:
                                    const Color(0xFF64748B).withOpacity(0.06),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.handshake_outlined,
                                      color: const Color(0xFF64748B)
                                          .withOpacity(0.7),
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'המחיר יסוכם ישירות עם בעל החיה',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B)
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Pet types ─────────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.pets_rounded,
                        title: 'סוגי חיות מחמד'),
                    const SizedBox(height: 8),
                    GlassCard(
                      useBlur: true,
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: _allPetTypes.map((type) {
                          final selected = _petTypes.contains(type);
                          IconData icon;
                          switch (type) {
                            case 'כלב':
                              icon = Icons.directions_walk_rounded;
                              break;
                            case 'חתול':
                              icon = Icons.pets_rounded;
                              break;
                            default:
                              icon = Icons.cruelty_free_rounded;
                          }
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() {
                                  if (selected && _petTypes.length > 1) {
                                    _petTypes.remove(type);
                                  } else {
                                    _petTypes.add(type);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: selected
                                        ? const Color(0xFF0F766E)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF0F766E)
                                          : const Color(0xFF64748B)
                                              .withOpacity(0.25),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon,
                                          size: 20,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF64748B)),
                                      const SizedBox(height: 5),
                                      Text(
                                        type,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Duration ──────────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.timer_rounded, title: 'משך הטיול'),
                    const SizedBox(height: 8),
                    GlassCard(
                      useBlur: true,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _durations
                                .map((d) => _buildSelectChip(
                                      label: d,
                                      selected: _duration == d,
                                      onTap: () =>
                                          setState(() => _duration = d),
                                    ))
                                .toList(),
                          ),
                          if (_duration == 'אחר') ...[
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFF0F766E)
                                    .withOpacity(0.06),
                              ),
                              child: TextField(
                                controller: _customDurationController,
                                textDirection: TextDirection.rtl,
                                decoration: InputDecoration(
                                  hintText: 'לדוגמה: 3 שעות, לילה שלם',
                                  hintStyle: TextStyle(
                                    color: const Color(0xFF64748B)
                                        .withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  prefixIcon: const Icon(Icons.edit_rounded,
                                      color: Color(0xFF0F766E), size: 18),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Available days ────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.calendar_month_rounded,
                        title: 'ימי זמינות (אופציונלי)'),
                    const SizedBox(height: 8),
                    GlassCard(
                      useBlur: true,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "All days" shortcut
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _toggleAllDays,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _allDaysSelected
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF0F766E)
                                        .withOpacity(0.07),
                                border: Border.all(
                                  color: _allDaysSelected
                                      ? const Color(0xFF0F766E)
                                      : const Color(0xFF0F766E)
                                          .withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _allDaysSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.select_all_rounded,
                                    size: 16,
                                    color: _allDaysSelected
                                        ? Colors.white
                                        : const Color(0xFF0F766E),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'כל הימים',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _allDaysSelected
                                          ? Colors.white
                                          : const Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Individual day chips (disabled when "all days" is selected)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: _days.map((day) {
                              final selected =
                                  _availableDays.contains(day);
                              return Opacity(
                                opacity: _allDaysSelected ? 0.38 : 1.0,
                                child: IgnorePointer(
                                  ignoring: _allDaysSelected,
                                  child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() {
                                  if (selected) {
                                    _availableDays.remove(day);
                                  } else {
                                    _availableDays.add(day);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 140),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    color: selected
                                        ? const Color(0xFF0F766E)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF0F766E)
                                          : const Color(0xFF64748B)
                                              .withOpacity(0.25),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ), // InkWell
                                ),  // IgnorePointer
                              ); // Opacity
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Bio ───────────────────────────────────────────────
                    const _SectionHeader(
                        icon: Icons.notes_rounded,
                        title: 'תיאור (אופציונלי)'),
                    const SizedBox(height: 8),
                    GlassCard(
                      useBlur: true,
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _bioController,
                        textDirection: TextDirection.rtl,
                        maxLines: 4,
                        maxLength: 200,
                        buildCounter: (context,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '$currentLength / $maxLength',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: currentLength > (maxLength! * 0.85)
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'תאר/י את הניסיון שלך, הזמינות, ומה מייחד אותך כמטייל/ת חיות מחמד...',
                          hintStyle: TextStyle(
                            color:
                                const Color(0xFF64748B).withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Submit button ─────────────────────────────────────
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _isPublishing ? null : _publish,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: _isPublishing
                                ? [
                                    const Color(0xFF64748B),
                                    const Color(0xFF94A3B8)
                                  ]
                                : [
                                    const Color(0xFF0F766E),
                                    const Color(0xFF22C55E)
                                  ],
                          ),
                          boxShadow: _isPublishing
                              ? []
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF0F766E)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: _isPublishing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isEditMode
                                          ? Icons.save_rounded
                                          : Icons.campaign_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEditMode
                                          ? 'שמור שינויים'
                                          : 'פרסם/י שירות',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color:
              selected ? const Color(0xFF0F766E) : Colors.transparent,
          border: Border.all(
            color: selected
                ? const Color(0xFF0F766E)
                : const Color(0xFF64748B).withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color:
                selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ── Shared section header widget ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: const Color(0xFF0F766E).withOpacity(0.1),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF0F766E)),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
