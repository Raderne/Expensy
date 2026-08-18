import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/breakpoints.dart';
import '../core/layout/expanded_add_pane.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/system_overlays.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/nav_rail.dart';
import '../core/widgets/two_pane.dart';
import '../features/add_expense/application/add_expense_controller.dart';
import '../features/add_expense/presentation/add_expense_screen.dart';
import '../features/analytics/application/analytics_controller.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/transactions/application/transactions_controller.dart';
import '../features/transactions/presentation/transactions_screen.dart';

/// Hosts navigation and renders the current branch (child) beside it.
///
/// Compact / medium: bottom nav under a single column. Expanded (Fold inner,
/// tablet): a left navigation rail beside a [TwoPane] pairing.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final NavTab active;
  final String location;

  const AppShell({
    super.key,
    required this.child,
    required this.active,
    required this.location,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Previous two-pane state, so folding the device is detected as a transition
  /// rather than inferred from the current frame alone.
  bool? _wasTwoPane;

  @override
  void initState() {
    super.initState();
    // Keep the transactions month in step with analytics whenever Stats is
    // paired with the list. Lives here rather than in build() so it stays a
    // reaction to a state change instead of a write during layout.
    ref.listenManual(analyticsControllerProvider, (_, next) {
      if (!mounted) return;
      if (!widget.location.startsWith('/analytics')) return;
      if (!useTwoPane(context)) return;
      final month = next.asData?.value.month;
      if (month == null) return;
      final tx = ref.read(transactionsControllerProvider).asData?.value;
      if (tx == null || tx.month == month) return;
      ref.read(transactionsControllerProvider.notifier).setMonth(month);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTwoPane = useTwoPane(context);
    final was = _wasTwoPane;
    _wasTwoPane = isTwoPane;
    if (was == true && !isTwoPane) _handleFoldToCompact();
  }

  /// The window shrank below the two-pane threshold — the device was folded, or
  /// the app was dropped into split screen. An Add Expense companion pane has
  /// nowhere to go in a single column, so carry a started entry into the
  /// fullscreen route rather than letting it disappear. The draft itself lives
  /// in [addExpenseControllerProvider], a keep-alive Notifier, so it survives
  /// the rebuild untouched.
  void _handleFoldToCompact() {
    if (!ref.read(expandedAddPaneProvider)) return;
    ref.read(expandedAddPaneProvider.notifier).close();
    if (!ref.read(addExpenseControllerProvider).hasDraft) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.push('/add');
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasHero =
        widget.active == NavTab.home ||
        widget.active == NavTab.profile ||
        widget.active == NavTab.transactions;

    final isTwoPane = useTwoPane(context);
    final showAdd = ref.watch(expandedAddPaneProvider);
    final addActive =
        isTwoPane && (showAdd || widget.location.startsWith('/transactions'));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasHero
          ? AppSystemOverlays.hero
          : AppSystemOverlays.background(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // The bottom bar is translucent and content reads through it. With a
        // rail there is no bottom bar to extend behind.
        extendBody: !isTwoPane,
        body: AmbientBackground(
          child: isTwoPane
              ? _expandedBody(
                  context,
                  hasHero: hasHero,
                  addActive: addActive,
                  showAdd: showAdd,
                )
              : SafeArea(top: !hasHero, bottom: false, child: widget.child),
        ),
        bottomNavigationBar: isTwoPane
            ? null
            : BottomNav(
                active: widget.active,
                addActive: addActive,
                onTap: _onTab,
                onAdd: () => _onAdd(isTwoPane: false),
              ),
      ),
    );
  }

  Widget _expandedBody(
    BuildContext context, {
    required bool hasHero,
    required bool addActive,
    required bool showAdd,
  }) {
    final padding = MediaQuery.paddingOf(context);
    // Display-feature bounds are window coordinates; tell TwoPane how far its
    // own origin sits from the window's, or it will look for the crease in the
    // wrong place now that a rail occupies the left edge.
    final origin = Offset(
      padding.left + AppNavRail.width,
      hasHero ? 0 : padding.top,
    );
    final pairing = _pairingFor(widget.location, showAdd: showAdd);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavRail(
          active: widget.active,
          addActive: addActive,
          onTap: _onTab,
          onAdd: () => _onAdd(isTwoPane: true),
        ),
        Expanded(
          child: SafeArea(
            left: false,
            top: !hasHero,
            child: TwoPane(
              origin: origin,
              // Profile is the only list-detail pairing today: the nested route
              // in the right pane is what the left-hand list should mark.
              detailLocation:
                  _isProfileFamily(widget.location) &&
                      widget.location != '/profile'
                  ? widget.location
                  : null,
              primaryLabel: pairing.primaryLabel,
              secondaryLabel: pairing.secondaryLabel,
              primary: pairing.primary,
              secondary: pairing.secondary,
            ),
          ),
        ),
      ],
    );
  }

  void _onTab(NavTab tab) {
    // Leaving a tab clears the FAB-driven add override (List already shows Add).
    if (tab != NavTab.transactions) {
      ref.read(expandedAddPaneProvider.notifier).close();
    }
    context.go(tab.path);
  }

  void _onAdd({required bool isTwoPane}) {
    if (isTwoPane) {
      ref.read(expandedAddPaneProvider.notifier).open();
      // Prefer staying on the current tab so the left pane stays put; if we are
      // somehow on a non-shell path, land on Home.
      if (widget.location.startsWith('/add')) {
        context.go('/');
      }
      return;
    }
    context.push('/add');
  }

  Widget _addPane() => AddExpenseScreen(
    embedded: true,
    onClose: () => ref.read(expandedAddPaneProvider.notifier).close(),
  );

  _PanePair _pairingFor(String loc, {required bool showAdd}) {
    // Profile nest + shared/postponed companions: Profile always on the left.
    if (_isProfileFamily(loc)) {
      final nested = loc != '/profile';
      return _PanePair(
        primaryLabel: 'Profile',
        secondaryLabel: showAdd
            ? 'Add expense'
            : (nested ? 'Settings detail' : 'Settings'),
        primary: const ProfileScreen(),
        secondary: showAdd
            ? _addPane()
            : (nested
                  ? widget.child
                  : const _EmptyCompanion(
                      message: 'Choose a setting',
                      hint: 'Tap an item on the left to open it here.',
                    )),
      );
    }

    if (loc.startsWith('/transactions')) {
      return _PanePair(
        primaryLabel: 'Transactions',
        secondaryLabel: 'Add expense',
        primary: widget.child,
        secondary: _addPane(),
      );
    }

    if (loc.startsWith('/analytics')) {
      return _PanePair(
        primaryLabel: 'Analytics',
        secondaryLabel: showAdd ? 'Add expense' : 'Transactions',
        primary: widget.child,
        secondary: showAdd ? _addPane() : const TransactionsScreen(),
      );
    }

    // Home (and any other shell path): Dashboard | Transactions (or Add).
    return _PanePair(
      primaryLabel: 'Home',
      secondaryLabel: showAdd ? 'Add expense' : 'Transactions',
      primary: loc == '/' || loc.isEmpty
          ? widget.child
          : const DashboardScreen(),
      secondary: showAdd ? _addPane() : const TransactionsScreen(),
    );
  }

  bool _isProfileFamily(String loc) =>
      loc.startsWith('/profile') || loc == '/shared' || loc == '/postponed';
}

class _PanePair {
  final Widget primary;
  final Widget secondary;
  final String primaryLabel;
  final String secondaryLabel;

  const _PanePair({
    required this.primary,
    required this.secondary,
    required this.primaryLabel,
    required this.secondaryLabel,
  });
}

/// Placeholder when Profile has no nested child selected.
class _EmptyCompanion extends StatelessWidget {
  final String message;
  final String hint;

  const _EmptyCompanion({required this.message, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 40, color: AppColors.inkLight),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.titleS,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              style: AppTextStyles.body.copyWith(color: AppColors.inkMid),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
