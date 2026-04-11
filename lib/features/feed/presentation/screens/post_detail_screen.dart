import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_input.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
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
        'authorPhotoUrl': ref.read(currentUserProfileProvider).asData?.value?.photoUrl ?? user.photoURL,
        'content': text,
      });

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text('שגיאה בשליחת התגובה'),
          backgroundColor: const Color(0xFFFB7185),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showLoginDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'צריך להתחבר כדי להמשיך',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'התחבר/י כדי לתת לייק, להגיב ולפרסם פוסטים.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
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
                  borderRadius: BorderRadius.circular(14),
                ),
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
          title: const Text(
            'למחוק את הפוסט?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('הפעולה הזו לא ניתנת לביטול.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(feedRepositoryProvider).deletePost(post.id);
                if (!mounted) return;
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB7185),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
        body: SafeArea(
          child: Column(
            children: [
              // Content
              Expanded(
                child: postsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                  error: (e, _) => Center(child: Text('שגיאה: $e')),
                  data: (posts) {
                    final post = posts
                        .where((p) => p.id == widget.postId)
                        .firstOrNull;
                    if (post == null) {
                      return const Center(
                        child: Text('הפוסט לא נמצא'),
                      );
                    }

                    final isAuthor = post.authorUid == uid;

                    return Column(
                      children: [
                        // Top bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.arrow_forward_rounded),
                                color: AppColors.textPrimary,
                              ),
                              const Expanded(
                                child: Text(
                                  'פוסט',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isAuthor)
                                IconButton(
                                  onPressed: () => _confirmDelete(post),
                                  icon: const Icon(
                                      Icons.delete_outline_rounded),
                                  color: const Color(0xFFFB7185),
                                  tooltip: 'מחק פוסט',
                                ),
                            ],
                          ),
                        ),

                        // Scrollable content
                        Expanded(
                          child: ListView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            children: [
                              _FullPostCard(
                                post: post,
                                currentUid: uid,
                                onLike: () {
                                  if (uid.isEmpty) {
                                    _showLoginDialog(context);
                                    return;
                                  }
                                  ref
                                      .read(feedRepositoryProvider)
                                      .toggleLike(post.id, uid);
                                },
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'תגובות (${post.commentCount})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              commentsAsync.when(
                                loading: () => const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                error: (e, _) =>
                                    Text('שגיאה בטעינת תגובות: $e'),
                                data: (comments) {
                                  if (comments.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Center(
                                        child: Text(
                                          'אין תגובות עדיין. היה/י הראשון/ה!',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: comments
                                        .map((c) => Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      bottom: 10),
                                              child:
                                                  _CommentCard(comment: c),
                                            ))
                                        .toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Comment input (or login prompt for guests)
              if (uid.isEmpty)
                InkWell(
                  onTap: () => _showLoginDialog(context),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withOpacity(0.6),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Text(
                          'התחבר/י כדי להגיב...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withOpacity(0.6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            hintText: 'כתוב/י תגובה...',
                            hintStyle: TextStyle(
                              color:
                                  AppColors.textSecondary.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.borderFaint,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isSending ? null : _sendComment,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [AppColors.primary, AppColors.statusOpen],
                            ),
                          ),
                          child: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullPostCard extends StatelessWidget {
  final FeedPost post;
  final String currentUid;
  final VoidCallback onLike;

  const _FullPostCard({
    required this.post,
    required this.currentUid,
    required this.onLike,
  });

  String get _timeAgo {
    if (post.createdAt == null) return '';
    final diff = DateTime.now().difference(post.createdAt!);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${post.createdAt!.day}/${post.createdAt!.month}/${post.createdAt!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedBy(currentUid);

    return AppCard(
      
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveUserAvatar(
                uid: post.authorUid,
                fallbackName: post.authorName,
                fallbackPhotoUrl: post.authorPhotoUrl,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (post.type == PostType.tip)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 14, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text(
                        'טיפ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 220,
                  color: AppColors.borderFaint,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 220,
                  color: AppColors.borderFaint,
                  child: const Icon(Icons.broken_image_rounded,
                      color: AppColors.textMuted),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onLike,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isLiked
                        ? const Color(0xFFFB7185).withOpacity(0.12)
                        : AppColors.borderFaint,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: isLiked
                            ? const Color(0xFFFB7185)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likes.length} לייקים',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isLiked
                              ? const Color(0xFFFB7185)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final FeedComment comment;

  const _CommentCard({required this.comment});

  String get _timeAgo {
    if (comment.createdAt == null) return '';
    final diff = DateTime.now().difference(comment.createdAt!);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    return 'לפני ${diff.inDays} ימים';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveUserAvatar(
            uid: comment.authorUid,
            fallbackName: comment.authorName,
            fallbackPhotoUrl: comment.authorPhotoUrl,
            size: 32,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
