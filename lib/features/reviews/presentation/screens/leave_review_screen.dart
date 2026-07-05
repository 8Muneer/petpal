import 'dart:async';
import 'dart:math' show max;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/hero_decorations.dart';
import 'package:petpal/features/reviews/domain/entities/review.dart';
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart';

class LeaveReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String providerUid;
  final String providerName;
  final String? providerPhotoUrl;

  const LeaveReviewScreen({
    super.key,
    required this.bookingId,
    required this.providerUid,
    required this.providerName,
    this.providerPhotoUrl,
  });

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen>
    with TickerProviderStateMixin {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  // Success state
  bool _submitted = false;
  int _submittedRating = 0;
  bool _popped = false;
  Timer? _autoPopTimer;

  late final List<AnimationController> _starControllers;
  late final List<Animation<double>> _starAnims;

  // Speech-to-text (on-device, free)
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _baseComment = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _starControllers = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
      ),
    );
    _starAnims = _starControllers
        .map((c) => Tween<double>(begin: 1.0, end: 1.2).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOutBack),
            ))
        .toList();
  }

  @override
  void dispose() {
    _autoPopTimer?.cancel();
    _speech.stop();
    for (final c in _starControllers) {
      c.dispose();
    }
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          // Recognizer can stop on its own (silence / timeout) — reflect that.
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('זיהוי דיבור אינו זמין במכשיר זה')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    HapticFeedback.lightImpact();
    _baseComment = _commentController.text;
    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: 'he_IL',
      ),
      onResult: (result) {
        final words = result.recognizedWords;
        if (words.isEmpty) return;
        final merged = _baseComment.isEmpty ? words : '$_baseComment $words';
        // Cap at the field's 500-char limit.
        final text = merged.length > 500 ? merged.substring(0, 500) : merged;
        _commentController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
    );
  }

  void _onStarTap(int star) {
    HapticFeedback.lightImpact();
    setState(() => _rating = star);
    _starControllers[star - 1]
      ..reset()
      ..forward().then((_) {
        if (mounted) _starControllers[star - 1].reverse();
      });
  }

  Future<void> _submit() async {
    if (_rating == 0) return;

    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final review = Review(
        id: '',
        bookingId: widget.bookingId,
        reviewerUid: user.uid,
        reviewerName: user.displayName ?? user.email ?? '',
        reviewerPhotoUrl: user.photoURL,
        providerId: widget.providerUid,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(reviewNotifierProvider.notifier).submitReview(review);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submittedRating = _rating;
        _submitted = true;
      });
      _autoPopTimer = Timer(
        const Duration(seconds: 2, milliseconds: 500),
        _closeSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה בשליחת הביקורת')),
      );
    }
  }

  /// Pops the screen exactly once — guards against the auto-pop timer and
  /// the manual close button both firing.
  void _closeSuccess() {
    if (_popped || !mounted) return;
    _popped = true;
    _autoPopTimer?.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: const BackButton(color: Colors.white),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ReviewHeroSection(
                    topPadding: topPadding,
                    providerName: widget.providerName,
                    providerPhotoUrl: widget.providerPhotoUrl,
                  ),
                  const SizedBox(height: 28),

                  // ── Star picker ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return Semantics(
                        button: true,
                        selected: star <= _rating,
                        label: 'דרג $star מתוך 5 כוכבים',
                        child: GestureDetector(
                          onTap: () => _onStarTap(star),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedBuilder(
                            animation: _starAnims[i],
                            builder: (_, child) => Transform.scale(
                              scale: _starAnims[i].value,
                              child: child,
                            ),
                            child: _StarItem(filled: star <= _rating),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _ratingLabel(_rating),
                      key: ValueKey(_rating),
                      style: GoogleFonts.frankRuhlLibre(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _rating > 0
                            ? AppColors.warning
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Comment ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionTitle(
                          title: 'הוסף הערה',
                          subtitle: 'אופציונלי',
                          trailing: _MicButton(
                            isListening: _isListening,
                            onTap: _toggleListening,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: AppRadius.lgRadius,
                            border: Border.all(
                              color: _isListening
                                  ? AppColors.warning
                                  : AppColors.border,
                              width: _isListening ? 1.5 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _commentController,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? 'מקשיב...'
                                  : 'ספר על החוויה שלך...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              counterStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Submit ────────────────────────────────────────────
                        AppButton(
                          label: 'שלח ביקורת',
                          isLoading: _isSubmitting,
                          onTap: _rating == 0 ? null : _submit,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Success overlay ─────────────────────────────────────────────
            if (_submitted)
              _SubmitSuccessOverlay(
                rating: _submittedRating,
                onClose: _closeSuccess,
              ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'גרוע',
        2 => 'לא טוב',
        3 => 'בסדר',
        4 => 'טוב',
        5 => 'מצוין!',
        _ => 'בחר דירוג',
      };
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _ReviewHeroSection extends StatelessWidget {
  final double topPadding;
  final String providerName;
  final String? providerPhotoUrl;

  const _ReviewHeroSection({
    required this.topPadding,
    required this.providerName,
    this.providerPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final height = max(screenH * 0.33, 260.0);
    final hasPhoto = providerPhotoUrl?.isNotEmpty == true;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Layer 1 — dark gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.deepGradient),
            ),
          ),

          // Layer 2 — dot grid
          const Positioned.fill(
            child: CustomPaint(painter: DotGridPainter()),
          ),

          // Layer 3 — decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: _decoCircle(180, Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: 10,
            left: -30,
            child:
                _decoCircle(120, AppColors.smartBlue.withValues(alpha: 0.16)),
          ),

          // Layer 4 — content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 10,
                bottom: 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar + white ring
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? CachedNetworkImage(
                              imageUrl: providerPhotoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _AvatarFallback(name: providerName),
                            )
                          : _AvatarFallback(name: providerName),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    providerName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.frankRuhlLibre(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 12,
                          color: Colors.black38,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'כיצד היה השירות?',
                    style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // Layer 5 — wave clip
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: const HeroWaveClipper(),
              child: Container(height: 40, color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decoCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ─── Star item ──────────────────────────────────────────────────────────────

class _StarItem extends StatelessWidget {
  final bool filled;
  const _StarItem({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: filled
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 52,
          color: filled ? AppColors.warning : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.warning,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle!,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ],
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

// ─── Mic button (voice-to-text) ───────────────────────────────────────────────

class _MicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  const _MicButton({required this.isListening, required this.onTap});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isListening) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isListening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isListening ? AppColors.warning : AppColors.primary;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          final glow = widget.isListening ? (0.18 + _pulse.value * 0.22) : 0.0;
          return Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: widget.isListening ? 0.14 : 0.10),
              shape: BoxShape.circle,
              boxShadow: glow > 0
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: glow),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 20,
              color: accent,
            ),
          );
        },
      ),
    );
  }
}

// ─── Success overlay ──────────────────────────────────────────────────────────

class _SubmitSuccessOverlay extends StatefulWidget {
  final int rating;
  final VoidCallback onClose;
  const _SubmitSuccessOverlay({required this.rating, required this.onClose});

  @override
  State<_SubmitSuccessOverlay> createState() => _SubmitSuccessOverlayState();
}

class _SubmitSuccessOverlayState extends State<_SubmitSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            color: AppColors.surface,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withValues(alpha: 0.4),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 80,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'תודה על הביקורת!',
                      style: GoogleFonts.frankRuhlLibre(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'הביקורת שלך עוזרת לשפר את הפלטפורמה',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < widget.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 20,
                          color: i < widget.rating
                              ? AppColors.warning
                              : AppColors.textMuted,
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    AppButton.secondary(
                      label: 'סגור',
                      expand: false,
                      onTap: widget.onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
