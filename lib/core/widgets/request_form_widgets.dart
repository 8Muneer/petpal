import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/pets/domain/entities/pet.dart';

/// Shared label widget used in walk/sitting request forms.
class RequestFieldLabel extends StatelessWidget {
  final String text;
  const RequestFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Horizontal scrollable pet selector used in walk/sitting request forms.
class PetSelectorRow extends StatelessWidget {
  final List<Pet> pets;
  final Pet? selectedPet;
  final ValueChanged<Pet> onSelect;
  final VoidCallback onAddNew;

  const PetSelectorRow({
    super.key,
    required this.pets,
    required this.selectedPet,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: pets.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == pets.length) {
            return GestureDetector(
              onTap: onAddNew,
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFaint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'הוסף חיה',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final pet = pets[i];
          final isSelected = selectedPet?.id == pet.id;
          return GestureDetector(
            onTap: () => onSelect(pet),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 80,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryFaint : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.surface,
                        backgroundImage: (pet.imageUrl?.isNotEmpty == true)
                            ? CachedNetworkImageProvider(pet.imageUrl!)
                            : null,
                        child: (pet.imageUrl?.isNotEmpty != true)
                            ? const Icon(Icons.pets_rounded,
                                size: 22, color: AppColors.textMuted)
                            : null,
                      ),
                      if (isSelected)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check,
                                size: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      pet.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    pet.type,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
