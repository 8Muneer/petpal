import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;
  final String serviceId;
  final String serviceType;
  final String priceText;

  const CreateBookingScreen({
    super.key,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
    required this.serviceId,
    required this.serviceType,
    required this.priceText,
  });

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _petNameController = TextEditingController();
  final _notesController = TextEditingController();

  String _petType = 'כלב';
  DateTime? _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  static const _petTypes = ['כלב', 'חתול', 'אחר'];
  bool get _isWalk => widget.serviceType == 'walk';

  @override
  void dispose() {
    _petNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({bool isStart = true}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('he'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.pureWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (_isWalk) {
        _selectedDate = picked;
      } else if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final petName = _petNameController.text.trim();
    if (petName.isEmpty) {
      _snack('יש להזין שם חיית המחמד');
      return;
    }
    if (_isWalk && _selectedDate == null) {
      _snack('יש לבחור תאריך לטיול');
      return;
    }
    if (!_isWalk && (_startDate == null || _endDate == null)) {
      _snack('יש לבחור תאריכי התחלה וסיום');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final profile = ref.read(currentUserProfileProvider).asData?.value;

      final data = {
        'ownerUid': user.uid,
        'ownerName': profile?.name ?? user.displayName ?? user.email ?? '',
        'ownerPhotoUrl': profile?.photoUrl ?? user.photoURL,
        'providerUid': widget.providerUid,
        'providerName': widget.providerName,
        'providerPhotoUrl': widget.providerPhotoUrl,
        'serviceId': widget.serviceId,
        'serviceType': widget.serviceType,
        'petName': petName,
        'petType': _petType,
        'requestedDate': _isWalk && _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!)
            : null,
        'startDate': !_isWalk && _startDate != null
            ? Timestamp.fromDate(_startDate!)
            : null,
        'endDate': !_isWalk && _endDate != null
            ? Timestamp.fromDate(_endDate!)
            : null,
        'specialInstructions': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'status': BookingStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.read(bookingRepositoryProvider).createBooking(data);
      if (!mounted) return;
      _snack('הבקשה נשלחה בהצלחה!', success: true);
      context.pop();
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _snack('שגיאה בשליחת הבקשה, נסה שוב');
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text('הזמנת שירות', style: AppTextStyles.headlineSm),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Provider summary banner
            _ProviderBanner(
              name: widget.providerName,
              photo: widget.providerPhotoUrl,
              serviceType: widget.serviceType,
              priceText: widget.priceText,
            ),
            const SizedBox(height: 24),

            // Pet info section
            Text('פרטי החיה', style: AppTextStyles.headlineSm),
            const SizedBox(height: 12),
            _Section(
              children: [
                TextField(
                  controller: _petNameController,
                  decoration: InputDecoration(
                    labelText: 'שם החיה',
                    hintText: 'למשל: רקסי',
                    prefixIcon: const Icon(Icons.pets_rounded,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                    filled: true,
                    fillColor: AppColors.pureWhite,
                  ),
                ),
                const SizedBox(height: 12),
                Text('סוג החיה', style: AppTextStyles.labelMd),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _petTypes.map((type) {
                    final selected = _petType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) => setState(() => _petType = type),
                      selectedColor: AppColors.primary,
                      labelStyle: AppTextStyles.labelMd.copyWith(
                        color: selected ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                      backgroundColor: AppColors.pureWhite,
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date section
            Text(_isWalk ? 'תאריך הטיול' : 'תאריכי שמירה',
                style: AppTextStyles.headlineSm),
            const SizedBox(height: 12),
            _Section(
              children: _isWalk
                  ? [
                      _DateTile(
                        label: 'תאריך',
                        date: _selectedDate,
                        onTap: () => _pickDate(),
                      ),
                    ]
                  : [
                      _DateTile(
                        label: 'תאריך התחלה',
                        date: _startDate,
                        onTap: () => _pickDate(isStart: true),
                      ),
                      const SizedBox(height: 8),
                      _DateTile(
                        label: 'תאריך סיום',
                        date: _endDate,
                        onTap: () => _pickDate(isStart: false),
                      ),
                      if (_startDate != null && _endDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_endDate!.difference(_startDate!).inDays} לילות',
                          style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
            ),
            const SizedBox(height: 20),

            // Notes
            Text('הוראות מיוחדות (אופציונלי)',
                style: AppTextStyles.headlineSm),
            const SizedBox(height: 12),
            _Section(
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'כל מידע חשוב שצריך לדעת...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                    filled: true,
                    fillColor: AppColors.pureWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('שלח בקשת הזמנה',
                        style: AppTextStyles.bodyMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ProviderBanner extends StatelessWidget {
  final String name;
  final String? photo;
  final String serviceType;
  final String priceText;

  const _ProviderBanner({
    required this.name,
    this.photo,
    required this.serviceType,
    required this.priceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: (photo != null && photo!.isNotEmpty)
                ? CachedNetworkImageProvider(photo!)
                : null,
            child: (photo == null || photo!.isEmpty)
                ? Text(
                    name.isNotEmpty
                        ? name.characters.first.toUpperCase()
                        : '?',
                    style: AppTextStyles.headlineSm
                        .copyWith(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                Text(
                  serviceType == 'walk' ? 'טיולי כלבים' : 'שמירה על חיות',
                  style: AppTextStyles.labelMd
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(priceText,
                style: AppTextStyles.labelMd.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateTile(
      {required this.label, required this.date, required this.onTap});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: date != null ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(10),
          color: date != null
              ? AppColors.primaryFaint
              : AppColors.pureWhite,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18,
                color: date != null ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(label,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.textSecondary)),
            const Spacer(),
            Text(
              date != null ? _fmt(date!) : 'בחר תאריך',
              style: AppTextStyles.bodyMd.copyWith(
                color: date != null ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_left_rounded,
                size: 18,
                color:
                    date != null ? AppColors.primary : AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

