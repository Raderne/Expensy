import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/collapsing_hero.dart';
import '../../../core/widgets/header_back_button.dart';
import '../../profile/presentation/widgets/edit_sheet_shell.dart';
import '../data/contacts_repository.dart';
import '../domain/contact.dart';
import 'widgets/edit_contact_sheet.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contactsViewProvider);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverCollapsingHero(
            minHeight: topInset + 56,
            maxHeight: topInset + 92,
            expanded: Padding(
              padding: EdgeInsets.only(top: topInset + 8, left: 18, right: 18),
              child: SizedBox(height: 56, child: _header(context, 'People')),
            ),
            collapsed: Padding(
              padding: EdgeInsets.only(top: topInset, left: 18, right: 18),
              child: SizedBox(height: 56, child: _header(context, 'People')),
            ),
          ),
          async.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (_, _) => SliverFillRemaining(
              child: Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(contactsProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
            data: (contacts) => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                pageInsetOf(context),
                16,
                pageInsetOf(context),
                28,
              ),
              sliver: SliverList.list(
                children: [
                  if (contacts.isEmpty)
                    const _EmptyState()
                  else
                    ...contacts.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ContactCard(
                          contact: c,
                          onEdit: () => _openEdit(context, c),
                          onDelete: () => _confirmDelete(context, ref, c),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _AddButton(onTap: () => _openAdd(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title) => Row(
    children: [
      HeaderBackButton.onHero(onTap: () => context.pop()),
      const Spacer(),
      Text(title, style: AppTextStyles.titleM.copyWith(color: Colors.white)),
      const Spacer(),
      const SizedBox(width: 44),
    ],
  );

  Future<void> _openAdd(BuildContext context) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => const EditContactSheet(),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact added'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openEdit(BuildContext context, Contact contact) async {
    final ok = await showEditSheet<bool>(
      context,
      (_) => EditContactSheet(existing: contact),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Contact contact,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove ${contact.name}?', style: AppTextStyles.titleM),
        content: Text(
          'Existing shared expenses keep their record. You just won\'t be able to split new ones with them.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.inkMid,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(contactsRepositoryProvider).delete(contact.id);
    ref.invalidate(contactsProvider);
    messenger.showSnackBar(const SnackBar(content: Text('Contact removed')));
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              ContactAvatar(contact: contact),
              const SizedBox(width: 12),
              Expanded(
                child: Text(contact.name, style: AppTextStyles.bodyStrong),
              ),
              if (contact.pending)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text('Syncing', style: AppTextStyles.mutedSmall),
                ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round initials avatar tinted with the contact's colour. Reused across the
/// shared-expense surfaces.
class ContactAvatar extends StatelessWidget {
  final Contact contact;
  final double size;
  const ContactAvatar({super.key, required this.contact, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final color = contact.colorValue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        contact.initials,
        style: AppTextStyles.labelStrong.copyWith(
          color: color,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.group_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text('No contacts yet', style: AppTextStyles.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'Add the people you split bills with — a sibling, flatmate, or friend.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Add contact',
                style: AppTextStyles.labelStrong.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
