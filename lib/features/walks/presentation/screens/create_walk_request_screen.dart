import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/widgets/location_picker_field.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/pets/domain/entities/pet.dart';
import 'package:petpal/features/pets/presentation/providers/pets_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';

class CreateWalkRequestScreen extends ConsumerStatefulWidget {
  final WalkRequest? initialRequest;
  const CreateWalkRequestScreen({super.key, this.initialRequest});

  bool get _isEditing => initialRequest != null;

  @override
  ConsumerState<CreateWalkRequestScreen> createState() =>
      _CreateWalkRequestScreenState();
}

class _CreateWalkRequestScreenState
    extends ConsumerState<CreateWalkRequestScreen> {
  final _petNameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _budgetController = TextEditingController();
  String _area = '';

  Pet? _selectedPet;
  PetType _petType = PetType.dog;
  PetGender? _petGender;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _duration = 'שעה';
  bool _isPublishing = false;

  // In edit mode, preserve existing image data
  String? _existingPetImageUrl;
  List<String> _existingPetImageUrls = [];

  static const _durations = ['30 דקות', 'שעה', 'שעה וחצי', 'שעתיים'];

  @override
  void initState() {
    super.initState();
    final r = widget.initialRequest;
    if (r != null) {
      _petNameController.text = r.petName;
      _area = r.area;
      _instructionsController.text = r.specialInstructions ?? '';
      _budgetController.text = r.budget ?? '';
      _petType = r.petType;
      _petGender = r.petGender;
      _selectedDate = r.preferredDate;
      _existingPetImageUrl = r.petImageUrl;
      _existingPetImageUrls = List.of(r.petImageUrls);
      _duration = r.duration;
      final parts = r.preferredTime.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _selectedTime = TimeOfDay(hour: h, minute: m);
        }
      }
    }
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _instructionsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _onPetSelected(Pet pet) {
    setState(() {
      _selectedPet = pet;
      _petNameController.text = pet.name;
      _petType = switch (pet.type) {
        'כלב' => PetType.dog,
        'חתול' => PetType.cat,
        _ => PetType.other,
      };
      _petGender = switch (pet.gender) {
        'זכר' => PetGender.male,
        'נקבה' => PetGender.female,
        _ => null,
      };
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(context).copyWith(
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 17, minute: 0),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(context).copyWith(
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
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    final petName = _petNameController.text.trim();
    final area = _area.trim();

    if (!widget._isEditing && _selectedPet == null) {
      _showSnack('יש לבחור חיית מחמד', isError: true);
      return;
    }
    if (petName.isEmpty) {
      _showSnack('יש להזין את שם חיית המחמד', isError: true);
      return;
    }
    if (area.isEmpty) {
      _showSnack('יש להזין אזור/שכונה', isError: true);
      return;
    }
    if (_selectedDate == null) {
      _showSnack('יש לבחור תאריך', isError: true);
      return;
    }
    if (_selectedTime == null) {
      _showSnack('יש לבחור שעה', isError: true);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isPublishing = false);
        _showSnack('יש להתחבר כדי לפרסם בקשה', isError: true);
        return;
      }

      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      final instructions = _instructionsController.text.trim();
      final budget = _budgetController.text.trim();

      // Use pet profile image (create) or preserve existing (edit)
      final petImgUrl = widget._isEditing
          ? _existingPetImageUrl
          : _selectedPet?.imageUrl;
      final petImgUrls = widget._isEditing
          ? _existingPetImageUrls
          : [if (_selectedPet?.imageUrl != null) _selectedPet!.imageUrl!];

      final data = {
        'petName': petName,
        'petType': _petType.name,
        'preferredDate': Timestamp.fromDate(_selectedDate!),
        'preferredTime': timeStr,
        'duration': _duration,
        'area': area,
        'petImageUrl': petImgUrl,
        'petImageUrls': petImgUrls,
        'specialInstructions': instructions.isNotEmpty ? instructions : null,
        'budget': budget.isNotEmpty ? budget : null,
        'petGender': _petGender?.name,
      };

      final repo = ref.read(walkRepositoryProvider);

      if (widget._isEditing) {
        await repo.updateRequest(widget.initialRequest!.id, data);
        if (!mounted) return;
        _showSnack('הבקשה עודכנה בהצלחה!');
        context.pop();
      } else {
        await repo.createRequest({
          ...data,
          'ownerUid': user.uid,
          'ownerName': user.displayName ?? user.email?.split('@').first ?? '',
          'ownerPhotoUrl': user.photoURL,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        _showSnack('הבקשה פורסמה בהצלחה!');
        context.pop();
      }
    } catch (e, stack) {
      debugPrint('_save walk error: $e\n$stack');
      if (!mounted) return;
      setState(() => _isPublishing = false);
      _showSnack(
        widget._isEditing ? 'שגיאה בעדכון הבקשה' : 'שגיאה בפרסום הבקשה',
        isError: true,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
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
    final isEditing = widget._isEditing;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: AppColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        isEditing ? 'עריכת בקשת טיול' : 'בקשת טיול חדשה',
                        style: const TextStyle(
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // ── Pet selector (create) / name+type+gender (edit) ──
                    if (!isEditing) ...[
                      const _FieldLabel('בחר חיית מחמד'),
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
                        data: (pets) => _PetSelectorRow(
                          pets: pets,
                          selectedPet: _selectedPet,
                          onSelect: _onPetSelected,
                          onAddNew: () => context.push('/my-pets'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const _FieldLabel('שם חיית המחמד'),
                      const SizedBox(height: 6),
                      AppCard(
                        padding: const EdgeInsets.all(4),
                        child: TextField(
                          controller: _petNameController,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            hintText: 'לדוגמה: רקסי',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                            prefixIcon: const Icon(Icons.pets_rounded,
                                color: AppColors.primary),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('סוג חיית המחמד'),
                      const SizedBox(height: 6),
                      AppCard(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            _buildPetTypeChip('כלב', PetType.dog,
                                Icons.directions_walk_rounded),
                            const SizedBox(width: 8),
                            _buildPetTypeChip(
                                'חתול', PetType.cat, Icons.pets_rounded),
                            const SizedBox(width: 8),
                            _buildPetTypeChip('אחר', PetType.other,
                                Icons.cruelty_free_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('מין חיית המחמד (אופציונלי)'),
                      const SizedBox(height: 6),
                      AppCard(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            _buildGenderChip(
                                'זכר', PetGender.male, Icons.male_rounded),
                            const SizedBox(width: 8),
                            _buildGenderChip('נקבה', PetGender.female,
                                Icons.female_rounded),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => setState(() => _petGender = null),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: _petGender == null
                                        ? AppColors.textSecondary
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.remove_circle_outline_rounded,
                                          size: 18,
                                          color: _petGender == null
                                              ? Colors.white
                                              : AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'לא ידוע',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          color: _petGender == null
                                              ? Colors.white
                                              : AppColors.textSecondary,
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
                      const SizedBox(height: 16),
                    ],

                    // Date & Time row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('תאריך'),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: _pickDate,
                                child: AppCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 20, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _selectedDate != null
                                              ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                                              : 'בחר/י תאריך',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedDate != null
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
                              const _FieldLabel('שעה'),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: _pickTime,
                                child: AppCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 20, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _selectedTime != null
                                              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                              : 'בחר/י שעה',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedTime != null
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

                    // Duration
                    const _FieldLabel('משך הטיול'),
                    const SizedBox(height: 6),
                    AppCard(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: _durations
                            .map((d) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: d == _durations.last ? 0 : 6),
                                    child: _buildDurationChip(d),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Area
                    const _FieldLabel('מיקום'),
                    const SizedBox(height: 6),
                    LocationPickerField(
                      initialValue: _area,
                      onChanged: (val) => setState(() => _area = val),
                    ),

                    const SizedBox(height: 16),

                    // Special instructions
                    const _FieldLabel('הוראות מיוחדות (אופציונלי)'),
                    const SizedBox(height: 6),
                    AppCard(
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _instructionsController,
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'למשל: הכלב מפחד מכלבים גדולים, צריך רצועה קצרה...',
                          hintStyle: TextStyle(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.6),
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

                    // Budget
                    const _FieldLabel('תקציב (אופציונלי)'),
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
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.6),
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

                    const SizedBox(height: 24),

                    // Save button
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _isPublishing ? null : _save,
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
                              : Text(
                                  isEditing ? 'עדכן בקשה' : 'פרסם/י בקשה',
                                  style: const TextStyle(
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

  Widget _buildPetTypeChip(String label, PetType type, IconData icon) {
    final selected = _petType == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _petType = type),
        child: Container(
          height: 44,
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

  Widget _buildGenderChip(String label, PetGender gender, IconData icon) {
    final selected = _petGender == gender;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _petGender = gender),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? (gender == PetGender.male
                    ? AppColors.smartBlue
                    : AppColors.error)
                : Colors.transparent,
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

  Widget _buildDurationChip(String label) {
    final selected = _duration == label;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _duration = label),
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
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _PetSelectorRow extends StatelessWidget {
  final List<Pet> pets;
  final Pet? selectedPet;
  final ValueChanged<Pet> onSelect;
  final VoidCallback onAddNew;

  const _PetSelectorRow({
    required this.pets,
    required this.selectedPet,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: pets.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == pets.length) {
            return GestureDetector(
              onTap: onAddNew,
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFaint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'הוסף חיה',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final pet = pets[i];
          final isSelected = selectedPet?.id == pet.id;
          return GestureDetector(
            onTap: () => onSelect(pet),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 80,
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primaryFaint : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.surface,
                        backgroundImage: (pet.imageUrl?.isNotEmpty == true)
                            ? CachedNetworkImageProvider(pet.imageUrl!)
                            : null,
                        child: (pet.imageUrl?.isNotEmpty != true)
                            ? const Icon(Icons.pets_rounded,
                                size: 22, color: AppColors.textMuted)
                            : null,
                      ),
                      if (isSelected)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check,
                                size: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      pet.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    pet.type,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
