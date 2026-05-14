import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieAnimationOverlay extends StatefulWidget {
  final bool isVisible;
  final String lottieAsset;
  final VoidCallback onComplete;

  const LottieAnimationOverlay({
    super.key,
    required this.isVisible,
    required this.lottieAsset,
    required this.onComplete,
  });

  @override
  State<LottieAnimationOverlay> createState() => _LottieAnimationOverlayState();
}

class _LottieAnimationOverlayState extends State<LottieAnimationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Default duration to prevent crash
    );
  }

  @override
  void didUpdateWidget(LottieAnimationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward(from: 0).then((_) => widget.onComplete());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: Lottie.network(
          widget.lottieAsset,
          controller: _controller,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
            if (widget.isVisible) {
              _controller.forward(from: 0).then((_) => widget.onComplete());
            }
          },
          width: 300,
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
