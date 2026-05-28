import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/location_picker_field.dart';
import 'package:petpal/core/widgets/request_form_widgets.dart';
import 'package:petpal/features/pets/domain/entities/pet.dart';
import 'package:petpal/features/pets/presentation/providers/pets_provider.dart';
import 'package:petpal/features/service_request/data/models/service_request_model.dart';
import 'package:petpal/features/service_request/domain/entities/service_request.dart';
import 'package:petpal/features/service_request/presentation/providers/service_request_provider.dart';

class CreateServiceRequestScreen extends ConsumerStatefulWidget {
  const CreateServiceRequestScreen({super.key});

  @override
  ConsumerState<CreateServiceRequestScreen> createState() =>
      _CreateServiceRequestScreenState();
}

class _CreateServiceRequestScreenState
    extends ConsumerState<CreateServiceRequestScreen> {
  final _instructionsController = TextEditingController();
  final _budgetController = TextEditingController();

  ServiceType _serviceType = ServiceType.walk;
  Pet? _selectedPet;
  String _area = '';

  // Walk fields
  DateTime? _walkDate;
  TimeOfDay? _walkTime;
  String _walkDuration = 'שעה';

  // Sitting fields
  DateTime? _sittingStart;
  DateTime? _sittingEnd;
  SittingLocation _sittingLocation = SittingLocation.atOwnerHome;

  bool _isPublishing = false;

  static const _durations = ['30 דקות', 'שעה', 'שעה וחצי', 'שעתיים'];

  @override
  void dispose() {
    _instructionsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _onPetSelected(Pet pet) => setState(() => _selectedPet = pet);

  PetSpecies _toPetSpecies(String type) => switch (type) {
        'חתול' => PetSpecies.cat,
        'ארנב' => PetSpecies.rabbit,
        'ציפור' => PetSpecies.bird,
        'אחר' => PetSpecies.other,
        _ => PetSpecies.dog,
      };

  PetGender? _toPetGender(String? gender) => switch (gender) {
        'זכר' => PetGender.male,
        'נקבה' => PetGender.female,
        _ => null,
      };

  Future<void> _pickDate({required bool isSittingStart}) async {
    final now = DateTime.now();
    final initial = isSittingStart
        ? (_sittingStart ?? now)
        : (_walkDate ?? now);
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked == null) return;
    setState(() {
      if (isSittingStart) {
        _sittingStart = picked;
        if (_sittingEnd != null && !_sittingEnd!.isAfter(picked)) {
          _sittingEnd = null;
        }
      } else {
        _walkDate = picked;
      }
    });
  }

  Future<void> _pickSittingEnd() async {
    final firstDate = _sittingStart?.add(const Duration(days: 1)) ??
        DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _sittingEnd ?? firstDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) setState(() => _sittingEnd = picked);
  }

  Future<void> _pickWalkTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _walkTime ?? const TimeOfDay(hour: 17, minute: 0),
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) setState(() => _walkTime = picked);
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) =>
      Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        ),
      );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _submit() async {
    if (_selectedPet == null) {
      _snack('יש לבחור חיית מחמד', isError: true);
      return;
    }
    if (_area.trim().isEmpty) {
      _snack('יש להזין אזור/שכונה', isError: true);
      return;
    }
    if (_serviceType == ServiceType.walk) {
      if (_walkDate == null) {
        _snack('יש לבחור תאריך', isError: true);
        return;
      }
      if (_walkTime == null) {
        _snack('יש לבחור שעה', isError: true);
        return;
      }
    } else {
      if (_sittingStart == null) {
        _snack('יש לבחור תאריך התחלה', isError: true);
        return;
      }
      if (_sittingEnd == null) {
        _snack('יש לבחור תאריך סיום', isError: true);
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('יש להתחבר כדי לפרסם', isError: true);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final pet = _selectedPet!;
      final timeStr = _walkTime != null
          ? '${_walkTime!.hour.toString().padLeft(2, '0')}:${_walkTime!.minute.toString().padLeft(2, '0')}'
          : null;

      final model = ServiceRequestModel(
        id: '',
        ownerUid: user.uid,
        ownerName: user.displayName ?? user.email?.split('@').first ?? '',
        ownerPhotoUrl: user.photoURL,
        petName: pet.name,
        petSpecies: _toPetSpecies(pet.type),
        petGender: _toPetGender(pet.gender),
        petImageUrls: [if (pet.imageUrl?.isNotEmpty == true) pet.imageUrl!],
        serviceType: _serviceType,
        area: _area.trim(),
        specialInstructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        budget: _budgetController.text.trim().isNotEmpty
            ? _budgetController.text.trim()
            : null,
        walkDate: _serviceType == ServiceType.walk ? _walkDate : null,
        walkTime: _serviceType == ServiceType.walk ? timeStr : null,
        walkDuration: _serviceType == ServiceType.walk ? _walkDuration : null,
        sittingStartDate:
            _serviceType == ServiceType.sitting ? _sittingStart : null,
        sittingEndDate:
            _serviceType == ServiceType.sitting ? _sittingEnd : null,
        sittingLocation:
            _serviceType == ServiceType.sitting ? _sittingLocation : null,
      );

      await ref
          .read(serviceRequestNotifierProvider.notifier)
          .createRequest(model);

      if (!mounted) return;
      _snack('הבקשה פורסמה בהצלחה!');
      context.pop();
    } catch (e) {
      debugPrint('CreateServiceRequest error: $e');
      if (!mounted) return;
      setState(() => _isPublishing = false);
      _snack('שגיאה בפרסום הבקשה', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWalk = _serviceType == ServiceType.walk;
    final nights = (_sittingStart != null && _sittingEnd != null)
        ? _sittingEnd!.difference(_sittingStart!).inDays
        : 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: AppColors.textPrimary,
                    ),
                    const Expanded(
                      child: Text(
                        'בקשת שירות חדשה',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    // ── Service type selector ────────────────────────────
                    const RequestFieldLabel('סוג שירות'),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          _typeChip(
                            label: 'טיול',
                            icon: Icons.directions_walk_rounded,
                            type: ServiceType.walk,
                          ),
                          const SizedBox(width: 8),
                          _typeChip(
                            label: 'שמירה',
                            icon: Icons.home_rounded,
                            type: ServiceType.sitting,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Pet selector ─────────────────────────────────────
                    const RequestFieldLabel('בחר חיית מחמד'),
                    const SizedBox(height: 8),
                    ref.watch(userPetsProvider).when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            ),
                          ),
                          error: (e, _) => Text('שגיאה: $e'),
                          data: (pets) => PetSelectorRow(
                            pets: pets,
                            selectedPet: _selectedPet,
                            onSelect: _onPetSelected,
                            onAddNew: () => context.push('/my-pets'),
                          ),
                        ),

                    const SizedBox(height: 16),

                    // ── Walk-specific fields ─────────────────────────────
                    if (isWalk) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const RequestFieldLabel('תאריך'),
                                const SizedBox(height: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () =>
                                      _pickDate(isSittingStart: false),
                                  child: AppCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 20,
                                            color: AppColors.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _walkDate != null
                                                ? _formatDate(_walkDate!)
                                                : 'בחר/י תאריך',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _walkDate != null
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary
                                                      .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const RequestFieldLabel('שעה'),
                                const SizedBox(height: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: _pickWalkTime,
                                  child: AppCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded,
                                            size: 20,
                                            color: AppColors.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _walkTime != null
                                                ? '${_walkTime!.hour.toString().padLeft(2, '0')}:${_walkTime!.minute.toString().padLeft(2, '0')}'
                                                : 'בחר/י שעה',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _walkTime != null
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary
                                                      .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const RequestFieldLabel('משך הטיול'),
                      const SizedBox(height: 6),
                      AppCard(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: _durations
                              .map((d) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          left: d == _durations.last ? 0 : 6),
                                      child: _durationChip(d),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Sitting-specific fields ──────────────────────────
                    if (!isWalk) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const RequestFieldLabel('תאריך התחלה'),
                                const SizedBox(height: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () =>
                                      _pickDate(isSittingStart: true),
                                  child: AppCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 20,
                                            color: AppColors.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _sittingStart != null
                                                ? _formatDate(_sittingStart!)
                                                : 'מתאריך',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _sittingStart != null
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary
                                                      .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const RequestFieldLabel('תאריך סיום'),
                                const SizedBox(height: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: _pickSittingEnd,
                                  child: AppCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.event_available_rounded,
                                            size: 20,
                                            color: AppColors.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _sittingEnd != null
                                                ? _formatDate(_sittingEnd!)
                                                : 'עד תאריך',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _sittingEnd != null
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary
                                                      .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (nights > 0) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            '$nights לילות',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const RequestFieldLabel('מיקום השמירה'),
                      const SizedBox(height: 6),
                      AppCard(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            _locationChip(
                              label: 'בבית שלי',
                              icon: Icons.home_rounded,
                              loc: SittingLocation.atOwnerHome,
                            ),
                            const SizedBox(width: 8),
                            _locationChip(
                              label: 'בבית המטפל',
                              icon: Icons.house_siding_rounded,
                              loc: SittingLocation.atSitterHome,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Common: area ─────────────────────────────────────
                    const RequestFieldLabel('מיקום / שכונה'),
                    const SizedBox(height: 6),
                    LocationPickerField(
                      initialValue: _area,
                      onChanged: (val) => setState(() => _area = val),
                    ),

                    const SizedBox(height: 16),

                    // ── Special instructions ─────────────────────────────
                    const RequestFieldLabel('הוראות מיוחדות (אופציונלי)'),
                    const SizedBox(height: 6),
                    AppCard(
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _instructionsController,
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'למשל: הכלב מפחד מכלבים גדולים...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Budget ────────────────────────────────────────────
                    const RequestFieldLabel('תקציב (אופציונלי)'),
                    const SizedBox(height: 6),
                    AppCard(
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _budgetController,
                        textDirection: TextDirection.rtl,
                        keyboardType: TextInputType.phone,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'לדוגמה: ₪50-₪80',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                          prefixIcon: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.primary),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Submit ─────────────────────────────────────────────
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _isPublishing ? null : _submit,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              AppColors.primary,
                              AppColors.statusOpen,
                            ],
                          ),
                        ),
                        child: Center(
                          child: _isPublishing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'פרסם/י בקשה',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
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

  Widget _typeChip({
    required String label,
    required IconData icon,
    required ServiceType type,
  }) {
    final selected = _serviceType == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _serviceType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? AppColors.primary : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationChip(String label) {
    final selected = _walkDuration == label;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _walkDuration = label),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? AppColors.primary : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationChip({
    required String label,
    required IconData icon,
    required SittingLocation loc,
  }) {
    final selected = _sittingLocation == loc;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _sittingLocation = loc),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? AppColors.primary : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
