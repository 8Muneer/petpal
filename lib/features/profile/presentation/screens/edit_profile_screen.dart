import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/input_field.dart';
import 'package:petpal/core/widgets/primary_gradient_button.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/profile/domain/entities/user_profile.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _initialized = false;

  void _initFields(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.name;
    _phoneController.text = profile.phone ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFB91C1C) : const Color(0xFF0F766E),
      ),
    );
  }

  void _showImagePickerSheet(UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'שינוי תמונת פרופיל',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 18),
                _ImagePickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'צלם/י תמונה',
                  color: const Color(0xFF0F766E),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUpload(profile, ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                _ImagePickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'בחר/י מהגלריה',
                  color: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUpload(profile, ImageSource.gallery);
                  },
                ),
                if (profile.photoUrl != null &&
                    profile.photoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ImagePickerOption(
                    icon: Icons.delete_outline_rounded,
                    label: 'הסר תמונה',
                    color: const Color(0xFF9F1239),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removePhoto(profile);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(UserProfile profile, ImageSource source) async {
    final imageService = ref.read(profileImageServiceProvider);

    final file = await imageService.pickImage(source);
    if (file == null) return; // user cancelled

    setState(() => _isUploadingImage = true);

    try {
      final url = await imageService.uploadProfileImage(profile.uid, file);

      // Save URL to Firestore
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(profile.uid, {'photoUrl': url});

      // Sync to Firebase Auth so home screens can access it
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);

      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showSnack('התמונה עודכנה בהצלחה ✅');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showSnack('שגיאה בהעלאת התמונה', isError: true);
    }
  }

  Future<void> _removePhoto(UserProfile profile) async {
    setState(() => _isUploadingImage = true);

    try {
      final imageService = ref.read(profileImageServiceProvider);
      await imageService.deleteProfileImage(profile.uid);

      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(profile.uid, {'photoUrl': null});

      // Sync to Firebase Auth
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);

      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showSnack('התמונה הוסרה');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showSnack('שגיאה בהסרת התמונה', isError: true);
    }
  }

  Future<void> _save(UserProfile profile) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('אנא הזן/י שם', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'name': name,
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'bio': _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      'location': _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    };

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.updateProfile(profile.uid, data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) =>
          _showSnack('שגיאה בשמירה: ${failure.message}', isError: true),
      (_) {
        _showSnack('הפרופיל עודכן בהצלחה ✅');
        context.pop();
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _initial(String name, String email) {
    final n = name.trim();
    if (n.isNotEmpty) return n.characters.first.toUpperCase();
    if (email.contains('@')) {
      return email.split('@').first.characters.first.toUpperCase();
    }
    return 'P';
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.petOwner:
        return 'בעל חיית מחמד';
      case UserRole.serviceProvider:
        return 'מטפל/ת';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PetPalScaffold(
        body: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('שגיאה בטעינת הפרופיל')),
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('לא נמצא פרופיל'));
              }

              _initFields(profile);

              final hasPhoto = profile.photoUrl != null &&
                  profile.photoUrl!.isNotEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'עריכת פרופיל',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Avatar Hero Card ──
                    GlassCard(
                      useBlur: true,
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          // Tappable avatar
                          GestureDetector(
                            onTap: _isUploadingImage
                                ? null
                                : () => _showImagePickerSheet(profile),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    gradient: hasPhoto
                                        ? null
                                        : const LinearGradient(
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                            colors: [
                                              Color(0xFF0F766E),
                                              Color(0xFF22C55E),
                                            ],
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F766E)
                                            .withOpacity(0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                    image: hasPhoto
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                profile.photoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: hasPhoto
                                      ? null
                                      : Center(
                                          child: Text(
                                            _initial(
                                                profile.name, profile.email),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 32,
                                            ),
                                          ),
                                        ),
                                ),
                                // Upload overlay
                                if (_isUploadingImage)
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      color: Colors.black.withOpacity(0.45),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  // Camera badge
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.12),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'לחץ/י לשינוי תמונה',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  const Color(0xFF64748B).withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Email (read-only)
                          Text(
                            profile.email,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155)
                                  .withOpacity(0.82),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E)
                                  .withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _roleLabel(profile.role),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Personal Details Section ──
                    const _SectionLabel(
                      icon: Icons.person_rounded,
                      label: 'פרטים אישיים',
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      useBlur: false,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          InputField(
                            controller: _nameController,
                            label: 'שם מלא',
                            hint: 'הזן/י שם',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 14),
                          // Email read-only field
                          TextField(
                            controller:
                                TextEditingController(text: profile.email),
                            readOnly: true,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: const Color(0xFF334155)
                                  .withOpacity(0.6),
                            ),
                            decoration: InputDecoration(
                              labelText: 'אימייל',
                              prefixIcon:
                                  const Icon(Icons.email_outlined),
                              suffixIcon: const Icon(Icons.lock_outline,
                                  size: 18, color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: const Color(0xFFE2E8F0)
                                        .withOpacity(0.9)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Contact Details Section ──
                    const _SectionLabel(
                      icon: Icons.contact_phone_rounded,
                      label: 'פרטי התקשרות',
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      useBlur: false,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          InputField(
                            controller: _phoneController,
                            label: 'טלפון',
                            hint: '050-1234567',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          InputField(
                            controller: _locationController,
                            label: 'מיקום',
                            hint: 'תל אביב',
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Bio Section ──
                    const _SectionLabel(
                      icon: Icons.info_outline_rounded,
                      label: 'קצת עלי',
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      useBlur: false,
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _bioController,
                        maxLines: 4,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'ספר/י קצת על עצמך...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.65),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: const Color(0xFFE2E8F0)
                                    .withOpacity(0.9)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFF0F766E), width: 1.6),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Save Button ──
                    PrimaryGradientButton(
                      text: _isLoading ? 'שומר...' : 'שמור שינויים',
                      icon: _isLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.check_rounded,
                      onTap: _isLoading ? null : () => _save(profile),
                    ),
                    const SizedBox(height: 10),

                    // ── Cancel Button ──
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.pop(),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: const Color(0xFFF1F5F9),
                          border:
                              Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded,
                                color: Color(0xFF64748B), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ביטול',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet option tile
class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color.withOpacity(0.14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section label with icon — used to separate form groups
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF0F766E).withOpacity(0.10),
          ),
          child: Icon(icon, color: const Color(0xFF0F766E), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
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
