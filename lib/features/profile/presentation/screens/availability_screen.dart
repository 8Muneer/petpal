import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  bool _isAvailable = true;
  final List<bool> _days = [true, true, true, false, false, false, false];
  bool _loading = true;
  bool _saving = false;

  static const _dayLabels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    final data = doc.data();
    if (data != null && mounted) {
      final savedDays = List<bool>.from(
        (data['availableDays'] as List<dynamic>? ?? _days)
            .map((v) => v == true),
      );
      setState(() {
        _isAvailable = data['isAvailable'] as bool? ?? true;
        if (savedDays.length == 7) {
          for (int i = 0; i < 7; i++) _days[i] = savedDays[i];
        }
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'isAvailable': _isAvailable,
      'availableDays': _days,
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('הזמינות עודכנה בהצלחה'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('עדכן זמינות', style: AppTextStyles.h2),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Availability toggle
                    AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isAvailable
                                  ? AppColors.successLight
                                  : AppColors.borderFaint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: _isAvailable
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('פתוח לקבלת בקשות',
                                    style: AppTextStyles.bodyBold),
                                const SizedBox(height: 2),
                                Text(
                                  _isAvailable
                                      ? 'מופיע/ת בחיפוש ומקבל/ת בקשות'
                                      : 'לא מופיע/ת בחיפוש כרגע',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isAvailable,
                            onChanged: (v) =>
                                setState(() => _isAvailable = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text('ימים זמינים', style: AppTextStyles.h3),
                    const SizedBox(height: 12),

                    // Days selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final selected = _days[i];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _days[i] = !_days[i]),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.7),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _dayLabels[i],
                                style: AppTextStyles.label.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    AppButton(
                      label: 'שמור שינויים',
                      leadingIcon: Icons.check_rounded,
                      isLoading: _saving,
                      onTap: _saving ? null : _save,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
