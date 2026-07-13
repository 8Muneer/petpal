import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/features/applications/data/models/service_application_model.dart';
import 'package:petpal/features/applications/domain/entities/service_application.dart';
import 'package:petpal/features/applications/presentation/providers/application_provider.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart';

/// Structured "הגש מועמדות" sheet a provider fills to offer on a request:
/// price, availability, experience and a short bio — replacing the old
/// price+message-into-chat flow. Writes a `ServiceApplication` the owner can
/// review and accept/refuse. Shared by walk and sitting request screens.
class ServiceApplicationSheet extends ConsumerStatefulWidget {
  final String requestType; // 'walk' | 'sitting'
  final String requestId;
  final String ownerUid;
  final String petName;
  final String ownerName;

  /// Small summary chips shown at the top (area / date / time / budget).
  final List<String> summaryChips;

  /// When the request is no longer applicable (e.g. the walk's preferred
  /// date). Submission is blocked once this has fully passed.
  final DateTime? deadline;

  const ServiceApplicationSheet({
    super.key,
    required this.requestType,
    required this.requestId,
    required this.ownerUid,
    required this.petName,
    required this.ownerName,
    this.summaryChips = const [],
    this.deadline,
  });

  @override
  ConsumerState<ServiceApplicationSheet> createState() =>
      _ServiceApplicationSheetState();
}

class _ServiceApplicationSheetState
    extends ConsumerState<ServiceApplicationSheet> {
  final _priceController = TextEditingController();
  final _altController = TextEditingController();
  final _expController = TextEditingController();
  final _bioController = TextEditingController();
  bool _available = true;
  bool _sending = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _priceController.dispose();
    _altController.dispose();
    _expController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  bool get _isExpired {
    final deadline = widget.deadline;
    if (deadline == null) return false;
    final endOfDeadlineDay =
        DateTime(deadline.year, deadline.month, deadline.day, 23, 59, 59);
    return endOfDeadlineDay.isBefore(DateTime.now());
  }

  Future<void> _submit() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    if (_isExpired) {
      _snack('לא ניתן להגיש מועמדות לבקשה שפג תוקפה');
      return;
    }

    final price = _priceController.text.trim();
    if (price.isEmpty) {
      _snack('יש להזין מחיר');
      return;
    }
    if (!_available && _altController.text.trim().isEmpty) {
      _snack('ציין/י מועד חלופי שבו תוכל/י');
      return;
    }

    setState(() => _sending = true);
    try {
      final profile = ref.read(currentUserProfileProvider).asData?.value;
      final rating = ref.read(providerRatingProvider(me.uid)).asData?.value;

      final model = ServiceApplicationModel(
        id: me.uid,
        requestId: widget.requestId,
        requestType: widget.requestType,
        ownerUid: widget.ownerUid,
        providerUid: me.uid,
        providerName: profile?.name ?? me.displayName ?? me.email ?? 'מטפל',
        providerPhotoUrl: profile?.photoUrl ?? me.photoURL,
        price: withShekel(price),
        availabilityConfirmed: _available,
        alternativeNote:
            _available ? null : _altController.text.trim(),
        experienceYears: int.tryParse(_expController.text.trim()),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        ratingAvg: rating?.avg,
        ratingCount: rating?.count,
        status: ApplicationStatus.pending,
      );

      await ref.read(applicationDatasourceProvider).submitApplication(model);
      if (!mounted) return;
      Navigator.pop(context);
      _snack('הצעתך נשלחה לבעל החיה', success: true);
    } catch (_) {
      if (mounted) _snack('שגיאה בשליחת ההצעה, נסה שוב');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefill bio + any existing offer once the async values are ready.
    if (!_prefilled) {
      final me = FirebaseAuth.instance.currentUser;
      final existing = me == null
          ? null
          : ref
              .read(myApplicationProvider((
                type: widget.requestType,
                id: widget.requestId,
                providerUid: me.uid,
              )))
              .asData
              ?.value;
      if (existing != null) {
        _priceController.text = existing.price ?? '';
        _available = existing.availabilityConfirmed;
        _altController.text = existing.alternativeNote ?? '';
        _expController.text = existing.experienceYears?.toString() ?? '';
        _bioController.text = existing.bio ?? '';
        _prefilled = true;
      } else {
        final bio = ref.read(currentUserProfileProvider).asData?.value?.bio;
        if (bio != null && bio.isNotEmpty && _bioController.text.isEmpty) {
          _bioController.text = bio;
        }
        _prefilled = true;
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text('הגש מועמדות',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.borderFaint,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('בעל החיה יראה את הפרטים ויחליט אם לאשר',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 14),

                if (widget.summaryChips.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.primary.withValues(alpha: 0.06),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.petName}  ·  ${widget.ownerName}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: widget.summaryChips
                              .map((c) => Text(c,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Price
                const _Label('המחיר שלך'),
                _Field(
                  controller: _priceController,
                  hint: 'לדוגמה: 80',
                  prefix: '₪',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                // Availability
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    color: AppColors.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _available
                            ? Icons.event_available_rounded
                            : Icons.event_busy_rounded,
                        size: 18,
                        color: _available
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('זמין/ה בתאריך המבוקש',
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Switch(
                        value: _available,
                        activeTrackColor: AppColors.success,
                        onChanged: (v) => setState(() => _available = v),
                      ),
                    ],
                  ),
                ),
                if (!_available) ...[
                  const SizedBox(height: 10),
                  const _Label('מועד חלופי'),
                  _Field(
                    controller: _altController,
                    hint: 'לדוגמה: אוכל ביום שלישי אחרי 16:00',
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 14),

                // Experience
                const _Label('ניסיון (שנים)'),
                _Field(
                  controller: _expController,
                  hint: 'לדוגמה: 3',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                // Bio
                const _Label('קצת עליי'),
                _Field(
                  controller: _bioController,
                  hint: 'ספר/י לבעל החיה על עצמך ועל הניסיון שלך...',
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 18),

                GestureDetector(
                  onTap: _sending ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_sending)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        else
                          const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(_sending ? 'שולח...' : 'שלח הצעה',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final int maxLines;
  final int minLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    this.prefix,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixText: prefix,
        prefixStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
