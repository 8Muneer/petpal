import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/features/booking/data/models/booking_request_model.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/pets/domain/entities/pet.dart';
import 'package:petpal/features/pets/presentation/providers/pets_provider.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;
  final String serviceId;
  final String serviceType;
  final String priceText;
  final String? priceType;

  const CreateBookingScreen({
    super.key,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
    required this.serviceId,
    required this.serviceType,
    required this.priceText,
    this.priceType,
  });

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _feedingController = TextEditingController();
  final _medicationController = TextEditingController();
  final _vetController = TextEditingController();

  Pet? _selectedPet;
  DateTime? _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _preferredTime; // walk start time
  TimeOfDay? _dropOffTime; // sitting drop-off
  TimeOfDay? _pickupTime; // sitting pickup
  int _hours = 1; // walk duration in hours — drives the hourly total
  String _sittingType = 'atOwnerHome'; // only used when serviceType == sitting
  bool _isSubmitting = false;

  bool get _isWalk => widget.serviceType == 'walk';

  /// Nights for a sitting booking (null for a walk or incomplete dates).
  int? get _nights {
    if (_isWalk || _startDate == null || _endDate == null) return null;
    final n = _endDate!.difference(_startDate!).inDays;
    return n > 0 ? n : null;
  }

  /// Live agreed-price label reflecting the current hours / nights selection.
  String get _priceLabel => bookingPriceLabel(
        priceText: widget.priceText,
        priceType: widget.priceType,
        hours: _isWalk ? _hours : null,
        nights: _nights,
      );

  /// 'HH:mm' for storage; null when no time was picked.
  static String? _fmtTime(TimeOfDay? t) => t == null
      ? null
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _feedingController.dispose();
    _medicationController.dispose();
    _vetController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TimeOfDay? current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.pureWhite,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickDate({bool isStart = true}) async {
    final now = DateTime.now();
    final DateTime firstDate;
    final DateTime initialDate;
    if (isStart) {
      firstDate = now;
      initialDate = _startDate != null && !_startDate!.isBefore(now)
          ? _startDate!
          : now.add(const Duration(days: 1));
    } else {
      firstDate = _startDate ?? now;
      initialDate = _endDate != null && !_endDate!.isBefore(firstDate)
          ? _endDate!
          : firstDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('he'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.uid == widget.providerUid) {
      _snack('אינך יכול להזמין את השירות של עצמך');
      return;
    }
    if (_selectedPet == null) {
      _snack('יש לבחור חיית מחמד');
      return;
    }
    if (_isWalk && _selectedDate == null) {
      _snack('יש לבחור תאריך לטיול');
      return;
    }
    if (_isWalk && _preferredTime == null) {
      _snack('יש לבחור שעת טיול');
      return;
    }
    if (!_isWalk && (_startDate == null || _endDate == null)) {
      _snack('יש לבחור תאריכי התחלה וסיום');
      return;
    }
    if (!_isWalk && _dropOffTime == null) {
      _snack('יש לבחור שעת מסירה');
      return;
    }

    // Block only a real TIME CLASH: an active booking you already hold with this
    // provider whose date/time overlaps the one you're requesting. Booking the
    // same provider on a different day is fine — we compare date+time via the
    // same overlap rule the server uses (BookingRequest.conflictsWith), instead
    // of the old "any active booking with this provider" block. The query filters
    // ownerUid+providerUid (equality, no composite index); overlap is checked
    // client-side on that small result set.
    setState(() => _isSubmitting = true);
    bool hasClash = false;
    try {
      final requested = BookingRequestModel(
        id: '',
        ownerUid: user.uid,
        ownerName: '',
        providerUid: widget.providerUid,
        providerName: '',
        serviceId: widget.serviceId,
        serviceType: _isWalk
            ? BookingServiceType.walk
            : BookingServiceType.sitting,
        petName: '',
        petType: '',
        requestedDate: _isWalk ? _selectedDate : null,
        startDate: _isWalk ? null : _startDate,
        endDate: _isWalk ? null : _endDate,
        preferredTime: _isWalk ? _fmtTime(_preferredTime) : null,
      );

      final snap = await FirebaseFirestore.instance
          .collection('booking_requests')
          .where('ownerUid', isEqualTo: user.uid)
          .where('providerUid', isEqualTo: widget.providerUid)
          .get();
      const activeStatuses = {'pending', 'accepted', 'awaitingConfirmation'};
      hasClash = snap.docs.any((d) {
        if (!activeStatuses.contains(d.data()['status'] as String?)) {
          return false;
        }
        return requested.conflictsWith(BookingRequestModel.fromFirestore(d));
      });
    } catch (_) {
      // Network error — allow submission; Firestore rules enforce server-side
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted) return;
    if (hasClash) {
      _snack('כבר קיימת הזמנה פעילה עם ספק זה במועד זה');
      return;
    }

    // Server-side: is the provider already committed at this time for ANYONE?
    // Only the server can see the provider's full calendar (rules hide other
    // owners' bookings), so this catches clashes the owner-side check can't.
    // On any failure we allow submission — the provider still won't double-accept
    // and C2 auto-declines conflicts on accept.
    setState(() => _isSubmitting = true);
    bool providerBusy = false;
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('checkProviderAvailability');
      final res = await callable.call<Map<String, dynamic>>({
        'providerUid': widget.providerUid,
        'serviceType': widget.serviceType,
        'requestedDate': _isWalk && _selectedDate != null
            ? _selectedDate!.millisecondsSinceEpoch
            : null,
        'startDate': !_isWalk && _startDate != null
            ? _startDate!.millisecondsSinceEpoch
            : null,
        'endDate': !_isWalk && _endDate != null
            ? _endDate!.millisecondsSinceEpoch
            : null,
        'preferredTime': _isWalk ? _fmtTime(_preferredTime) : null,
      });
      providerBusy = res.data['available'] == false;
    } catch (_) {
      // Allow submission on failure (network / not deployed).
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted) return;
    if (providerBusy) {
      _snack('נותן השירות כבר תפוס במועד זה');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('שליחת בקשת הזמנה'),
          content: Text(
            'לשלוח בקשת הזמנה ל${widget.providerName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('שלח'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
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
        'petName': _selectedPet!.name,
        'petType': _selectedPet!.type,
        'petImageUrl': _selectedPet!.imageUrl,
        'requestedDate': _isWalk && _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!)
            : null,
        'startDate': !_isWalk && _startDate != null
            ? Timestamp.fromDate(_startDate!)
            : null,
        'endDate': !_isWalk && _endDate != null
            ? Timestamp.fromDate(_endDate!)
            : null,
        'preferredTime': _isWalk ? _fmtTime(_preferredTime) : null,
        'dropOffTime': !_isWalk ? _fmtTime(_dropOffTime) : null,
        'pickupTime': !_isWalk ? _fmtTime(_pickupTime) : null,
        'location': _trimOrNull(_locationController),
        'contactPhone': _trimOrNull(_phoneController),
        'feedingInfo': _trimOrNull(_feedingController),
        'medicationInfo': _trimOrNull(_medicationController),
        'vetContact': _trimOrNull(_vetController),
        'priceText': widget.priceText.trim().isEmpty ? null : widget.priceText,
        'priceType': widget.priceType,
        'hours': _isWalk ? _hours : null,
        'specialInstructions': _trimOrNull(_notesController),
        'sittingType': !_isWalk ? _sittingType : null,
        'status': BookingStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.read(bookingRepositoryProvider).createBooking(data);
      if (!mounted) return;
      _snack('הבקשה נשלחה בהצלחה!', success: true);
      if (context.canPop()) context.pop();
      if (context.canPop()) context.pop();
    } catch (_) {
      if (!mounted) return;
      _snack('שגיאה בשליחת הבקשה, נסה שוב');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  static String? _trimOrNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
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
    final petsAsync = ref.watch(userPetsProvider);

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
            _ProviderBanner(
              name: widget.providerName,
              photo: widget.providerPhotoUrl,
              serviceType: widget.serviceType,
              priceText: widget.priceText,
            ),
            const SizedBox(height: 24),

            // Pet selection section
            Text('בחר חיית מחמד', style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Text(
              'בחר את החיה שתשתתף בשירות',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            petsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Center(child: Text('שגיאה: $e')),
              data: (pets) => _PetSelector(
                pets: pets,
                selectedPet: _selectedPet,
                onSelect: (pet) => setState(() => _selectedPet = pet),
                onAddNew: () async {
                  await context.push('/my-pets');
                  // After returning, stream auto-updates
                },
              ),
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
                      const SizedBox(height: 8),
                      _TimeTile(
                        label: 'שעת טיול',
                        time: _preferredTime,
                        onTap: () => _pickTime(_preferredTime,
                            (t) => setState(() => _preferredTime = t)),
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
                      const SizedBox(height: 8),
                      _TimeTile(
                        label: 'שעת מסירה',
                        time: _dropOffTime,
                        onTap: () => _pickTime(_dropOffTime,
                            (t) => setState(() => _dropOffTime = t)),
                      ),
                      const SizedBox(height: 8),
                      _TimeTile(
                        label: 'שעת איסוף (אופציונלי)',
                        time: _pickupTime,
                        onTap: () => _pickTime(_pickupTime,
                            (t) => setState(() => _pickupTime = t)),
                      ),
                    ],
            ),
            const SizedBox(height: 20),

            // Walk duration in hours — drives the hourly total
            if (_isWalk) ...[
              Text('משך בשעות', style: AppTextStyles.headlineSm),
              const SizedBox(height: 12),
              _Section(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timelapse_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text('מספר שעות',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        onTap:
                            _hours > 1 ? () => setState(() => _hours--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_hours',
                            style: AppTextStyles.headlineSm
                                .copyWith(fontWeight: FontWeight.w800)),
                      ),
                      _StepperButton(
                        icon: Icons.add_rounded,
                        onTap:
                            _hours < 24 ? () => setState(() => _hours++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Live agreed-price summary (updates with hours / nights)
            _PriceSummary(label: _priceLabel),
            const SizedBox(height: 20),

            // Sitting type selector — only for sitting bookings
            if (!_isWalk) ...[
              Text('סוג שמירה', style: AppTextStyles.headlineSm),
              const SizedBox(height: 12),
              _Section(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _sittingType = 'atOwnerHome'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _sittingType == 'atOwnerHome'
                                  ? AppColors.primary
                                  : AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _sittingType == 'atOwnerHome'
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              'בבית הבעלים',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: _sittingType == 'atOwnerHome'
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _sittingType = 'atSitterHome'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _sittingType == 'atSitterHome'
                                  ? AppColors.primary
                                  : AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _sittingType == 'atSitterHome'
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              'בבית השומר',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: _sittingType == 'atSitterHome'
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Location + contact
            Text('מיקום ויצירת קשר', style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Text(
              'עוזר לנותן השירות להגיע ולתאם (אופציונלי)',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            _Section(
              children: [
                _FieldInput(
                  controller: _locationController,
                  label: _isWalk ? 'נקודת מפגש / כתובת' : 'כתובת',
                  icon: Icons.location_on_outlined,
                  hint: 'לדוגמה: רחוב הרצל 10, תל אביב',
                ),
                const SizedBox(height: 12),
                _FieldInput(
                  controller: _phoneController,
                  label: 'טלפון ליצירת קשר',
                  icon: Icons.phone_outlined,
                  hint: '050-0000000',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Care details
            Text('פרטי טיפול', style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Text(
              'מידע חשוב על החיה (אופציונלי)',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            _Section(
              children: [
                _FieldInput(
                  controller: _feedingController,
                  label: 'האכלה',
                  icon: Icons.restaurant_outlined,
                  hint: 'כמות, שעות, סוג מזון...',
                ),
                const SizedBox(height: 12),
                _FieldInput(
                  controller: _medicationController,
                  label: 'תרופות',
                  icon: Icons.medication_outlined,
                  hint: 'תרופות ומינון, אם יש',
                ),
                const SizedBox(height: 12),
                _FieldInput(
                  controller: _vetController,
                  label: 'וטרינר / איש קשר לחירום',
                  icon: Icons.local_hospital_outlined,
                  hint: 'שם וטלפון',
                  keyboardType: TextInputType.phone,
                ),
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

// ── Pet Selector ───────────────────────────────────────────────────────────────

class _PetSelector extends StatelessWidget {
  final List<Pet> pets;
  final Pet? selectedPet;
  final ValueChanged<Pet> onSelect;
  final VoidCallback onAddNew;

  const _PetSelector({
    required this.pets,
    required this.selectedPet,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: pets.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == pets.length) {
            return _AddPetTile(onTap: onAddNew);
          }
          final pet = pets[i];
          final isSelected = selectedPet?.id == pet.id;
          return _PetTile(
            pet: pet,
            isSelected: isSelected,
            onTap: () => onSelect(pet),
          );
        },
      ),
    );
  }
}

class _PetTile extends StatelessWidget {
  final Pet pet;
  final bool isSelected;
  final VoidCallback onTap;

  const _PetTile({
    required this.pet,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 88,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryFaint : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.subtle : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.surface,
                  backgroundImage: (pet.imageUrl?.isNotEmpty == true)
                      ? CachedNetworkImageProvider(pet.imageUrl!)
                      : null,
                  child: (pet.imageUrl?.isNotEmpty != true)
                      ? const Icon(Icons.pets_rounded,
                          size: 26, color: AppColors.textMuted)
                      : null,
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check,
                          size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                pet.name,
                style: AppTextStyles.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              pet.type,
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.textMuted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPetTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPetTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.border, style: BorderStyle.solid, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryFaint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              'הוסף חיה',
              style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
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

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeTile(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final has = time != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: has ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(10),
          color: has ? AppColors.primaryFaint : AppColors.pureWhite,
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 18, color: has ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(label,
                style: AppTextStyles.labelMd
                    .copyWith(color: AppColors.textSecondary)),
            const Spacer(),
            Text(
              has
                  ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
                  : 'בחר שעה',
              style: AppTextStyles.bodyMd.copyWith(
                color: has ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_left_rounded,
                size: 18, color: has ? AppColors.primary : AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryFaint : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: enabled ? AppColors.primary : AppColors.border),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? AppColors.primary : AppColors.textMuted),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final String label;
  const _PriceSummary({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('סה״כ משוער',
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;

  const _FieldInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMd
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
            filled: true,
            fillColor: AppColors.pureWhite,
          ),
        ),
      ],
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
