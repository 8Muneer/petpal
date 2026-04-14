import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/location_picker_field.dart';
import 'package:petpal/features/lost_and_found/data/models/lost_found_post_model.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_provider.dart';

class CreateLostFoundPostScreen extends ConsumerStatefulWidget {
  const CreateLostFoundPostScreen({super.key});

  @override
  ConsumerState<CreateLostFoundPostScreen> createState() =>
      _CreateLostFoundPostScreenState();
}

class _CreateLostFoundPostScreenState
    extends ConsumerState<CreateLostFoundPostScreen> {
  final _formKey = GlobalKey<FormState>();
  LostFoundType _type = LostFoundType.lost;
  XFile? _imageFile;
  final _petNameController = TextEditingController();
  String _species = 'כלב';
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _area = '';
  bool _isLoading = false;

  static const _speciesOptions = ['כלב', 'חתול', 'ציפור', 'ארנב', 'אחר'];

  @override
  void dispose() {
    _petNameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file != null) setState(() => _imageFile = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showError('נא לצרף תמונה של החיה');
      return;
    }
    if (_area.isEmpty) {
      _showError('נא לשתף מיקום');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final post = LostFoundPostModel(
        id: '',
        reporterUid: currentUserUid,
        reporterName: currentUserName,
        reporterPhotoUrl: currentUserPhoto,
        type: _type,
        petName: _petNameController.text.trim(),
        species: _species,
        breed: _breedController.text.trim(),
        color: _colorController.text.trim(),
        description: _descriptionController.text.trim(),
        area: _area,
        imageUrl: '',
      );

      final createFn = ref.read(createLostFoundPostProvider);
      await createFn(post, _imageFile!);

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF10B981),
          content: const Text(
            'הדיווח פורסם! ה-AI מחפש התאמות...',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    } catch (e) {
      _showError('שגיאה בפרסום: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFB7185),
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            'דיווח חדש',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Type selector
              _buildTypeSelector(),
              const SizedBox(height: 20),

              // Image picker
              _buildImagePicker(),
              const SizedBox(height: 20),

              // Pet name
              _buildLabel('שם החיה (אופציונלי)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _petNameController,
                hint: 'למשל: רקס, לולה',
              ),
              const SizedBox(height: 16),

              // Species
              _buildLabel('סוג חיה'),
              const SizedBox(height: 8),
              _buildSpeciesSelector(),
              const SizedBox(height: 16),

              // Breed
              _buildLabel('גזע'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _breedController,
                hint: 'למשל: לברדור, פרסי',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 16),

              // Color
              _buildLabel('צבע / תיאור מראה'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _colorController,
                hint: 'למשל: חום בהיר עם כתמים לבנים',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel('פרטים נוספים'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint:
                    _type == LostFoundType.lost
                        ? 'מתי ואיפה נעלם, סימנים מיוחדים...'
                        : 'היכן נמצא, מצב בריאות, התנהגות...',
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 16),

              // Location
              _buildLabel('מיקום'),
              const SizedBox(height: 8),
              LocationPickerField(
                initialValue: _area,
                onChanged: (val) => setState(() => _area = val),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB7185),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'פרסם דיווח',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _TypeButton(
            label: 'החיה שלי אבדה',
            icon: Icons.search_rounded,
            selected: _type == LostFoundType.lost,
            color: const Color(0xFFFB7185),
            onTap: () => setState(() => _type = LostFoundType.lost),
          ),
          _TypeButton(
            label: 'מצאתי חיה',
            icon: Icons.favorite_rounded,
            selected: _type == LostFoundType.found,
            color: const Color(0xFF60A5FA),
            onTap: () => setState(() => _type = LostFoundType.found),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _imageFile == null
                ? const Color(0xFFE5E7EB)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: _imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB7185).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_photo_alternate_rounded,
                        color: Color(0xFFFB7185), size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'הוסף תמונה של החיה',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'התמונה תשמש להתאמה עם AI',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'החלף תמונה',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
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

  Widget _buildSpeciesSelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _speciesOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _speciesOptions[i];
          final selected = _species == s;
          return GestureDetector(
            onTap: () => setState(() => _species = s),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFB7185)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFB7185)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Color(0xFF1A1A2E)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFB7185), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFB7185)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
