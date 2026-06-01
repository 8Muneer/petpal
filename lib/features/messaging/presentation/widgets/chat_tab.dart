import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/messaging/presentation/providers/messaging_provider.dart';

class ChatTab extends ConsumerWidget {
  final bool isProvider;
  const ChatTab({super.key, this.isProvider = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
    final async = ref.watch(conversationsProvider);

    return SafeArea(
      bottom: false,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (convos) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
          children: [
            SectionHeader(
              title: 'צ׳אט',
              subtitle: isProvider ? 'שיחות עם בעלי חיות המחמד' : 'שיחות עם נותני שירות',
            ),
            const SizedBox(height: 10),
            if (convos.isEmpty)
              EmptyStateCard(
                title: 'אין שיחות עדיין',
                subtitle: isProvider
                    ? 'שיחות יופיעו כאן לאחר פנייה מבעלי חיות מחמד.'
                    : 'שיחות יופיעו כאן לאחר פנייה לנותן שירות.',
                icon: Icons.chat_bubble_outline_rounded,
              )
            else
              ...convos.map((c) {
                final names =
                    Map<String, String>.from(c['participantNames'] ?? {});
                final photoUrls =
                    Map<String, String>.from(c['participantPhotoUrls'] ?? {});
                final otherEntry = names.entries.firstWhere(
                  (e) => e.key != myUid,
                  orElse: () => const MapEntry('', 'לא ידוע'),
                );
                final otherName = otherEntry.value;
                final otherPhotoUrl = photoUrls[otherEntry.key] ?? '';
                final lastMsg = c['lastMessage'] as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => context.push(
                      '/chat/${c['id']}',
                      extra: {
                        'otherName': otherName,
                        'otherPhotoUrl': otherPhotoUrl,
                        'otherUid': otherEntry.key
                      },
                    ),
                    child: Row(
                      children: [
                        LiveUserAvatar(
                          uid: otherEntry.key,
                          fallbackName: otherName,
                          fallbackPhotoUrl:
                              otherPhotoUrl.isNotEmpty ? otherPhotoUrl : null,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(otherName, style: AppTextStyles.bodyBold),
                              const SizedBox(height: 2),
                              Text(
                                lastMsg.isEmpty ? 'התחל שיחה...' : lastMsg,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
