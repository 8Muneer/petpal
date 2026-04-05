import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_input.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';

class CreateSittingRequestScreen extends ConsumerStatefulWidget {
  final SittingRequest? initialRequest;

  const CreateSittingRequestScreen({super.key, this.initialRequest});

  bool get _isEditing => initialRequest != null;

  @override
  ConsumerState<CreateSittingRequestScreen> createState() =>
      _CreateSittingRequestScreenState();
}

class _CreateSittingRequestScreenState
    extends ConsumerState<CreateSittingRequestScreen> {
  final _petNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _budgetController = TextEditingController();

  PetType _petType = PetType.dog;
  PetGender? _petGender;
  XFile? _pickedImage;
  String? _existingImageUrl;
  DateTime? _startDate;
  DateTime? _endDate;
  SittingType _sittingType = SittingType.atOwnerHome;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRequest;
    if (r != null) {
      _petNameController.text = r.petName;
      _areaController.text = r.area;
      _instructionsController.text = r.specialInstructions ?? '';
      _budgetController.text = r.budget ?? '';
      _petType = r.petType;
      _petGender = r.petGender;
      _startDate = r.startDate;
      _endDate = r.endDate;
      _sittingType = r.sittingType;
      _existingImageUrl = r.petImageUrl;
    }
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _areaController.dispose();
    _instructionsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imageService = ref.read(sittingImageServiceProvider);
    final file = await imageService.pickImage(ImageSource.gallery);
    if (file != null) {
      setState(() {
        _pickedImage = file;
        _existingImageUrl = null;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before the new start date
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final firstDate = _startDate?.add(const Duration(days: 1)) ??
        DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    final petName = _petNameController.text.trim();
    final area = _areaController.text.trim();

    if (petName.isEmpty) {
      _showSnack('יש להזין את שם חיית המחמד', isError: true);
      return;
    }
    if (area.isEmpty) {
      _showSnack('יש להזין אזור/שכונה', isError: true);
      return;
    }
    if (_startDate == null) {
      _showSnack('יש לבחור תאריך התחלה', isError: true);
      return;
    }
    if (_endDate == null) {
      _showSnack('יש לבחור תאריך סיום', isError: true);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final instructions = _instructionsController.text.trim();
      final budget = _budgetController.text.trim();

      String? petImageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        final imageService = ref.read(sittingImageServiceProvider);
        final uploadId = widget._isEditing
            ? widget.initialRequest!.id
            : FirebaseFirestore.instance
                .collection('sitting_requests')
                .doc()
                .id;
        petImageUrl =
            await imageService.uploadPetImage(uploadId, _pickedImage!);
      }

      final data = {
        'petName': petName,
        'petType': _petType.name,
        'petGender': _petGender?.name,
        'petImageUrl': petImageUrl,
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'sittingType': _sittingType.name,
        'area': area,
        'specialInstructions': instructions.isNotEmpty ? instructions : null,
        'budget': budget.isNotEmpty ? budget : null,
      };

      final repo = ref.read(sittingRepositoryProvider);

      if (widget._isEditing) {
        await repo.updateRequest(widget.initialRequest!.id, data);
        if (!mounted) return;
        context.pop();
        _showSnack('הבקשה עודכנה בהצלחה!');
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
        context.pop();
        _showSnack('הבקשה פורסמה בהצלחה!');
      }
    } catch (e) {
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
            isError ? const Color(0xFFFB7185) : const Color(0xFF7C3AED),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isEditing = widget._isEditing;
    final hasImage =
        _pickedImage != null || (_existingImageUrl?.isNotEmpty == true);
    final nights = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays
        : 0;

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
                      color: const Color(0xFF0F172A),
                    ),
                    Expanded(
                      child: Text(
                        isEditing ? 'עריכת בקשת שמירה' : 'בקשת שמירה חדשה',
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // Pet name
                    _FieldLabel('שם חיית המחמד'),
                    const SizedBox(height: 6),
                    AppCard(
                      
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _petNameController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'לדוגמה: בלה',
                          hintStyle: TextStyle(
                            color: const Color(0xFF64748B).withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                          prefixIcon: const Icon(Icons.pets_rounded,
                              color: Color(0xFF7C3AED)),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pet type
                    _FieldLabel('סוג חיית המחמד'),
                    const SizedBox(height: 6),
                    AppCard(
                      
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          _buildPetTypeChip(
                              'כלב', PetType.dog, Icons.directions_walk_rounded),
                          const SizedBox(width: 8),
                          _buildPetTypeChip(
                              'חתול', PetType.cat, Icons.pets_rounded),
                          const SizedBox(width: 8),
                          _buildPetTypeChip(
                              'אחר', PetType.other, Icons.cruelty_free_rounded),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pet gender
                    _FieldLabel('מין חיית המחמד (אופציונלי)'),
                    const SizedBox(height: 6),
                    AppCard(
                      
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          _buildGenderChip(
                              'זכר', PetGender.male, Icons.male_rounded),
                          const SizedBox(width: 8),
                          _buildGenderChip(
                              'נקבה', PetGender.female, Icons.female_rounded),
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
                                      ? const Color(0xFF64748B)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        Icons.remove_circle_outline_rounded,
                                        size: 18,
                                        color: _petGender == null
                                            ? Colors.white
                                            : const Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'לא ידוע',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: _petGender == null
                                            ? Colors.white
                                            : const Color(0xFF64748B),
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

                    // Sitting type
                    _FieldLabel('מיקום השמירה'),
                    const SizedBox(height: 6),
                    AppCard(
                      
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          _buildSittingTypeChip(
                            'בבית הבעלים',
                            SittingType.atOwnerHome,
                            Icons.home_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildSittingTypeChip(
                            'בבית השומר/ת',
                            SittingType.atSitterHome,
                            Icons.house_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Pet photo
                    _FieldLabel('תמונה של חיית המחמד (אופציונלי)'),
                    const SizedBox(height: 6),
                    if (hasImage) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _pickedImage != null
                                ? Image.file(
                                    File(_pickedImage!.path),
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _existingImageUrl!,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: InkWell(
                              onTap: _removeImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _pickImage,
                        child: AppCard(
                          
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color:
                                    const Color(0xFF64748B).withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'הוסף/י תמונה של החיה',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B)
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Date range row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('תאריך התחלה'),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: _pickStartDate,
                                child: AppCard(
                                  
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 20,
                                          color: Color(0xFF7C3AED)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _startDate != null
                                              ? _formatDate(_startDate!)
                                              : 'בחר/י תאריך',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _startDate != null
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF64748B)
                                                    .withOpacity(0.6),
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
                              _FieldLabel('תאריך סיום'),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: _pickEndDate,
                                child: AppCard(
                                  
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 20,
                                          color: Color(0xFF7C3AED)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _endDate != null
                                              ? _formatDate(_endDate!)
                                              : 'בחר/י תאריך',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _endDate != null
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF64748B)
                                                    .withOpacity(0.6),
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

                    // Nights counter badge
                    if (nights > 0) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF7C3AED).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$nights לילות',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Area
                    _FieldLabel('אזור / שכונה'),
                    const SizedBox(height: 6),
                    AppCard(
                      
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _areaController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'לדוגמה: רמת אביב, תל אביב',
                          hintStyle: TextStyle(
                            color: const Color(0xFF64748B).withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                          prefixIcon: const Icon(Icons.location_on_rounded,
                              color: Color(0xFF7C3AED)),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Special instructions
                    _FieldLabel('הוראות מיוחדות (אופציונלי)'),
                    const SizedBox(height: 6),
                    AppCard(
                      
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _instructionsController,
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'לדוגמה: החתולה אוכלת רק מזון יבש, צריך לנקות ארגז חול פעם ביום...',
                          hintStyle: TextStyle(
                            color: const Color(0xFF64748B).withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Budget
                    _FieldLabel('תקציב (אופציונלי)'),
                    const SizedBox(height: 6),
                    AppCard(
                      
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _budgetController,
                        textDirection: TextDirection.rtl,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'לדוגמה: ₪80-₪120 ללילה',
                          hintStyle: TextStyle(
                            color: const Color(0xFF64748B).withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                          prefixIcon: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color(0xFF7C3AED)),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
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
                            colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
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
            color: selected ? const Color(0xFF7C3AED) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: selected ? Colors.white : const Color(0xFF64748B),
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
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFFEC4899))
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSittingTypeChip(
      String label, SittingType type, IconData icon) {
    final selected = _sittingType == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _sittingType = type),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? const Color(0xFF7C3AED) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: selected ? Colors.white : const Color(0xFF64748B),
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
        color: Color(0xFF334155),
      ),
    );
  }
}
