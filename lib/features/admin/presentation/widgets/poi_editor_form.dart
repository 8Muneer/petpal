import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/data/repositories/admin_repository.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/features/admin/presentation/services/admin_image_service.dart';

/// Days of the week, Israeli order (Sunday first), with their storage keys.
const List<(String, String)> _weekDays = [
  ('sun', 'ראשון'),
  ('mon', 'שני'),
  ('tue', 'שלישי'),
  ('wed', 'רביעי'),
  ('thu', 'חמישי'),
  ('fri', 'שישי'),
  ('sat', 'שבת'),
];

const _vetServices = ['חיסונים', 'ניתוחים', 'אשפוז', 'חירום', 'מעבדה', 'צילום'];
const _storeServices = ['מזון', 'אביזרים', 'צעצועים', 'טיפוח', 'משלוחים'];
const _parkAmenities = [
  'מגודר',
  'ברזיית מים',
  'ספסלים',
  'צל',
  'הפרדת גדלים',
  'תאורה',
];

List<String> _serviceOptions(POIType t) => switch (t) {
      POIType.vet => _vetServices,
      POIType.store => _storeServices,
      POIType.park => _parkAmenities,
    };

String _serviceLabel(POIType t) => switch (t) {
      POIType.vet => 'שירותים',
      POIType.store => 'קטגוריות מוצרים',
      POIType.park => 'מתקנים',
    };

String _typeLabel(POIType t) => switch (t) {
      POIType.park => 'גינת כלבים',
      POIType.vet => 'וטרינר',
      POIType.store => 'חנות',
    };

class POIEditorForm extends ConsumerStatefulWidget {
  final POI? poi;

  const POIEditorForm({super.key, this.poi});

  @override
  ConsumerState<POIEditorForm> createState() => _POIEditorFormState();
}

