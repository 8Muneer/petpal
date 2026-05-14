import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class CreateSittingServiceScreen extends ConsumerStatefulWidget {
  final SittingService? initialService;

  const CreateSittingServiceScreen({super.key, this.initialService});

  @override
  ConsumerState<CreateSittingServiceScreen> createState() => _CreateSittingServiceScreenState();
}

class _CreateSittingServiceScreenState extends ConsumerState<CreateSittingServiceScreen> {
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  int _experienceYears = 1;
  String _sittingLocation = 'בבית השומר';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialService != null) {
      _bioController.text = widget.initialService!.bio ?? '';
      // Remove currency symbol for editing
      _priceController.text = widget.initialService!.priceText.replaceAll('₪', '').trim();
      _areaController.text = widget.initialService!.area;
      _experienceYears = widget.initialService!.experienceYears;
      _sittingLocation = widget.initialService!.sittingLocation;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bio = _bioController.text.trim();
    final price = _priceController.text.trim();
    final area = _areaController.text.trim();

    if (area.isEmpty) {
      _showSnack('יש להזין אזור פעילות', isError: true);
      return;
    }
    if (price.isEmpty) {
      _showSnack('יש להזין מחיר', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final repo = ref.read(sittingRepositoryProvider);
      final data = {
        'providerUid': user.uid,
        'providerName': user.displayName ?? 'שומר',
        'providerPhotoUrl': user.photoURL,
        'bio': bio,
        'priceText': '₪$price',
        'area': area,
        'experienceYears': _experienceYears,
        'sittingLocation': _sittingLocation,
        'isVerified': false,
        'isActive': true,
      };

      if (widget.initialService != null) {
        await repo.updateService(widget.initialService!.id, data);
      } else {
        await repo.createService(data);
      }

      if (mounted) {
        context.pop();
        _showSnack('הפרופיל עודכן בהצלחה!');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('שגיאה בשמירת הנתונים', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward_rounded)),
                    Text('פרופיל שומר', style: AppTextStyles.h2),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Text('ספר לנו על עצמך', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'ניסיון, אהבה לחיות, מה אתה מציע...',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('מחיר (₪)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'לדוגמה: 50',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('אזור פעילות', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _areaController,
                      decoration: InputDecoration(
                        hintText: 'לדוגמה: תל אביב, לב העיר',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('שנות ניסיון', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _experienceYears.toDouble(),
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: _experienceYears.toString(),
                      onChanged: (val) => setState(() => _experienceYears = val.toInt()),
                    ),
                    const SizedBox(height: 20),
                    const Text('מיקום השמירה המועדף', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      initialValue: _sittingLocation,
                      items: ['בבית השומר', 'בבית הבעלים', 'שניהם'].map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                      onChanged: (val) => setState(() => _sittingLocation = val!),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 40),
                    AppButton(
                      label: _isSaving ? 'שומר...' : 'שמור ופרסם',
                      onTap: _isSaving ? null : _save,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
