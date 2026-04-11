import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';
import 'package:petpal/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/sitting/data/models/sitting_request_model.dart';
import 'package:petpal/features/walks/data/models/walk_request_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherName;
  final String? otherPhotoUrl;
  final String? otherUid;

  const ChatScreen({
    required this.conversationId,
    required this.otherName,
    this.otherPhotoUrl,
    this.otherUid,
    super.key,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  User? get _me => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final me = _me;
    if (me == null) return;

    setState(() => _sending = true);
    _ctrl.clear();

    // Read photoUrl from Firestore (source of truth)
    final profile = ref.read(currentUserProfileProvider).asData?.value;
    final myPhotoUrl = profile?.photoUrl ?? me.photoURL ?? '';

    await ref.read(messagingDatasourceProvider).sendMessage(
          conversationId: widget.conversationId,
          senderId: me.uid,
          senderName: me.displayName ?? me.email ?? 'משתמש',
          senderPhotoUrl: myPhotoUrl,
          text: text,
        );

    setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _deleteMessage(String messageId) async {
    await ref.read(messagingDatasourceProvider).deleteMessage(
          widget.conversationId,
          messageId,
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _sameDay(Map a, Map b) {
    final ta = (a['timestamp'] as Timestamp?)?.toDate();
    final tb = (b['timestamp'] as Timestamp?)?.toDate();
    if (ta == null || tb == null) return true;
    return ta.year == tb.year && ta.month == tb.month && ta.day == tb.day;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'היום';
    if (diff == 1) return 'אתמול';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _showMessageOptions(
      BuildContext ctx, String messageId, String text) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              _OptionTile(
                icon: Icons.copy_rounded,
                label: 'העתק הודעה',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ההודעה הועתקה'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _OptionTile(
                icon: Icons.delete_outline_rounded,
                label: 'מחק הודעה',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(messageId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _me?.uid ?? '';
    final myName = _me?.displayName ?? _me?.email ?? 'אני';
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));

    return AppScaffold(
      resizeToAvoidBottomInset: true,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        // Avatar + info (RTL: rightmost)
                        widget.otherUid != null
                            ? LiveUserAvatar(
                                uid: widget.otherUid!,
                                fallbackName: widget.otherName,
                                fallbackPhotoUrl: widget.otherPhotoUrl,
                                size: 44,
                              )
                            : _ChatAvatar(
                                name: widget.otherName,
                                radius: 22,
                                color: AppColors.primary,
                                photoUrl: widget.otherPhotoUrl,
                              ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.otherName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'שיחה פעילה',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Back button (RTL: leftmost)
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                ],
              ),
            ),

            // ── Messages ────────────────────────────────────────────────────
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF0F2F5),
                child: messagesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Text('שגיאה: $e',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: AppColors.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('התחל/י שיחה!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              )),
                        ],
                      ),
                    );
                  }
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isMe = msg['senderId'] == myUid;
                      final ts = msg['timestamp'] as Timestamp?;
                      final time = ts != null ? _formatTime(ts.toDate()) : '';
                      final msgId = msg['id'] as String? ?? '';
                      final text = msg['text'] as String? ?? '';
                      final senderName = isMe
                          ? myName
                          : (msg['senderName'] as String? ??
                              widget.otherName);
                      final senderPhotoUrl =
                          msg['senderPhotoUrl'] as String? ?? '';

                      // Date separator
                      final showDate = i == 0 ||
                          !_sameDay(messages[i - 1], msg);

                      // Grouping
                      final prevSender = i > 0
                          ? messages[i - 1]['senderId'] as String?
                          : null;
                      final nextSender = i < messages.length - 1
                          ? messages[i + 1]['senderId'] as String?
                          : null;
                      final isFirstInGroup =
                          prevSender != msg['senderId'] || showDate;
                      final isLastInGroup =
                          nextSender != msg['senderId'];

                      // Context card — full width, centered
                      if (msg['type'] == 'context') {
                        return _ContextCard(
                          metadata: Map<String, dynamic>.from(
                              msg['metadata'] as Map? ?? {}),
                        );
                      }

                      return Column(
                        children: [
                          if (showDate)
                            _DateSeparator(
                              label: _formatDateLabel(
                                  ts?.toDate() ?? DateTime.now()),
                            ),
                          _MessageRow(
                            text: text,
                            time: time,
                            isMe: isMe,
                            senderName: senderName,
                            senderPhotoUrl: senderPhotoUrl,
                            senderId: msg['senderId'] as String?,
                            showAvatar: !isMe && isLastInGroup,
                            showName: !isMe && isFirstInGroup,
                            isFirstInGroup: isFirstInGroup,
                            isLastInGroup: isLastInGroup,
                            onLongPress: msgId.isNotEmpty
                                ? () => _showMessageOptions(
                                    ctx, msgId, text)
                                : null,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ),
            ),

            // ── Input bar ───────────────────────────────────────────────────
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(
                          color: AppColors.border, width: 1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Send button (RTL: rightmost)
                    GestureDetector(
                      onTap: _send,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(13),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Text field (RTL: to the left of send button)
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        textDirection: TextDirection.rtl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'כתוב הודעה...',
                          hintStyle: TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppColors.border, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppColors.border, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message row (avatar + bubble)
// ─────────────────────────────────────────────────────────────────────────────

class _MessageRow extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final String senderName;
  final String senderPhotoUrl;
  final String? senderId;
  final bool showAvatar;
  final bool showName;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback? onLongPress;

  const _MessageRow({
    required this.text,
    required this.time,
    required this.isMe,
    required this.senderName,
    required this.senderPhotoUrl,
    this.senderId,
    required this.showAvatar,
    required this.showName,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // RTL: my messages align RIGHT (Alignment.centerRight physical)
    //       their messages align LEFT (Alignment.centerLeft physical)
    final topPad = isFirstInGroup ? 6.0 : 2.0;

    if (isMe) {
      return Padding(
        padding: EdgeInsets.only(top: topPad, bottom: 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: GestureDetector(
              onLongPress: onLongPress,
              child: _Bubble(
                text: text,
                time: time,
                isMe: true,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
              ),
            ),
          ),
        ),
      );
    }

    // Their message — pinned to physical LEFT, avatar left, bubble right
    return Padding(
      padding: EdgeInsets.only(top: topPad, bottom: 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar (physical left)
                SizedBox(
                  width: 32,
                  child: showAvatar
                      ? (senderId != null
                          ? LiveUserAvatar(
                              uid: senderId!,
                              fallbackName: senderName,
                              fallbackPhotoUrl: senderPhotoUrl.isNotEmpty
                                  ? senderPhotoUrl
                                  : null,
                              size: 32,
                            )
                          : _ChatAvatar(
                              name: senderName,
                              radius: 16,
                              color: const Color(0xFF0EA5E9),
                              photoUrl: senderPhotoUrl.isNotEmpty
                                  ? senderPhotoUrl
                                  : null,
                            ))
                      : null,
                ),
                const SizedBox(width: 6),
                // Bubble (physical right of avatar)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showName)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3, left: 4),
                          child: Text(
                            senderName,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onLongPress: onLongPress,
                        child: _Bubble(
                          text: text,
                          time: time,
                          isMe: false,
                          isFirstInGroup: isFirstInGroup,
                          isLastInGroup: isLastInGroup,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _Bubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(18);
    const rSmall = Radius.circular(4);

    // My messages: tail bottom-right (physical)
    // Their messages: tail bottom-left (physical)
    final radius = isMe
        ? BorderRadius.only(
            topRight: r,
            topLeft: r,
            bottomLeft: r,
            bottomRight: isLastInGroup ? rSmall : r,
          )
        : BorderRadius.only(
            topRight: r,
            topLeft: r,
            bottomRight: r,
            bottomLeft: isLastInGroup ? rSmall : r,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        gradient: isMe ? AppColors.primaryGradient : null,
        color: isMe ? null : Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isMe ? Colors.white : const Color(0xFF1E293B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.65)
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date separator
// ─────────────────────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: AppColors.border, thickness: 1)),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.borderFaint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Divider(color: AppColors.border, thickness: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _ChatAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color color;
  final String? photoUrl;

  const _ChatAvatar({
    required this.name,
    required this.radius,
    required this.color,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(url),
        backgroundColor: color.withValues(alpha: 0.15),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet option tile
// ─────────────────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Context card (request preview, tappable)
// ─────────────────────────────────────────────────────────────────────────────

class _ContextCard extends StatefulWidget {
  final Map<String, dynamic> metadata;
  const _ContextCard({required this.metadata});

  @override
  State<_ContextCard> createState() => _ContextCardState();
}

class _ContextCardState extends State<_ContextCard> {
  bool _loading = false;

  Future<void> _navigate() async {
    final requestId = widget.metadata['requestId'] as String? ?? '';
    final requestType = widget.metadata['requestType'] as String? ?? '';
    if (requestId.isEmpty) return;

    setState(() => _loading = true);
    try {
      final collection =
          requestType == 'walk' ? 'walk_requests' : 'sitting_requests';
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(requestId)
          .get();
      if (!doc.exists || !mounted) return;

      if (requestType == 'walk') {
        final request = WalkRequestModel.fromFirestore(doc);
        if (mounted) context.push('/walks/detail', extra: request);
      } else {
        final request = SittingRequestModel.fromFirestore(doc);
        if (mounted) context.push('/sitting/detail', extra: request);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metadata;
    final isWalk = m['requestType'] == 'walk';
    final accent = isWalk ? AppColors.primary : const Color(0xFF7C3AED);
    final bgColor =
        isWalk ? const Color(0xFFECFDF5) : const Color(0xFFF5F3FF);
    final label = isWalk ? 'בקשת טיול' : 'בקשת שמירה';
    final typeIcon =
        isWalk ? Icons.directions_walk_rounded : Icons.home_rounded;

    final petImageUrl = m['petImageUrl'] as String? ?? '';
    final petName = m['petName'] as String? ?? '';
    final ownerName = m['ownerName'] as String? ?? '';

    final chips = <_ChipData>[];
    final date = m['date'] as String? ?? '';
    final startDate = m['startDate'] as String? ?? '';
    final endDate = m['endDate'] as String? ?? '';
    final time = m['time'] as String? ?? '';
    final area = m['area'] as String? ?? '';
    final budget = m['budget'] as String? ?? '';

    if (date.isNotEmpty) {
      chips.add(_ChipData(Icons.calendar_today_rounded,
          time.isNotEmpty ? '$date · $time' : date));
    }
    if (startDate.isNotEmpty) {
      chips.add(_ChipData(
          Icons.date_range_rounded, '$startDate – $endDate'));
    }
    if (area.isNotEmpty) {
      chips.add(_ChipData(Icons.location_on_rounded, area));
    }
    if (budget.isNotEmpty) {
      chips.add(_ChipData(
          Icons.account_balance_wallet_rounded, budget));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: _loading ? null : _navigate,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Accent bar (right in RTL = first child) ──────────────
                  Container(width: 4, color: accent),

                  // ── Content ──────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type badge + tap indicator
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      accent.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon,
                                        size: 11, color: accent),
                                    const SizedBox(width: 4),
                                    Text(label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        )),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _loading
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: accent),
                                    )
                                  : Icon(
                                      Icons.open_in_new_rounded,
                                      size: 14,
                                      color: accent
                                          .withValues(alpha: 0.55),
                                    ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Pet name
                          Text(
                            petName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          // Owner name
                          if (ownerName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              ownerName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],

                          if (chips.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              children: chips
                                  .map((c) => _InfoChip(
                                      icon: c.icon,
                                      label: c.label,
                                      color: accent))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Pet image (left in RTL = last child) ─────────────────
                  if (petImageUrl.isNotEmpty)
                    SizedBox(
                      width: 86,
                      child: CachedNetworkImage(
                        imageUrl: petImageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: accent.withValues(alpha: 0.08),
                          child: Icon(Icons.pets_rounded,
                              color:
                                  accent.withValues(alpha: 0.35),
                              size: 30),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipData {
  final IconData icon;
  final String label;
  const _ChipData(this.icon, this.label);
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