class _POIEditorFormState extends ConsumerState<POIEditorForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _emailController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _imageUrlController;
  late TextEditingController _tagController;

  late POIType _selectedType;
  late bool _isEmergency;
  late bool _open24h;
  bool _isUploading = false;

  final List<String> _tags = [];
  final Set<String> _services = {};

  /// Per-day open flag + open/close times.
  final Map<String, bool> _dayOpen = {};
  final Map<String, TimeOfDay?> _dayFrom = {};
  final Map<String, TimeOfDay?> _dayTo = {};

  @override
  void initState() {
    super.initState();
    final p = widget.poi;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _websiteController = TextEditingController(text: p?.website ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _latController = TextEditingController(text: p?.latitude.toString() ?? '');
    _lngController = TextEditingController(text: p?.longitude.toString() ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _tagController = TextEditingController();
    _selectedType = p?.type ?? POIType.park;
    _isEmergency = p?.isEmergency ?? false;
    _open24h = p?.open24h ?? false;
    _tags.addAll(p?.tags ?? const []);
    _services.addAll(p?.services ?? const []);

    // Hydrate the weekly hours editor.
    for (final (key, _) in _weekDays) {
      final raw = p?.openingHours[key];
      if (raw != null && raw.contains('-')) {
        final parts = raw.split('-');
        _dayOpen[key] = true;
        _dayFrom[key] = _parseTime(parts[0]);
        _dayTo[key] = _parseTime(parts[1]);
      } else {
        _dayOpen[key] = false;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _imageUrlController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Map<String, String> _buildOpeningHours() {
    if (_open24h) return {};
    final result = <String, String>{};
    for (final (key, _) in _weekDays) {
      if (_dayOpen[key] == true &&
          _dayFrom[key] != null &&
          _dayTo[key] != null) {
        result[key] = '${_fmt(_dayFrom[key]!)}-${_fmt(_dayTo[key]!)}';
      }
    }
    return result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final adminRepo = ref.read(adminRepositoryProvider);
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final newPoi = POI(
      id: widget.poi?.id ?? '',
      name: _nameController.text.trim(),
      type: _selectedType,
      isEmergency: _selectedType == POIType.vet ? _isEmergency : false,
      latitude: double.parse(_latController.text),
      longitude: double.parse(_lngController.text),
      address: clean(_addressController),
      phoneNumber: clean(_phoneController),
      website: clean(_websiteController),
      email: clean(_emailController),
      description: clean(_descController),
      imageUrl: clean(_imageUrlController),
      open24h: _open24h,
      openingHours: _buildOpeningHours(),
      services: _services.toList(),
      tags: _tags,
      rating: widget.poi?.rating ?? 0.0,
      reviewCount: widget.poi?.reviewCount ?? 0,
    );

    try {
      await adminRepo.savePOI(newPoi);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירת המקום: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final imageService = ref.read(adminImageServiceProvider);
    final file = await imageService.pickImage(ImageSource.gallery);
    if (file == null) return;
    setState(() => _isUploading = true);
    try {
      final poiId =
          widget.poi?.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}';
      final url = await imageService.uploadPOIImage(poiId, file);
      setState(() => _imageUrlController.text = url);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _addTag() {
    final v = _tagController.text.trim();
    if (v.isEmpty || _tags.contains(v)) return;
    setState(() {
      _tags.add(v);
      _tagController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceOptions = _serviceOptions(_selectedType);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.poi == null ? 'הוספת מקום' : 'עריכת מקום',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _label('שם המקום'),
                TextFormField(
                  controller: _nameController,
                  decoration: _dec('לדוגמה: גן הכלבים המרכזי'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'שדה חובה' : null,
                ),
                const SizedBox(height: 16),

                _label('סוג'),
                DropdownButtonFormField<POIType>(
                  initialValue: _selectedType,
                  items: POIType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(_typeLabel(t))))
                      .toList(),
                  onChanged: (val) => setState(() {
                    _selectedType = val!;
                    _services.clear(); // options differ per type
                  }),
                  decoration: _dec(''),
                ),
                const SizedBox(height: 12),

                // 24/7 + emergency toggles
                _switchTile(
                  'פתוח 24 שעות',
                  _open24h,
                  (v) => setState(() => _open24h = v),
                ),
                if (_selectedType == POIType.vet)
                  _switchTile(
                    'מרפאת חירום',
                    _isEmergency,
                    (v) => setState(() => _isEmergency = v),
                  ),
                const SizedBox(height: 16),

                _label('תיאור'),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: _dec('תיאור קצר של המקום, שירותים מיוחדים וכו׳'),
                ),
                const SizedBox(height: 16),

                // Opening hours
                if (!_open24h) ...[
                  _label('שעות פעילות'),
                  _buildHoursEditor(),
                  const SizedBox(height: 16),
                ],

                // Type-specific services / amenities
                _label(_serviceLabel(_selectedType)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: serviceOptions.map((s) {
                    final selected = _services.contains(s);
                    return _selectChip(
                      label: s,
                      selected: selected,
                      onTap: () => setState(() {
                        selected ? _services.remove(s) : _services.add(s);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                _label('כתובת'),
                TextFormField(
                  controller: _addressController,
                  decoration: _dec('כתובת מלאה'),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('טלפון'),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _dec('מספר ליצירת קשר'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('אימייל'),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec('name@example.com'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _label('אתר אינטרנט'),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: _dec('https://...'),
                ),
                const SizedBox(height: 16),

                // Coordinates
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('קו רוחב'),
                          TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _dec('0.0000'),
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? 'לא תקין'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('קו אורך'),
                          TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _dec('0.0000'),
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? 'לא תקין'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tags
                _label('תגיות'),
                _buildTagEditor(),
                const SizedBox(height: 16),

                // Image
                _label('תמונה'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrlController,
                        decoration: _dec('https://...'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: _isUploading ? null : _pickImage,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_a_photo_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                AppButton(
                  label: widget.poi == null ? 'הוספת מקום' : 'שמירת שינויים',
                  expand: true,
                  onTap: _save,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Opening hours editor ───────────────────────────────────────────────────

  Widget _buildHoursEditor() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          for (final (key, label) in _weekDays) _buildDayRow(key, label),
        ],
      ),
    );
  }

  Widget _buildDayRow(String key, String label) {
    final open = _dayOpen[key] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Switch(
            value: open,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _dayOpen[key] = v),
          ),
          const SizedBox(width: 4),
          if (open) ...[
            _timeChip(
              _dayFrom[key],
              'פתיחה',
              (t) => setState(() => _dayFrom[key] = t),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('—'),
            ),
            _timeChip(
              _dayTo[key],
              'סגירה',
              (t) => setState(() => _dayTo[key] = t),
            ),
          ] else
            const Text('סגור',
                style: TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _timeChip(
      TimeOfDay? value, String hint, ValueChanged<TimeOfDay> onPicked) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          value == null ? hint : _fmt(value),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: value == null ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ── Tag editor ─────────────────────────────────────────────────────────────

  Widget _buildTagEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: _dec('הוסף תגית ולחץ +'),
                onFieldSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: _addTag,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map((t) => Chip(
                      label: Text(t),
                      onDeleted: () => setState(() => _tags.remove(t)),
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.08),
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  // ── Small shared pieces ──────────────────────────────────────────────────

  Widget _selectChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14))),
        Switch(
          value: value,
          activeThumbColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
