import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/data/repositories/admin_repository.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/features/admin/presentation/services/admin_image_service.dart';

class POIEditorForm extends ConsumerStatefulWidget {
  final POI? poi;

  const POIEditorForm({super.key, this.poi});

  @override
  ConsumerState<POIEditorForm> createState() => _POIEditorFormState();
}

class _POIEditorFormState extends ConsumerState<POIEditorForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _imageUrlController;
  late POIType _selectedType;
  late bool _isEmergency;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.poi?.name ?? '');
    _addressController = TextEditingController(text: widget.poi?.address ?? '');
    _phoneController = TextEditingController(text: widget.poi?.phoneNumber ?? '');
    _latController = TextEditingController(text: widget.poi?.latitude.toString() ?? '');
    _lngController = TextEditingController(text: widget.poi?.longitude.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.poi?.imageUrl ?? '');
    _selectedType = widget.poi?.type ?? POIType.park;
    _isEmergency = widget.poi?.isEmergency ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final adminRepo = ref.read(adminRepositoryProvider);
    
    final newPoi = POI(
      id: widget.poi?.id ?? '',
      name: _nameController.text.trim(),
      type: _selectedType,
      isEmergency: _isEmergency,
      latitude: double.parse(_latController.text),
      longitude: double.parse(_lngController.text),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      rating: widget.poi?.rating ?? 0.0,
      reviewCount: widget.poi?.reviewCount ?? 0,
      tags: widget.poi?.tags ?? [],
    );

    try {
      await adminRepo.savePOI(newPoi);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving place: $e')),
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
      final poiId = widget.poi?.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}';
      final url = await imageService.uploadPOIImage(poiId, file);
      setState(() => _imageUrlController.text = url);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.poi == null ? 'Add New Place' : 'Edit Place',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Name
              _buildLabel('Place Name'),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('e.g., Central Bark Park'),
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Type & Emergency
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Type'),
                        DropdownButtonFormField<POIType>(
                          initialValue: _selectedType,
                          items: POIType.values.map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name.toUpperCase()),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedType = val!),
                          decoration: _buildInputDecoration(''),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedType == POIType.vet) ...[
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Emergency?'),
                        Switch(
                          value: _isEmergency,
                          onChanged: (val) => setState(() => _isEmergency = val),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Coordinates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Latitude'),
                        TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _buildInputDecoration('0.0000'),
                          validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Longitude'),
                        TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _buildInputDecoration('0.0000'),
                          validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address
              _buildLabel('Address'),
              TextFormField(
                controller: _addressController,
                decoration: _buildInputDecoration('Full physical address'),
              ),
              const SizedBox(height: 16),

              // Phone
              _buildLabel('Phone Number'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration('Contact number'),
              ),
              const SizedBox(height: 16),

              // Image URL
              _buildLabel('Image URL'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: _buildInputDecoration('https://...'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: _isUploading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_a_photo_rounded),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              AppButton(
                label: widget.poi == null ? 'Create Place' : 'Save Changes',
                expand: true,
                onTap: _save,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
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
    );
  }
}
