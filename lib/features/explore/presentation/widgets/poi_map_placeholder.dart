import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class POIMapPlaceholder extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;

  const POIMapPlaceholder({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Future<void> _launchMaps() async {
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    final appleMapsUrl =
        Uri.parse('https://maps.apple.com/?q=$latitude,$longitude');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      // Throw a typed Exception (not a bare String) so callers can catch it
      // via `on Exception` and handle it gracefully.
      throw Exception('No maps application is available on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppRadius.organicRadius,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 12),
                if (address != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      address!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          
          // Action Button Overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              // Wrap _launchMaps so the Exception it throws is caught here,
              // where we have a BuildContext to show a SnackBar. Without this
              // wrapper, an unhandled async exception would silently crash the
              // Future and produce a red error in the console with no user feedback.
              onPressed: () async {
                try {
                  await _launchMaps();
                } on Exception {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('לא ניתן לפתוח אפליקציית מפות'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('קבל הוראות הגעה'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
