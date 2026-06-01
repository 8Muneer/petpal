import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/data/repositories/admin_repository.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_ui_components.dart';

class UserDirectoryScreen extends ConsumerStatefulWidget {
  const UserDirectoryScreen({super.key});

  @override
  ConsumerState<UserDirectoryScreen> createState() => _UserDirectoryScreenState();
}

class _UserDirectoryScreenState extends ConsumerState<UserDirectoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final adminRepo = ref.watch(adminRepositoryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: adminRepo.watchAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data ?? [];
              
              if (_searchQuery.isNotEmpty) {
                users = users.where((u) {
                  final name = (u['name'] as String?)?.toLowerCase() ?? '';
                  final email = (u['email'] as String?)?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();
              }

              if (users.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_outlined, size: 64, color: AppColors.borderFaint),
                      SizedBox(height: 16),
                      Text('No users found', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserCard(context, user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final bool isActive = user['isActive'] ?? true;
    final int karma = user['karma'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user['photoUrl'] != null ? NetworkImage(user['photoUrl']) : null,
          child: user['photoUrl'] == null ? const Icon(Icons.person) : null,
        ),
        title: Row(
          children: [
            Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (user['isVerified'] == true) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 16, color: Colors.blue),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? 'No email', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                AdminStatusBadge(
                  label: isActive ? 'ACTIVE' : 'SUSPENDED',
                  color: isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                AdminStatusBadge(label: 'KARMA: $karma', color: Colors.purple),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (val) => _handleAction(user['uid'], val, isActive),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'toggle_status', child: Text(isActive ? 'Suspend User' : 'Activate User')),
            const PopupMenuItem(value: 'add_karma', child: Text('Give Karma (+10)')),
            const PopupMenuItem(value: 'remove_karma', child: Text('Deduct Karma (-10)')),
          ],
        ),
      ),
    );
  }

  void _handleAction(String userId, String action, bool currentStatus) async {
    final adminRepo = ref.read(adminRepositoryProvider);
    
    try {
      if (action == 'toggle_status') {
        await adminRepo.updateUserStatus(userId, !currentStatus);
      } else if (action == 'add_karma') {
        await adminRepo.adjustUserKarma(userId, 10);
      } else if (action == 'remove_karma') {
        await adminRepo.adjustUserKarma(userId, -10);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
