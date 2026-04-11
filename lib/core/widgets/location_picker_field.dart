import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:petpal/core/theme/app_theme.dart';

/// A tappable field that requests the device GPS, reverse-geocodes the
/// coordinates to a neighbourhood/city string, and calls [onChanged] with
/// the result. The resolved address is also stored in the widget's own state
/// so the parent only needs to listen via the callback.
class LocationPickerField extends StatefulWidget {
  /// Pre-filled value (edit mode).
  final String initialValue;

  /// Called whenever the resolved address changes.
  final ValueChanged<String> onChanged;

  const LocationPickerField({
    super.key,
    this.initialValue = '',
    required this.onChanged,
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  String _address = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _address = widget.initialValue;
  }

  void _snack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor:
            error ? const Color(0xFFFB7185) : AppColors.primary,
      ),
    );
  }

  Future<void> _pick() async {
    setState(() => _loading = true);
    try {
      // 1. Check location services enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('שירותי המיקום כבויים. יש להפעיל GPS');
        await Geolocator.openLocationSettings();
        return;
      }

      // 2. Check / request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _snack('הרשאת מיקום נדחתה לצמיתות — יש לאפשר בהגדרות');
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        _snack('נדרשת הרשאת מיקום');
        return;
      }

      // 3. Get coordinates
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // 3. Reverse geocode via Nominatim with Hebrew locale
      String resolved =
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      try {
        final client = HttpClient();
        client.userAgent = 'PetPal/1.0';
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?format=json'
          '&lat=${pos.latitude}'
          '&lon=${pos.longitude}'
          '&accept-language=he'
          '&zoom=14',
        );
        final request = await client.getUrl(uri);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        client.close();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final addr = json['address'] as Map<String, dynamic>? ?? {};
        final suburb = (addr['suburb'] ?? addr['neighbourhood'] ??
            addr['quarter'] ?? '') as String;
        final city = (addr['city'] ?? addr['town'] ??
            addr['village'] ?? addr['county'] ?? '') as String;
        final parts = [suburb, city].where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) resolved = parts.join(', ');
      } catch (_) {
        // network unavailable — keep raw coordinates as fallback
      }

      if (mounted) {
        setState(() => _address = resolved);
        widget.onChanged(resolved);
      }
    } catch (e) {
      _snack('לא ניתן לקבל מיקום. יש לוודא שה-GPS מופעל');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.primary),
          ),
        ),
      );
    }

    if (_address.isEmpty) {
      // Prompt button
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _pick,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), AppColors.primary],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'שתף מיקום נוכחי',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Address resolved — show card with change option
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _address,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'שנה',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
