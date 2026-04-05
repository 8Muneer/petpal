import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/features/messaging/presentation/providers/messaging_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final async = ref.watch(conversationsProvider);

    return AppScaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('הודעות', style: AppTextStyles.h2),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('שגיאה: $e')),
                  data: (convos) {
                    if (convos.isEmpty) {
                      return const EmptyStateWidget(
                        title: 'אין שיחות עדיין',
                        subtitle:
                            'שיחות יופיעו כאן לאחר בקשה או הזמנה.',
                        icon: Icons.chat_bubble_outline_rounded,
                      );
                    }
                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: convos.length,
                      itemBuilder: (ctx, i) {
                        final c = convos[i];
                        final names = Map<String, String>.from(
                            c['participantNames'] ?? {});
                        final photoUrls = Map<String, String>.from(
                            c['participantPhotoUrls'] ?? {});
                        final otherEntry = names.entries.firstWhere(
                          (e) => e.key != myUid,
                          orElse: () => const MapEntry('', 'לא ידוע'),
                        );
                        final otherName = otherEntry.value;
                        final otherPhotoUrl =
                            photoUrls[otherEntry.key] ?? '';
                        final lastMsg =
                            c['lastMessage'] as String? ?? '';
                        final ts =
                            c['lastMessageAt'] as Timestamp?;
                        final timeStr = ts != null
                            ? _formatTime(ts.toDate())
                            : '';

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            onTap: () => ctx.push(
                              '/chat/${c['id']}',
                              extra: {
                                'otherName': otherName,
                                'otherPhotoUrl': otherPhotoUrl,
                                'otherUid': otherEntry.key,
                              },
                            ),
                            child: Row(
                              children: [
                                LiveUserAvatar(
                                  uid: otherEntry.key,
                                  fallbackName: otherName,
                                  fallbackPhotoUrl: otherPhotoUrl.isNotEmpty ? otherPhotoUrl : null,
                                  size: 48,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(otherName,
                                          style:
                                              AppTextStyles.bodyBold),
                                      const SizedBox(height: 2),
                                      Text(
                                        lastMsg.isEmpty
                                            ? 'התחל שיחה...'
                                            : lastMsg,
                                        style: AppTextStyles.caption
                                            .copyWith(
                                                color: AppColors
                                                    .textSecondary),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (timeStr.isNotEmpty)
                                  Text(timeStr,
                                      style: AppTextStyles.caption
                                          .copyWith(
                                              color: AppColors
                                                  .textMuted)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שע׳';
    if (diff.inDays == 1) return 'אתמול';
    return '${dt.day}/${dt.month}';
  }
}
