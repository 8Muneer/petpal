import 'package:flutter/material.dart';

class PetPalScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;

  const PetPalScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    const Color(0xFFECFDF5),
                    const Color(0xFFF6F7FB),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // Top-left blob
          Positioned(
            top: -120,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF34D399).withOpacity(0.22),
                    const Color(0xFF0EA5E9).withOpacity(0.14),
                  ],
                ),
              ),
            ),
          ),

          // Bottom-right blob
          Positioned(
            bottom: 120,
            right: -110,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF22C55E).withOpacity(0.12),
                    const Color(0xFF0F766E).withOpacity(0.14),
                  ],
                ),
              ),
            ),
          ),

          // Content
          body,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
