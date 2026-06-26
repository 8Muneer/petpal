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

  // When the admin picks a photo for a NEW POI (no existing ID yet), we can't
  // upload it immediately because we don't have a Firestore document ID to use
  // as the Storage path. We store the file here and upload it during _save()
  // after Firestore assigns the real ID.
  XFile? _pendingImageFile;

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
    _latController = TextEditingController(
        text: p?.latitude != null ? p!.latitude.toString() : '');
    _lngController = TextEditingController(
        text: p?.longitude != null ? p!.longitude.toString() : '');
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

    // Guard: block save if any open day has closing time ≤ opening time.
    // The per-row warning already flags this visually; this prevents the bad
    // data from reaching Firestore even if the admin ignores the warning.
    if (!_open24h) {
      for (final (key, label) in _weekDays) {
        if (_isDayRangeInvalid(key)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה בשעות יום $label: שעת הסגירה חייבת להיות אחרי שעת הפתיחה'),
            ),
          );
          return;
        }
      }
    }

    final adminRepo = ref.read(adminRepositoryProvider);
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    // Coordinates are optional — the admin may not know them yet.
    // Rule: both fields must be either both empty or both filled with valid values.
    // A partially filled pair (one empty, one not) is always a mistake.
    final latText = _latController.text.trim();
    final lngText = _lngController.text.trim();
    final latEmpty = latText.isEmpty;
    final lngEmpty = lngText.isEmpty;

    if (latEmpty != lngEmpty) {
      // One field has a value and the other doesn't — show a clear error.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש להזין גם קו רוחב וגם קו אורך, או להשאיר את שניהם ריקים')),
      );
      return;
    }

    // Both filled — parse and validate. Using tryParse guards against locale
    // decimal-separator differences (e.g. "32,08" on some keyboards).
    double? lat, lng;
    if (!latEmpty) {
      lat = double.tryParse(latText);
      lng = double.tryParse(lngText);
      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ערכי קו הרוחב / האורך אינם תקינים')),
        );
        return;
      }
    }
    // If both empty → lat and lng remain null → no map shown on detail screen.

    final newPoi = POI(
      id: widget.poi?.id ?? '',
      name: _nameController.text.trim(),
      type: _selectedType,
      isEmergency: _selectedType == POIType.vet ? _isEmergency : false,
      latitude: lat,
      longitude: lng,
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
      // savePOI now returns the real Firestore document ID (auto-generated for
      // new POIs, or the existing ID for edits).
      final savedId = await adminRepo.savePOI(newPoi);

      // If the admin picked an image for a NEW POI, upload it now under the
      // real document ID and patch the document with the resulting URL.
      // This eliminates the orphaned-upload bug where images were stored under
      // a temporary 'new_<timestamp>' path that never matched the final doc ID.
      if (_pendingImageFile != null) {
        final imageService = ref.read(adminImageServiceProvider);
        final url = await imageService.uploadPOIImage(savedId, _pendingImageFile!);
        await adminRepo.updatePOIImageUrl(savedId, url);
      }

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

    if (widget.poi != null) {
      // Existing POI — we already have the Firestore document ID, so we can
      // upload immediately under the correct Storage path.
      setState(() => _isUploading = true);
      try {
        final url = await imageService.uploadPOIImage(widget.poi!.id, file);
        if (mounted) setState(() => _imageUrlController.text = url);
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    } else {
      // New POI — no document ID exists yet. Store the file locally and defer
      // the upload to _save(), where we can use the real Firestore-assigned ID.
      // This prevents the image from being orphaned under a temporary path that
      // never matches the final document ID.
      setState(() {
        _pendingImageFile = file;
        // Clear any manually entered URL so the pending file takes priority.
        _imageUrlController.text = '';
      });
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
                            // Empty = no location (valid). Filled = must be
                            // a parseable number in the geographic range.
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final d = double.tryParse(v.trim());
                              if (d == null) return 'יש להזין מספר';
                              if (d < -90 || d > 90) return 'חייב להיות בין -90 ל-90';
                              return null;
                            },
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
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final d = double.tryParse(v.trim());
                              if (d == null) return 'יש להזין מספר';
                              if (d < -180 || d > 180) return 'חייב להיות בין -180 ל-180';
                              return null;
                            },
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
                // For new POIs, when a photo is picked it is NOT uploaded yet —
                // it waits until save. Show a "pending" hint so the admin knows
                // the image will be attached on save.
                if (_pendingImageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'תמונה נבחרה — תועלה בעת השמירה',
                          style: TextStyle(
                              fontSize: 12, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrlController,
                        // Disable manual URL entry while a local file is pending
                        // upload to avoid the two sources conflicting.
                        enabled: _pendingImageFile == null,
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

  /// Returns true when a day is marked open but its closing time is not
  /// strictly after its opening time. Overnight spans (e.g. 22:00–02:00) are
  /// not supported — the admin should split those across two calendar days.
  bool _isDayRangeInvalid(String key) {
    if (_dayOpen[key] != true) return false;
    final from = _dayFrom[key];
    final to = _dayTo[key];
    if (from == null || to == null) return false;
    final fromMins = from.hour * 60 + from.minute;
    final toMins = to.hour * 60 + to.minute;
    return toMins <= fromMins;
  }

  Widget _buildDayRow(String key, String label) {
    final open = _dayOpen[key] ?? false;
    final invalid = _isDayRangeInvalid(key);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          // Inline warning — shown immediately when the admin picks invalid hours
          // so they don't have to wait until the save button to discover the error.
          if (invalid)
            Padding(
              padding: const EdgeInsets.only(right: 64, bottom: 4),
              child: Text(
                'שעת הסגירה חייבת להיות אחרי שעת הפתיחה',
                style: TextStyle(fontSize: 11, color: Colors.red[700]),
              ),
            ),
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
