import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Shared chrome for every Profile edit bottom sheet — drag handle, title,
/// caption, body, and a primary action button that owns its busy + error UI.
class EditSheetShell extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget child;
  final String actionLabel;
  final bool actionEnabled;
  final bool saving;
  final String? error;
  final VoidCallback onAction;

  const EditSheetShell({
    super.key,
    required this.title,
    this.caption,
    required this.child,
    required this.actionLabel,
    required this.actionEnabled,
    required this.saving,
    required this.error,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight - bottomInset),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000C22),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.inkFaint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(title, style: AppTextStyles.titleM),
                          if (caption != null) ...[
                            const SizedBox(height: 4),
                            Text(caption!, style: AppTextStyles.body),
                          ],
                          const SizedBox(height: 16),
                          child,
                          if (error != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              error!,
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  _ActionButton(
                    label: actionLabel,
                    enabled: actionEnabled,
                    saving: saving,
                    onTap: onAction,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool saving;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && !saving ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.inkFaint,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.27),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: AppTextStyles.labelStrong.copyWith(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Common helper to open any of the edit sheets with the same look + behavior.
Future<T?> showEditSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000C22),
    builder: builder,
  );
}
