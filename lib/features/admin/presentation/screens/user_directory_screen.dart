import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/data/repositories/admin_repository.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_theme.dart';

class UserDirectoryScreen extends ConsumerStatefulWidget {
  const UserDirectoryScreen({super.key});

  @override
  ConsumerState<UserDirectoryScreen> createState() =>
      _UserDirectoryScreenState();
}

class _UserDirectoryScreenState extends ConsumerState<UserDirectoryScreen> {
  String _query = '';
  String _roleFilter = 'הכל'; // הכל | בעל חיה | ספק | מנהל

  static const _roleChips = ['הכל', 'בעל חיה', 'ספק', 'מנהל'];

  String _roleLabel(Map<String, dynamic> u) {
    final raw = (u['role'] ?? u['userType'])?.toString();
    switch (raw) {
      case 'petOwner':
      case 'owner':
        return 'בעל חיה';
      case 'serviceProvider':
      case 'provider':
        return 'ספק';
      case 'admin':
        return 'מנהל';
      default:
        return 'משתמש';
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminRepo = ref.watch(adminRepositoryProvider);

    return Column(
      children: [
        // ── Toolbar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: _AdminSearchField(
            hint: 'חיפוש לפי שם או אימייל…',
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _roleChips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final label = _roleChips[i];
              return _FilterChip(
                label: label,
                selected: _roleFilter == label,
                onTap: () => setState(() => _roleFilter = label),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: adminRepo.watchAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data ?? [];
              if (_query.isNotEmpty) {
                users = users.where((u) {
                  final name = (u['name'] as String?)?.toLowerCase() ?? '';
                  final email = (u['email'] as String?)?.toLowerCase() ?? '';
                  return name.contains(_query) || email.contains(_query);
                }).toList();
              }
              if (_roleFilter != 'הכל') {
                users =
                    users.where((u) => _roleLabel(u) == _roleFilter).toList();
              }

              if (users.isEmpty) {
                return const _EmptyUsers();
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: users.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${users.length} משתמשים',
                          style: AdminText.section),
                    );
                  }
                  final user = users[index - 1];
                  return _UserRow(
                    user: user,
                    roleLabel: _roleLabel(user),
                    onAction: (action) => _handleAction(user, action),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(Map<String, dynamic> user, String action) async {
    final adminRepo = ref.read(adminRepositoryProvider);
    final uid = user['uid'] as String;
    final isActive = user['isActive'] ?? true;
    try {
      switch (action) {
        case 'toggle_status':
          await adminRepo.updateUserStatus(uid, !isActive);
          break;
        case 'add_karma':
          await adminRepo.adjustUserKarma(uid, 10);
          break;
        case 'remove_karma':
          await adminRepo.adjustUserKarma(uid, -10);
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הפעולה בוצעה')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }
}

// ─── Row ─────────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final String roleLabel;
  final ValueChanged<String> onAction;

  const _UserRow({
    required this.user,
    required this.roleLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] as String?)?.trim();
    final email = (user['email'] as String?)?.trim();
    final photoUrl = user['photoUrl'] as String?;
    final isActive = user['isActive'] ?? true;
    final isVerified = user['isVerified'] == true;
    final karma = user['karma'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AdminColors.bg,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? const Icon(Icons.person, color: AdminColors.inkMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name == null || name.isEmpty ? 'ללא שם' : name,
                        style: AdminText.rowTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          size: 15, color: AdminColors.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email == null || email.isEmpty ? 'ללא אימייל' : email,
                  style: AdminText.rowSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(label: roleLabel, color: AdminColors.accent),
                    _Chip(
                      label: isActive ? 'פעיל' : 'חסום',
                      color: isActive ? AppColors.success : AppColors.error,
                    ),
                    _Chip(
                        label: 'קארמה $karma', color: AppColors.twilightIndigo),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AdminColors.inkMuted),
            onSelected: onAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_status',
                child: Text(isActive ? 'חסימת משתמש' : 'שחרור חסימה'),
              ),
              const PopupMenuItem(
                  value: 'add_karma', child: Text('הוספת קארמה (+10)')),
              const PopupMenuItem(
                  value: 'remove_karma', child: Text('הפחתת קארמה (−10)')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared admin pieces ───────────────────────────────────────────────────

class _AdminSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _AdminSearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: AdminColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AdminColors.inkMuted),
        prefixIcon:
            const Icon(Icons.search, size: 20, color: AdminColors.inkMuted),
        filled: true,
        fillColor: AdminColors.panel,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AdminColors.accent : AdminColors.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AdminColors.accent : AdminColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AdminColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined,
              size: 56, color: AdminColors.inkMuted),
          SizedBox(height: 14),
          Text('לא נמצאו משתמשים', style: AdminText.rowTitle),
          SizedBox(height: 2),
          Text('נסה/י חיפוש או סינון אחר', style: AdminText.rowSub),
        ],
      ),
    );
  }
}
