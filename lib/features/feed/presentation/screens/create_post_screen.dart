import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  PostType _type = PostType.post;
  XFile? _pickedImage;
  bool _isPublishing = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imageService = ref.read(feedImageServiceProvider);
    final file = await imageService.pickImage(ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showSnack('יש לכתוב תוכן לפוסט', isError: true);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl;

      // Upload image if exists and type is post
      if (_type == PostType.post && _pickedImage != null) {
        // Use a temp ID, then update after creating the doc
        final tempId =
            FirebaseFirestore.instance.collection('posts').doc().id;
        final imageService = ref.read(feedImageServiceProvider);
        imageUrl = await imageService.uploadPostImage(tempId, _pickedImage!);
      }

      final repo = ref.read(feedRepositoryProvider);
      await repo.createPost({
        'authorUid': user.uid,
        'authorName': user.displayName ?? user.email?.split('@').first ?? '',
        'authorPhotoUrl': user.photoURL,
        'type': _type == PostType.tip ? 'tip' : 'post',
        'content': content,
        'imageUrl': imageUrl,
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
      _showSnack('שגיאה בפרסום הפוסט', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFFB7185) : const Color(0xFF0F766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PetPalScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: const Color(0xFF0F172A),
                    ),
                    const Expanded(
                      child: Text(
                        'פוסט חדש',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // Type selector
                    GlassCard(
                      useBlur: true,
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TypeChip(
                              label: 'פוסט',
                              icon: Icons.article_outlined,
                              selected: _type == PostType.post,
                              onTap: () =>
                                  setState(() => _type = PostType.post),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TypeChip(
                              label: 'טיפ',
                              icon: Icons.lightbulb_outline_rounded,
                              selected: _type == PostType.tip,
                              onTap: () {
                                setState(() {
                                  _type = PostType.tip;
                                  _pickedImage = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Content field
                    GlassCard(
                      useBlur: true,
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _contentController,
                        maxLines: 6,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: _type == PostType.tip
                              ? 'שתף/י טיפ שימושי...'
                              : 'מה חדש? שתף/י עם הקהילה...',
                          hintStyle: TextStyle(
                            color:
                                const Color(0xFF64748B).withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Image picker (only for post type)
                    if (_type == PostType.post) ...[
                      const SizedBox(height: 14),
                      if (_pickedImage != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                File(_pickedImage!.path),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _pickedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _pickImage,
                          child: GlassCard(
                            useBlur: true,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 36,
                                  color: const Color(0xFF64748B)
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'הוסף/י תמונה',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B)
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 20),

                    // Publish button
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _isPublishing ? null : _publish,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                          ),
                        ),
                        child: Center(
                          child: _isPublishing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'פרסם/י',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
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

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? const Color(0xFF0F766E)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
