import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// Unified scaffold replacing [PetPalScaffold].
///
/// Improvements over original:
/// - Blob sizes derived from [MediaQuery] — no clipping on small screens
/// - Gradient and blob colors pulled from [AppColors] tokens
/// - Optional [appBar] slot
/// - Optional [floatingActionButton]
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final blobSize = size.width * 0.72; // ~72% of screen width

    return Scaffold(
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: AppColors.surfaceBase,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(
        children: [
          // Background gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
            ),
          ),

          // Top-left decorative blob
          Positioned(
            top: -(blobSize * 0.42),
            left: -(blobSize * 0.30),
            child: _Blob(
              size: blobSize,
              colors: const [
                Color(0x3852B788), // primaryLight 22%
                Color(0x240EA5E9), // blue 14%
              ],
            ),
          ),

          // Bottom-right decorative blob
          Positioned(
            bottom: blobSize * 0.20,
            right: -(blobSize * 0.36),
            child: _Blob(
              size: blobSize * 0.90,
              colors: const [
                Color(0x1F40916C), // walks 12%
                Color(0x242D6A4F), // primary 14%
              ],
            ),
          ),

          // Main content
          body,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _Blob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
    );
  }
}
