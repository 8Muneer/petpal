import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

const int _maxImages = 5;

class CreatePostScreen extends ConsumerStatefulWidget {
  final FeedPost? post;
  const CreatePostScreen({super.key, this.post});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  PostType _type = PostType.post;
  final List<String> _existingUrls = []; // already-uploaded URLs (edit mode)
  final List<XFile> _newImages = [];     // freshly picked local files
  bool _isPublishing = false;

  bool get _isEditMode => widget.post != null;
  bool get _isValid => _contentController.text.trim().isNotEmpty;
  int get _totalImageCount => _existingUrls.length + _newImages.length;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _contentController.text = widget.post!.content;
      _type = widget.post!.type;
      _existingUrls.addAll(widget.post!.imageUrls);
    }
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_totalImageCount >= _maxImages) return;
    final imageService = ref.read(feedImageServiceProvider);
    final file = await imageService.pickImage(ImageSource.gallery);
    if (file != null) setState(() => _newImages.add(file));
  }

  void _removeExistingUrl(int index) =>
      setState(() => _existingUrls.removeAt(index));

  void _removeNewImage(int index) =>
      setState(() => _newImages.removeAt(index));

  Future<bool> _confirmDiscard() async {
    final hasContent =
        _contentController.text.trim().isNotEmpty || _newImages.isNotEmpty;
    if (!hasContent) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('לבטל את הפוסט?',
              style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('התוכן שכתבת יימחק.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('המשך בעריכה'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFB7185)),
              child: const Text('בטל פוסט',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isPublishing = true);

    try {
      final repo = ref.read(feedRepositoryProvider);

      if (_isEditMode) {
        // Upload any newly added images and combine with kept existing URLs
        List<String> updatedUrls = List.from(_existingUrls);
        if (_newImages.isNotEmpty) {
          final imageService = ref.read(feedImageServiceProvider);
          final newUrls = await imageService.uploadPostImages(
              widget.post!.id, _newImages);
          updatedUrls.addAll(newUrls);
        }
        await repo.updatePost(widget.post!.id, {
          'type': _type == PostType.tip ? 'tip' : 'post',
          'content': content,
          'imageUrls': updatedUrls,
        });
        if (!mounted) return;
        context.pop();
        _showSnack('הפוסט עודכן בהצלחה!');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final profile = ref.read(currentUserProfileProvider).asData?.value;
      final photoUrl = profile?.photoUrl ?? user.photoURL;

      final postId =
          FirebaseFirestore.instance.collection('posts').doc().id;

      List<String> imageUrls = [];
      if (_type == PostType.post && _newImages.isNotEmpty) {
        final imageService = ref.read(feedImageServiceProvider);
        imageUrls = await imageService.uploadPostImages(postId, _newImages);
      }

      await repo.createPost({
        'authorUid': user.uid,
        'authorName': user.displayName ?? user.email?.split('@').first ?? '',
        'authorPhotoUrl': photoUrl,
        'type': _type == PostType.tip ? 'tip' : 'post',
        'content': content,
        'imageUrls': imageUrls,
        'likes': <String>[],
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      context.pop();
      _showSnack('הפוסט פורסם בהצלחה!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      _showSnack(
          _isEditMode ? 'שגיאה בעדכון הפוסט' : 'שגיאה בפרסום הפוסט',
          isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFFB7185) : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(currentUserProfileProvider).asData?.value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        appBar: AppBar(
          backgroundColor: AppColors.pureWhite,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.onSurface),
            onPressed: () async {
              if (_isEditMode) {
                context.pop();
                return;
              }
              final router = GoRouter.of(context);
              final discard = await _confirmDiscard();
              if (!mounted) return;
              if (discard) router.pop();
            },
          ),
          title: Text(
            _isEditMode ? 'עריכת פוסט' : 'פוסט חדש',
            style: AppTextStyles.h3,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isPublishing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : TextButton(
                      onPressed: _isValid ? _publish : null,
                      style: TextButton.styleFrom(
                        backgroundColor: _isValid
                            ? AppColors.primary
                            : AppColors.surface,
                        foregroundColor: _isValid
                            ? Colors.white
                            : AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        _isEditMode ? 'עדכן' : 'פרסם',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info header
              Row(
                children: [
                  LiveUserAvatar(
                    uid: user?.uid ?? '',
                    fallbackName: user?.displayName ?? '',
                    fallbackPhotoUrl: profile?.photoUrl ?? user?.photoURL,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ??
                            user?.email?.split('@').first ??
                            '',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('קהילת PetPal',
                          style: AppTextStyles.labelSm),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Styled content text box
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _contentController.text.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: 8,
                  minLines: 3,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'מה תרצה לשתף עם הקהילה?',
                    hintStyle: AppTextStyles.bodyLg
                        .copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: AppTextStyles.bodyLg
                      .copyWith(color: AppColors.textPrimary, height: 1.6),
                ),
              ),
              const SizedBox(height: 28),

              // Photo picker (post type only)
              if (_type == PostType.post) ...[
                _PhotoPickerSection(
                  existingUrls: _existingUrls,
                  newImages: _newImages,
                  onAdd: _pickImage,
                  onRemoveExisting: _removeExistingUrl,
                  onRemoveNew: _removeNewImage,
                ),
                const SizedBox(height: 32),
              ],

              // Category / type selector
              _CategorySection(
                selected: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  if (t == PostType.tip) _newImages.clear();
                }),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Photo picker section ─────────────────────────────────────────────────────

class _PhotoPickerSection extends StatelessWidget {
  final List<String> existingUrls;
  final List<XFile> newImages;
  final VoidCallback onAdd;
  final void Function(int) onRemoveExisting;
  final void Function(int) onRemoveNew;

  const _PhotoPickerSection({
    required this.existingUrls,
    required this.newImages,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  int get _total => existingUrls.length + newImages.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'תמונות (עד $_maxImages)',
              style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.bold),
            ),
            Text('$_total/$_maxImages', style: AppTextStyles.labelSm),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Already-uploaded thumbnails (URL)
              for (var i = 0; i < existingUrls.length; i++)
                _UrlPreview(
                  url: existingUrls[i],
                  onRemove: () => onRemoveExisting(i),
                ),
              // Newly picked local thumbnails (XFile)
              for (var i = 0; i < newImages.length; i++)
                _LocalPreview(
                  path: newImages[i].path,
                  onRemove: () => onRemoveNew(i),
                ),
              // Add button (hidden when at max)
              if (_total < _maxImages) _AddPhotoButton(onTap: onAdd),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.add_a_photo_outlined,
            color: AppColors.primary, size: 32),
      ),
    );
  }
}

Widget _removeOverlay(VoidCallback onRemove) => Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
              color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );

class _UrlPreview extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _UrlPreview({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  color: AppColors.borderFaint,
                  child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))),
              errorWidget: (_, __, ___) => Container(
                  color: AppColors.borderFaint,
                  child: const Icon(Icons.broken_image_rounded,
                      color: AppColors.textMuted)),
            ),
          ),
          _removeOverlay(onRemove),
        ],
      ),
    );
  }
}

class _LocalPreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _LocalPreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          _removeOverlay(onRemove),
        ],
      ),
    );
  }
}


// ─── Category / type selector ─────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final PostType selected;
  final void Function(PostType) onChanged;

  const _CategorySection(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const categories = [
      (PostType.post, 'פוסט'),
      (PostType.tip, 'טיפ'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'על מה הפוסט?',
          style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurface, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final (type, label) = categories[index];
              final isSelected = type == selected;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(type),
                  backgroundColor: AppColors.pureWhite,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
