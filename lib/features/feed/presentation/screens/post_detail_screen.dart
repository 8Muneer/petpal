import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/time_ago_text.dart';
import 'package:petpal/features/feed/domain/entities/feed_comment.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final repo = ref.read(feedRepositoryProvider);
      await repo.addComment(widget.postId, {
        'authorUid': user.uid,
        'authorName': user.displayName ?? user.email?.split('@').first ?? '',
        'authorPhotoUrl':
            ref.read(currentUserProfileProvider).asData?.value?.photoUrl ??
                user.photoURL,
        'content': text,
      });

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text('שגיאה בשליחת התגובה'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showLoginDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text('צריך להתחבר כדי להמשיך',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900)),
          content: Text('התחבר/י כדי לתת לייק, להגיב ולפרסם פוסטים.',
              style: AppTextStyles.bodyMd),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ביטול',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('התחבר/י',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(FeedPost post) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              Text('למחוק את הפוסט?',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          content: Text('הפעולה הזו לא ניתנת לביטול.',
              style: AppTextStyles.bodyMd),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ביטול',
                  style:
                      AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(feedRepositoryProvider).deletePost(post.id);
                if (!mounted) return;
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('מחיקה',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider);
    final commentsAsync = ref.watch(feedCommentsProvider(widget.postId));
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        extendBody: false,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                          width: 0.8),
                    ),
                  ),
                  child: postsAsync.when(
                    loading: () => _headerRow(context, null, uid),
                    error: (_, __) => _headerRow(context, null, uid),
                    data: (posts) {
                      final post =
                          posts.where((p) => p.id == widget.postId).firstOrNull;
                      return _headerRow(context, post, uid);
                    },
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────
            Expanded(
              child: postsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
                error: (e, _) => Center(
                  child: Text('שגיאה: $e',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.error)),
                ),
                data: (posts) {
                  final post =
                      posts.where((p) => p.id == widget.postId).firstOrNull;
                  if (post == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 52,
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('הפוסט לא נמצא',
                              style: AppTextStyles.h3
                                  .copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      // Post card
                      _FullPostCard(
                        post: post,
                        currentUid: uid,
                        onLike: () {
                          if (uid.isEmpty) {
                            _showLoginDialog();
                            return;
                          }
                          ref
                              .read(feedRepositoryProvider)
                              .toggleLike(post.id, uid);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Comments header
                      _CommentsHeader(count: post.commentCount),
                      const SizedBox(height: 12),

                      // Comments list
                      commentsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2),
                          ),
                        ),
                        error: (e, _) => Text('שגיאה בטעינת תגובות: $e',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.error)),
                        data: (comments) {
                          if (comments.isEmpty) {
                            return _EmptyComments();
                          }
                          return Column(
                            children: comments
                                .map((c) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _CommentCard(comment: c),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Comment input bar ────────────────────────────
            _CommentInputBar(
              uid: uid,
              controller: _commentController,
              isSending: _isSending,
              onSend: _isSending ? null : _sendComment,
              onTapWhenGuest: _showLoginDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(BuildContext context, FeedPost? post, String uid) {
    final isTip = post?.type == PostType.tip;
    final isAuthor = post != null && post.authorUid == uid;

    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_forward_rounded),
          color: AppColors.textPrimary,
          tooltip: 'חזור',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isTip ? 'טיפ' : 'פוסט',
                style: AppTextStyles.h3
                    .copyWith(color: AppColors.primary, fontStyle: FontStyle.italic),
              ),
              Text(
                'פיד חדשות · קהילת PetPal',
                style: AppTextStyles.labelSm
                    .copyWith(letterSpacing: 1.2, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (isAuthor) ...[
          IconButton(
            onPressed: () => context.push('/feed/edit', extra: post),
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.primary,
            tooltip: 'ערוך פוסט',
          ),
          IconButton(
            onPressed: () => _confirmDelete(post),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.error,
            tooltip: 'מחק פוסט',
          ),
        ],
      ],
    );
  }
}

// ─── Full post card ───────────────────────────────────────────────────────────

class _FullPostCard extends StatelessWidget {
  final FeedPost post;
  final String currentUid;
  final VoidCallback onLike;

  const _FullPostCard({
    required this.post,
    required this.currentUid,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedBy(currentUid);
    final isTip = post.type == PostType.tip;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              LiveUserAvatar(
                uid: post.authorUid,
                fallbackName: post.authorName,
                fallbackPhotoUrl: post.authorPhotoUrl,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                    TimeAgoText(
                        createdAt: post.createdAt,
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (isTip)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('טיפ',
                          style: AppTextStyles.labelSm.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.warning)),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Content
          Text(
            post.content,
            style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.textPrimary,
              height: 1.7,
            ),
          ),

          // Images
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PostImageGallery(imageUrls: post.imageUrls),
          ],

          const SizedBox(height: 16),

          // Divider
          Divider(color: AppColors.border.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 12),

          // Like row
          Row(
            children: [
              _LikeButton(
                isLiked: isLiked,
                count: post.likes.length,
                onTap: onLike,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Like button ──────────────────────────────────────────────────────────────

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  const _LikeButton(
      {required this.isLiked, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isLiked
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLiked
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.pets_rounded : Icons.pets_outlined,
              size: 20,
              color: isLiked ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 7),
            Text(
              '$count',
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w900,
                color: isLiked ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'לייקים',
              style: AppTextStyles.labelSm.copyWith(
                color: isLiked ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Image gallery ────────────────────────────────────────────────────────────

class _PostImageGallery extends StatefulWidget {
  final List<String> imageUrls;

  const _PostImageGallery({required this.imageUrls});

  @override
  State<_PostImageGallery> createState() => _PostImageGalleryState();
}

class _PostImageGalleryState extends State<_PostImageGallery> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final single = widget.imageUrls.length == 1;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: single
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrls.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _placeholder(),
                  errorWidget: (_, __, ___) => _error(),
                )
              : SizedBox(
                  height: 280,
                  child: PageView.builder(
                    itemCount: widget.imageUrls.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: widget.imageUrls[i],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _error(),
                    ),
                  ),
                ),
        ),
        if (!single) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder() => Container(
        height: 220,
        color: AppColors.surface,
        child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
      );

  Widget _error() => Container(
        height: 220,
        color: AppColors.surface,
        child:
            const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
      );
}

// ─── Comments header ──────────────────────────────────────────────────────────

class _CommentsHeader extends StatelessWidget {
  final int count;
  const _CommentsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'תגובות',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.labelSm.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

// ─── Empty comments ───────────────────────────────────────────────────────────

class _EmptyComments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text(
              'אין תגובות עדיין.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
            Text(
              'היה/י הראשון/ה להגיב!',
              style: AppTextStyles.labelSm,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Comment card ─────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final FeedComment comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return AppCard.outline(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveUserAvatar(
            uid: comment.authorUid,
            fallbackName: comment.authorName,
            fallbackPhotoUrl: comment.authorPhotoUrl,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    TimeAgoText(createdAt: comment.createdAt, style: AppTextStyles.labelSm),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  comment.content,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textPrimary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comment input bar ────────────────────────────────────────────────────────

class _CommentInputBar extends StatelessWidget {
  final String uid;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback? onSend;
  final VoidCallback onTapWhenGuest;

  const _CommentInputBar({
    required this.uid,
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onTapWhenGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5), width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: uid.isEmpty
              ? _GuestInputHint(onTap: onTapWhenGuest)
              : _AuthInputRow(
                  uid: uid,
                  controller: controller,
                  isSending: isSending,
                  onSend: onSend,
                ),
        ),
      ),
    );
  }
}

class _GuestInputHint extends StatelessWidget {
  final VoidCallback onTap;
  const _GuestInputHint({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Text('התחבר/י כדי להגיב...',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _AuthInputRow extends StatelessWidget {
  final String uid;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback? onSend;

  const _AuthInputRow({
    required this.uid,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LiveUserAvatar(uid: uid, fallbackName: '', size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              textDirection: TextDirection.rtl,
              minLines: 1,
              maxLines: 4,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'כתוב/י תגובה...',
                hintStyle:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isSending
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.primary, AppColors.statusOpen],
                    ),
              color: isSending ? AppColors.border : null,
            ),
            child: isSending
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 19),
          ),
        ),
      ],
    );
  }
}
