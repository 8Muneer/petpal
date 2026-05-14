import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/community/presentation/providers/create_post_provider.dart';

class PhotoPickerGrid extends ConsumerWidget {
  const PhotoPickerGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(createPostProvider.select((s) => s.imagePaths));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'תמונות (עד 5)',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
            ),
            Text(
              '${images.length}/5',
              style: AppTextStyles.labelSm,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + 1,
            itemBuilder: (context, index) {
              if (index == images.length) {
                return _AddPhotoButton(onTap: () {
                  // Mock picking
                  ref.read(createPostProvider.notifier).addImage(
                    'https://images.unsplash.com/photo-1544568100-847a948585b9?q=80&w=200'
                  );
                });
              }

              return _PhotoPreview(
                path: images[index],
                onRemove: () => ref.read(createPostProvider.notifier).removeImage(images[index]),
              );
            },
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
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _PhotoPreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              path,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
