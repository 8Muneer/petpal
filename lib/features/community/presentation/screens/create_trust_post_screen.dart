import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/community/presentation/providers/create_post_provider.dart';
import 'package:petpal/features/community/presentation/widgets/category_chip_selector.dart';
import 'package:petpal/features/community/presentation/widgets/photo_picker_grid.dart';
import 'package:petpal/features/community/presentation/widgets/service_lookup_field.dart';

class CreateTrustPostScreen extends ConsumerStatefulWidget {
  const CreateTrustPostScreen({super.key});

  @override
  ConsumerState<CreateTrustPostScreen> createState() => _CreateTrustPostScreenState();
}

class _CreateTrustPostScreenState extends ConsumerState<CreateTrustPostScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(createPostProvider);
    if (state.content.isEmpty && state.imagePaths.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('לבטל את הפוסט?'),
        content: const Text('התוכן שכתבת יימחק.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('המשך בעריכה'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק פוסט'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPostProvider);
    final isValid = state.isValid;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        appBar: AppBar(
          backgroundColor: AppColors.pureWhite,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.onSurface),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          title: Text('פוסט חדש', style: AppTextStyles.h3),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: state.isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: isValid
                          ? () async {
                              final user = ref.read(authStateChangesProvider).asData?.value;
                              if (user == null) return;

                              final success = await ref.read(createPostProvider.notifier).submit(
                                    authorId: user.uid,
                                    authorName: user.displayName ?? 'Neighbor',
                                    authorPhotoUrl: user.photoURL ?? 'https://i.pravatar.cc/150?u=${user.uid}',
                                    authorNeighborhood: 'Brooklyn Heights', // Mock for now
                                  );
                              if (success && mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('הפוסט פורסם בהצלחה!')),
                                );
                              }
                            }
                          : null,
                      style: TextButton.styleFrom(
                        backgroundColor: isValid ? AppColors.primary : AppColors.surface,
                        foregroundColor: isValid ? Colors.white : AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('פרסם', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // User Info Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(ref.watch(authStateChangesProvider).asData?.value?.photoURL ?? 'https://i.pravatar.cc/150?u=current_user'),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(authStateChangesProvider).asData?.value?.displayName ?? 'Neighbor',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('קהילה גלובלית', style: AppTextStyles.labelSm),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content Input
              TextField(
                controller: _controller,
                maxLines: 8,
                minLines: 3,
                onChanged: (val) => ref.read(createPostProvider.notifier).setContent(val),
                decoration: InputDecoration(
                  hintText: 'מה תרצה לשתף עם הקהילה?',
                  hintStyle: AppTextStyles.bodyLg.copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
                style: AppTextStyles.bodyLg,
              ),
              const SizedBox(height: 24),

              // Photo Picker
              const PhotoPickerGrid(),
              const SizedBox(height: 32),

              // Category Selector
              const CategoryChipSelector(),
              const SizedBox(height: 32),

              // Service Tagging
              const ServiceLookupField(),
              const SizedBox(height: 100), // Extra space for scrolling
            ],
          ),
        ),
      ),
    );
  }
}
