import 'package:flutter/material.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../goals/presentation/widgets/goals_summary_card.dart';
import '../../../recurring_confirmations/presentation/postponed_items_card.dart';
import '../../../recurring_expenses/presentation/widgets/upcoming_bills_card.dart';
import '../../application/dashboard_controller.dart';
import 'budget_card.dart';
import 'onboarding_card.dart';
import 'recent_transactions_section.dart';

/// The dashboard's card stack, below whatever hero is above it.
///
/// Shared by the compact screen (as a sliver) and by the expanded shell's left
/// pane (as a scroll view). [showRecent] is false in the pane because the
/// companion pane already shows the full activity feed; on a phone there is no
/// companion, so the section earns its place.
class DashboardCards extends StatelessWidget {
  final DashboardState state;
  final bool showRecent;

  const DashboardCards({
    super.key,
    required this.state,
    this.showRecent = true,
  });

  bool get _isFirstRun {
    final s = state.summary;
    return state.recentTransactions.isEmpty &&
        s.balance == 0 &&
        s.income == 0 &&
        s.expenses == 0;
  }

  List<Widget> children(BuildContext context) => [
    if (_isFirstRun) ...[const OnboardingCard(), const SizedBox(height: 14)],
    BudgetCard(budget: state.summary.budget),
    const SizedBox(height: 14),
    const GoalsSummaryCard(),
    const UpcomingBillsCard(),
    const PostponedItemsCard(),
    // With the onboarding card up the dashboard already has a primary CTA, so
    // the section's own empty state would only repeat it.
    if (!_isFirstRun && showRecent)
      RecentTransactionsSection(transactions: state.recentTransactions),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        pageInsetOf(context),
        16,
        pageInsetOf(context),
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: children(context),
    );
  }
}
