import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/breakpoints.dart';
import '../core/layout/expanded_add_pane.dart';
import '../core/layout/expanded_destination.dart';
import '../core/theme/system_overlays.dart';
import '../core/widgets/ambient_background.dart';
import '../core/widgets/bottom_nav.dart';
import '../core/widgets/nav_rail.dart';
import '../features/add_expense/application/add_expense_controller.dart';
import '../features/add_expense/presentation/add_expense_screen.dart';
import '../features/analytics/application/analytics_controller.dart';
import '../features/analytics/presentation/analytics_pane.dart';
import '../features/analytics/presentation/widgets/analytics_header_bar.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/widgets/dashboard_header_bar.dart';
import '../features/profile/presentation/profile_settings_pane.dart';
import '../features/profile/presentation/widgets/account_overview_pane.dart';
import '../features/profile/presentation/widgets/profile_header_bar.dart';
import '../features/transactions/application/transactions_controller.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/transactions/presentation/widgets/activity_feed_pane.dart';
import '../features/transactions/presentation/widgets/transactions_header_bar.dart';

/// Hosts navigation and renders the current destination beside it.
///
/// Compact / medium: bottom nav under the single-column screen from the router.
///
/// Expanded (Fold inner, tablet): a left navigation rail, then one full-width
/// header for the destination and two purpose-built content panes underneath —
/// see [ExpandedDestination]. The shell composes those panes itself rather than
/// using the router's [child], because the top-level screens ship their own
/// hero and chrome for the compact case and a pane must not.
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
    // paired with the feed — the Stats header is then the only month control on
    // screen, and the feed beside it has to follow. Lives here rather than in
    // build() so it stays a reaction to a state change instead of a write
    // during layout.
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
    final isTwoPane = useTwoPane(context);
    final showAdd = ref.watch(expandedAddPaneProvider);
    final addActive =
        isTwoPane && (showAdd || widget.location.startsWith('/transactions'));

    // Compact heroes bleed under the status bar; the expanded header band does
    // the same, except on Stats which has never had a gradient.
    final hasHero = isTwoPane
        ? widget.active != NavTab.analytics
        : (widget.active == NavTab.home ||
              widget.active == NavTab.profile ||
              widget.active == NavTab.transactions);

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
              ? _expandedBody(context, hasHero: hasHero, showAdd: showAdd)
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
    required bool showAdd,
  }) {
    final padding = MediaQuery.paddingOf(context);
    final layout = _layoutFor(widget.location, showAdd: showAdd);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavRail(
          active: widget.active,
          addActive: showAdd || widget.location.startsWith('/transactions'),
          onTap: _onTab,
          onAdd: () => _onAdd(isTwoPane: true),
        ),
        Expanded(
          child: SafeArea(
            left: false,
            // A gradient header draws its own status-bar padding; a flat one
            // needs the inset consumed for it.
            top: !hasHero,
            child: ExpandedDestination(
              // Display-feature bounds are window coordinates; tell the layout
              // how far its own origin sits from the window's, or it will look
              // for the crease in the wrong place now that a rail occupies the
              // left edge.
              origin: Offset(
                padding.left + AppNavRail.width,
                hasHero ? 0 : padding.top,
              ),
              header: layout.header,
              primary: layout.primary,
              secondary: layout.secondary,
              primaryLabel: layout.primaryLabel,
              secondaryLabel: layout.secondaryLabel,
              detailLocation: layout.detailLocation,
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

  _ExpandedLayout _layoutFor(String loc, {required bool showAdd}) {
    // Profile nest + shared/postponed companions: settings always on the left.
    if (_isProfileFamily(loc)) {
      final nested = loc != '/profile';
      return _ExpandedLayout(
        header: const ProfileHeaderBar(),
        primaryLabel: 'Settings',
        secondaryLabel: showAdd
            ? 'Add expense'
            : (nested ? 'Settings detail' : 'Account overview'),
        primary: const ProfileSettingsPane(),
        secondary: showAdd
            ? _addPane()
            : (nested ? widget.child : const AccountOverviewPane()),
        detailLocation: nested ? loc : null,
      );
    }

    if (loc.startsWith('/transactions')) {
      return _ExpandedLayout(
        header: const TransactionsHeaderBar(),
        primaryLabel: 'Transactions',
        secondaryLabel: 'Add expense',
        primary: const TransactionsBody(),
        secondary: _addPane(),
      );
    }

    if (loc.startsWith('/analytics')) {
      return _ExpandedLayout(
        header: const AnalyticsHeaderBar(),
        primaryLabel: 'Analytics',
        secondaryLabel: showAdd ? 'Add expense' : 'Transactions',
        primary: const AnalyticsPane(),
        secondary: showAdd
            ? _addPane()
            : const ActivityFeedPane(showFilter: true),
      );
    }

    // Home (and any other shell path): dashboard cards | activity feed (or Add).
    return _ExpandedLayout(
      header: const DashboardHeaderBar(),
      primaryLabel: 'Home',
      secondaryLabel: showAdd ? 'Add expense' : 'Recent activity',
      primary: const DashboardCardsPane(),
      secondary: showAdd ? _addPane() : const ActivityFeedPane(),
    );
  }

  bool _isProfileFamily(String loc) =>
      loc.startsWith('/profile') || loc == '/shared' || loc == '/postponed';
}

class _ExpandedLayout {
  final Widget header;
  final Widget primary;
  final Widget secondary;
  final String primaryLabel;
  final String secondaryLabel;
  final String? detailLocation;

  const _ExpandedLayout({
    required this.header,
    required this.primary,
    required this.secondary,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.detailLocation,
  });
}
