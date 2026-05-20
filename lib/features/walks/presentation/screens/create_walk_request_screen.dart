import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/core/widgets/location_picker_field.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';

class CreateWalkRequestScreen extends ConsumerStatefulWidget {
  /// When non-null the screen operates in edit mode.
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

  PetType _petType = PetType.dog;
  PetGender? _petGender;
  List<XFile> _pickedImages = [];
  List<String> _existingImageUrls = [];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _duration = 'שעה';
  bool _isPublishing = false;

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
      _existingImageUrls = List.of(r.allImages);
      _duration = r.duration;
      // Parse stored time string "HH:MM"
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

  static const _maxImages = 5;

  bool get _canAddMore =>
      (_existingImageUrls.length + _pickedImages.length) < _maxImages;

  Future<void> _addImages() async {
    if (!_canAddMore) return;
    final imageService = ref.read(walkImageServiceProvider);
    final picked = await imageService.pickImages();
    if (picked.isEmpty) return;
    setState(() {
      final remaining = _maxImages - _existingImageUrls.length - _pickedImages.length;
      _pickedImages.addAll(picked.take(remaining));
    });
  }

  void _removeExistingImage(int index) =>
      setState(() => _existingImageUrls.removeAt(index));

  void _removePickedImage(int index) =>
      setState(() => _pickedImages.removeAt(index));

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

      // Upload newly picked images and combine with existing URLs
      List<String> allUrls = List.of(_existingImageUrls);
      if (_pickedImages.isNotEmpty) {
        final imageService = ref.read(walkImageServiceProvider);
        final uploadId = widget._isEditing
            ? widget.initialRequest!.id
            : FirebaseFirestore.instance.collection('walk_requests').doc().id;
        final newUrls = await imageService.uploadPetImages(uploadId, _pickedImages);
        allUrls.addAll(newUrls);
      }

      final data = {
        'petName': petName,
        'petType': _petType.name,
        'preferredDate': Timestamp.fromDate(_selectedDate!),
        'preferredTime': timeStr,
        'duration': _duration,
        'area': area,
        'petImageUrl': allUrls.isNotEmpty ? allUrls.first : null,
        'petImageUrls': allUrls,
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
        backgroundColor:
            isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget._isEditing;
    final totalImages = _existingImageUrls.length + _pickedImages.length;

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
                    // Pet name
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
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.6),
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

                    // Pet type
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

                    // Pet gender
                    const _FieldLabel('מין חיית המחמד (אופציונלי)'),
                    const SizedBox(height: 6),
                    AppCard(
                      
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          _buildGenderChip('זכר', PetGender.male,
                              Icons.male_rounded),
                          const SizedBox(width: 8),
                          _buildGenderChip('נקבה', PetGender.female,
                              Icons.female_rounded),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () =>
                                  setState(() => _petGender = null),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: _petGender == null
                                      ? AppColors.textSecondary
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
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

                    // Pet photos (multi-image)
                    const _FieldLabel('תמונות של חיית המחמד (אופציונלי)'),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Existing (network) thumbnails
                          for (int i = 0; i < _existingImageUrls.length; i++)
                            _ImageThumb(
                              child: Image.network(
                                _existingImageUrls[i],
                                fit: BoxFit.cover,
                              ),
                              onRemove: () => _removeExistingImage(i),
                            ),
                          // Newly picked (local) thumbnails
                          for (int i = 0; i < _pickedImages.length; i++)
                            _ImageThumb(
                              child: Image.file(
                                File(_pickedImages[i].path),
                                fit: BoxFit.cover,
                              ),
                              onRemove: () => _removePickedImage(i),
                            ),
                          // Add button
                          if (_canAddMore)
                            GestureDetector(
                              onTap: _addImages,
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFaint,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 28,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.7)),
                                    const SizedBox(height: 4),
                                    Text(
                                      totalImages == 0
                                          ? 'הוסף תמונה'
                                          : 'הוסף עוד',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.8),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

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
                                      const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 20,
                                          color: AppColors.primary),
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
                                      const Icon(
                                          Icons.access_time_rounded,
                                          size: 20,
                                          color: AppColors.primary),
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
                                        left: d == _durations.last
                                            ? 0
                                            : 6),
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
                        keyboardType: TextInputType.text,
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
                              AppColors.statusOpen
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
                  color:
                      selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color:
                      selected ? Colors.white : AppColors.textSecondary,
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

class _ImageThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ImageThumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 110,
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: child,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
