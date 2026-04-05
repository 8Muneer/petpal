import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_input.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';

class ServiceSettingsScreen extends StatefulWidget {
  const ServiceSettingsScreen({super.key});

  @override
  State<ServiceSettingsScreen> createState() => _ServiceSettingsScreenState();
}

class _ServiceSettingsScreenState extends State<ServiceSettingsScreen> {
  bool _offersWalks = false;
  bool _offersSitting = false;
  final _walkPriceCtrl = TextEditingController();
  final _sittingPriceCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _walkPriceCtrl.dispose();
    _sittingPriceCtrl.dispose();
    super.dispose();
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
      setState(() {
        _offersWalks = data['offersWalks'] as bool? ?? false;
        _offersSitting = data['offersSitting'] as bool? ?? false;
        _walkPriceCtrl.text = (data['walkPrice'] ?? '').toString();
        _sittingPriceCtrl.text = (data['sittingPrice'] ?? '').toString();
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
      'offersWalks': _offersWalks,
      'offersSitting': _offersSitting,
      'walkPrice': _walkPriceCtrl.text.trim(),
      'sittingPrice': _sittingPriceCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('השירותים עודכנו בהצלחה'),
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
                        Text('נהל שירותים', style: AppTextStyles.h2),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text('השירותים שלי', style: AppTextStyles.h3),
                    const SizedBox(height: 12),

                    // Walks toggle
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _offersWalks
                                      ? AppColors.walksLight
                                      : AppColors.borderFaint,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(
                                  Icons.directions_walk_rounded,
                                  color: _offersWalks
                                      ? AppColors.walks
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('טיולים',
                                        style: AppTextStyles.bodyBold),
                                    Text('ליווי ועריסה לכלבים',
                                        style: AppTextStyles.caption
                                            .copyWith(
                                                color: AppColors
                                                    .textSecondary)),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _offersWalks,
                                onChanged: (v) =>
                                    setState(() => _offersWalks = v),
                                activeColor: AppColors.walks,
                              ),
                            ],
                          ),
                          if (_offersWalks) ...[
                            const SizedBox(height: 14),
                            AppInput(
                              controller: _walkPriceCtrl,
                              label: 'מחיר לטיול (₪)',
                              icon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Sitting toggle
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _offersSitting
                                      ? AppColors.sittingLight
                                      : AppColors.borderFaint,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(
                                  Icons.house_rounded,
                                  color: _offersSitting
                                      ? AppColors.sitting
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('שמירה',
                                        style: AppTextStyles.bodyBold),
                                    Text('אירוח חיות בית',
                                        style: AppTextStyles.caption
                                            .copyWith(
                                                color: AppColors
                                                    .textSecondary)),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _offersSitting,
                                onChanged: (v) =>
                                    setState(() => _offersSitting = v),
                                activeColor: AppColors.sitting,
                              ),
                            ],
                          ),
                          if (_offersSitting) ...[
                            const SizedBox(height: 14),
                            AppInput(
                              controller: _sittingPriceCtrl,
                              label: 'מחיר ללילה (₪)',
                              icon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ],
                      ),
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
