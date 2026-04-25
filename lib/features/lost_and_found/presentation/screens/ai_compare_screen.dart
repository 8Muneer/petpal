import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/lost_and_found/data/datasources/gemini_matching_service.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/providers/lost_found_provider.dart';

class AiCompareScreen extends ConsumerStatefulWidget {
  final LostFoundPost post1;
  final LostFoundPost post2;

  const AiCompareScreen({
    super.key,
    required this.post1,
    required this.post2,
  });

  @override
  ConsumerState<AiCompareScreen> createState() => _AiCompareScreenState();
}

enum _CompareState { idle, loading, result }

class _AiCompareScreenState extends ConsumerState<AiCompareScreen>
    with TickerProviderStateMixin {
  _CompareState _state = _CompareState.idle;
  GeminiMatchResult? _result;
  late AnimationController _pulseController;
  late AnimationController _resultController;
  late Animation<double> _confidenceAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _confidenceAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOutCubic),
    );

    _fadeAnim = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _runCompare() async {
    setState(() {
      _state = _CompareState.loading;
      _result = null;
    });

    final gemini = ref.read(geminiServiceProvider);
    final result = await gemini.compareImages(
      widget.post1.imageUrl,
      widget.post2.imageUrl,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _state = _CompareState.result;
    });
    _resultController.forward(from: 0);
  }

  Color get _confidenceColor {
    final c = _result?.confidence ?? 0;
    if (c >= 80) return const Color(0xFF10B981);
    if (c >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFFB7185);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            'השוואת AI',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildImagePair(),
              const SizedBox(height: 24),
              if (_state == _CompareState.idle) _buildIdleState(),
              if (_state == _CompareState.loading) _buildLoadingState(),
              if (_state == _CompareState.result) _buildResultState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePair() {
    return Row(
      children: [
        Expanded(child: _PetImageCard(post: widget.post1, label: 'דיווח ראשון')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.compare_arrows_rounded,
                color: Color(0xFF8B5CF6), size: 20),
          ),
        ),
        Expanded(child: _PetImageCard(post: widget.post2, label: 'דיווח שני')),
      ],
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'השוואה חכמה עם Gemini AI',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              const Text(
                'ה-AI יבדוק גזע, צבע, סימנים מיוחדים וכל מאפיין ייחודי של שתי החיות',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _runCompare,
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: const Text(
              'הפעל השוואת AI',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 0.9 + _pulseController.value * 0.15,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6)
                          .withValues(alpha: 0.7 + _pulseController.value * 0.3),
                      const Color(0xFF6366F1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(
                          alpha: 0.3 + _pulseController.value * 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Gemini מנתח את התמונות...',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'בודק גזע, צבע, סימנים מיוחדים ומאפיינים ייחודיים',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          _AnimatedDots(),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    if (_result == null) {
      return _buildErrorState();
    }

    final isMatch = _result!.isMatch && _result!.confidence >= 60;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          // Main result card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                // Match/No-match icon
                AnimatedBuilder(
                  animation: _confidenceAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _confidenceAnim.value,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isMatch
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFFFB7185).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isMatch
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isMatch
                            ? const Color(0xFF10B981)
                            : const Color(0xFFFB7185),
                        size: 42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isMatch ? 'נמצאה התאמה!' : 'לא נמצאה התאמה',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: isMatch
                          ? const Color(0xFF10B981)
                          : const Color(0xFFFB7185)),
                ),
                const SizedBox(height: 20),

                // Confidence / mismatch meter
                _ConfidenceMeter(
                  confidence: _result!.confidence,
                  isMatch: isMatch,
                  animation: _confidenceAnim,
                  color: _confidenceColor,
                ),
                const SizedBox(height: 20),

                // Reason
                if (_result!.reason.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _result!.reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Try again button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _state = _CompareState.idle);
                _result = null;
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('השווה שוב',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
                side: const BorderSide(color: Color(0xFF8B5CF6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFB7185), size: 48),
          const SizedBox(height: 12),
          const Text(
            'שגיאה בהשוואה',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'לא ניתן היה להשוות את התמונות. נסה שוב.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _state = _CompareState.idle),
            child: const Text('נסה שוב'),
          ),
        ],
      ),
    );
  }
}

class _PetImageCard extends StatelessWidget {
  final LostFoundPost post;
  final String label;
  const _PetImageCard({required this.post, required this.label});

  @override
  Widget build(BuildContext context) {
    final isLost = post.type == LostFoundType.lost;
    final accent =
        isLost ? const Color(0xFFFB7185) : const Color(0xFF60A5FA);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: post.imageUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 150,
              color: const Color(0xFFF0F2F5),
              child: const Icon(Icons.pets_rounded,
                  color: Colors.grey, size: 36),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 150,
              color: const Color(0xFFF0F2F5),
              child: const Icon(Icons.pets_rounded,
                  color: Colors.grey, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isLost ? 'אבוד' : 'נמצא',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: accent),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          post.petName.isNotEmpty ? post.petName : post.species,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
      ],
    );
  }
}

class _ConfidenceMeter extends StatelessWidget {
  final int confidence;
  final bool isMatch;
  final Animation<double> animation;
  final Color color;

  const _ConfidenceMeter({
    required this.confidence,
    required this.isMatch,
    required this.animation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = isMatch ? confidence : (100 - confidence);
    final label = isMatch ? 'התאמה' : 'אי-התאמה';
    final icon = isMatch
        ? Icons.check_circle_outline_rounded
        : Icons.highlight_off_rounded;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: animation,
              builder: (_, __) => Text(
                '${(displayValue * animation.value).round()}%',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: color),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => LinearProgressIndicator(
              value: (displayValue / 100) * animation.value,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0F2F5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8 + _controllers[i].value * 6,
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                const Color(0xFF8B5CF6),
                _controllers[i].value,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
