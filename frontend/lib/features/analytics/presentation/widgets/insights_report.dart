import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/financial_insights.dart';

/// The calculated report, arranged in one column or two when [wide] is set.
class InsightsReportBody extends StatelessWidget {
  final FinancialInsightsReport report;
  final bool wide;
  final ValueChanged<InsightAction> onOpen;

  const InsightsReportBody({
    super.key,
    required this.report,
    required this.wide,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final takeaway = _Takeaway(report: report);
    final scorecard = _Scorecard(report: report);
    final trend = _Trend(report: report);
    final findings = _Findings(report: report);
    final actions = _Actions(report: report, onOpen: onOpen);
    final contextSection = _Context(report: report);
    final limits = _Limitations(report: report);

    if (!wide) {
      return Column(
        key: const Key('insights-column'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          takeaway,
          const SizedBox(height: 16),
          scorecard,
          const SizedBox(height: 16),
          trend,
          const SizedBox(height: 16),
          findings,
          const SizedBox(height: 16),
          actions,
          const SizedBox(height: 16),
          contextSection,
          limits,
        ],
      );
    }

    return Row(
      key: const Key('insights-two-column'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              takeaway,
              const SizedBox(height: 16),
              scorecard,
              const SizedBox(height: 16),
              trend,
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              findings,
              const SizedBox(height: 16),
              actions,
              const SizedBox(height: 16),
              contextSection,
              limits,
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: AppTextStyles.titleS),
    );
  }
}

class _Takeaway extends StatelessWidget {
  final FinancialInsightsReport report;
  const _Takeaway({required this.report});

  @override
  Widget build(BuildContext context) {
    final generated = insightsFreshnessLabel(
      report.generatedAt,
      DateTime.now(),
    );
    final history =
        'Based on ${report.dataCoverage.historyMonths} months of history';
    final source = report.commentaryAvailable
        ? 'AI-generated · may contain errors'
        : 'Calculated from your data · commentary is unavailable';
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            history,
            style: AppTextStyles.labelStrong.copyWith(
              color: AppColors.primaryInk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.headline,
            style: AppTextStyles.titleM.copyWith(height: 1.3),
          ),
          if (report.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.summary,
              style: AppTextStyles.body.copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          Text('$source · $generated', style: AppTextStyles.muted),
        ],
      ),
    );
  }
}

class _Scorecard extends StatelessWidget {
  final FinancialInsightsReport report;
  const _Scorecard({required this.report});

  @override
  Widget build(BuildContext context) {
    final card = report.scorecard;
    final money = report.currencyCode;
    final saved = card.savingsRatePct == null
        ? '—'
        : '${card.savingsRatePct!.round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('This month'),
        const SizedBox(height: 10),
        _MetricGrid(
          metrics: [
            _Metric(
              label: 'Income',
              value: formatInsightMoney(card.income, money),
              caption: _changeCaption(card.incomeChangePct, 'income'),
            ),
            _Metric(
              label: 'Spending',
              value: formatInsightMoney(card.expenses, money),
              caption: _changeCaption(card.expenseChangePct, 'spending'),
            ),
            _Metric(
              label: 'Net',
              value: formatInsightMoney(card.net, money),
              caption: card.net >= 0
                  ? 'Income left after spending'
                  : 'Spending above income',
            ),
            _Metric(
              label: 'Saved',
              value: saved,
              caption: card.savingsRatePct == null
                  ? 'Needs income this month'
                  : 'Share of income kept',
            ),
          ],
        ),
      ],
    );
  }

  String? _changeCaption(double? pct, String noun) {
    if (pct == null) return null;
    final rounded = pct.round();
    if (rounded == 0) return 'Same $noun as last month';
    final direction = rounded > 0 ? 'Up' : 'Down';
    return '$direction ${rounded.abs()}% $noun vs last month';
  }
}

class _Metric {
  final String label;
  final String value;
  final String? caption;
  const _Metric({required this.label, required this.value, this.caption});
}

class _MetricGrid extends StatelessWidget {
  final List<_Metric> metrics;
  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = scale >= 1.4 || constraints.maxWidth < 320;
        if (stacked) {
          return Column(
            children: [
              for (final metric in metrics) ...[
                _MetricTile(metric: metric),
                const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < metrics.length; i += 2) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _MetricTile(metric: metrics[i])),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < metrics.length
                        ? _MetricTile(metric: metrics[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _Metric metric;
  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: AppTextStyles.muted),
          const SizedBox(height: 4),
          Text(metric.value, style: AppTextStyles.titleM),
          if (metric.caption != null) ...[
            const SizedBox(height: 4),
            Text(
              metric.caption!,
              style: AppTextStyles.muted.copyWith(height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

class _Trend extends StatelessWidget {
  final FinancialInsightsReport report;
  const _Trend({required this.report});

  @override
  Widget build(BuildContext context) {
    final points = report.trend;
    if (points.isEmpty) return const SizedBox.shrink();
    final maxAbs = points.fold<double>(
      0,
      (max, point) => point.net.abs() > max ? point.net.abs() : max,
    );
    final summary = points
        .map(
          (point) =>
              '${_monthShort(point.month)} net ${formatInsightMoney(point.net, report.currencyCode)}',
        )
        .join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Six-month net'),
        const SizedBox(height: 10),
        GlassCard(
          radius: 16,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Semantics(
            label: 'Net by month. $summary',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final point in points)
                    Expanded(
                      child: _TrendBar(point: point, maxAbs: maxAbs),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  final InsightTrendPoint point;
  final double maxAbs;
  const _TrendBar({required this.point, required this.maxAbs});

  @override
  Widget build(BuildContext context) {
    final fraction = maxAbs == 0
        ? 0.0
        : (point.net.abs() / maxAbs).clamp(0.0, 1.0);
    final positive = point.net >= 0;
    final color = !point.hasActivity
        ? AppColors.inkFaint
        : positive
        ? AppColors.success
        : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 88,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 8 + 72 * fraction,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            positive || !point.hasActivity ? '+' : '−',
            style: AppTextStyles.mutedSmall.copyWith(color: color),
          ),
          Text(_monthShort(point.month), style: AppTextStyles.mutedSmall),
        ],
      ),
    );
  }
}

String _monthShort(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  final year = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (year == null || m == null) return month;
  return DateFormat.MMM().format(DateTime.utc(year, m));
}

class _Findings extends StatelessWidget {
  final FinancialInsightsReport report;
  const _Findings({required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('What stood out'),
        const SizedBox(height: 10),
        if (report.insights.isEmpty)
          Text('No commentary for this month.', style: AppTextStyles.body)
        else
          ...report.insights.map((finding) => _FindingRow(finding: finding)),
      ],
    );
  }
}

class _FindingRow extends StatelessWidget {
  final InsightFinding finding;
  const _FindingRow({required this.finding});

  @override
  Widget build(BuildContext context) {
    final (
      Color accent,
      IconData icon,
      String tone,
    ) = switch (finding.sentiment) {
      InsightSentiment.positive => (
        AppColors.successInk,
        Icons.trending_up_rounded,
        'Good sign',
      ),
      InsightSentiment.warning => (
        AppColors.accentInk,
        Icons.warning_amber_rounded,
        'Watch',
      ),
      InsightSentiment.neutral => (
        AppColors.inkLight,
        Icons.info_outline_rounded,
        'Note',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tone,
                    style: AppTextStyles.mutedSmall.copyWith(color: accent),
                  ),
                  const SizedBox(height: 2),
                  Text(finding.title, style: AppTextStyles.bodyStrong),
                  if (finding.detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      finding.detail,
                      style: AppTextStyles.body.copyWith(height: 1.35),
                    ),
                  ],
                  if (finding.evidence.isNotEmpty &&
                      finding.evidence != finding.detail) ...[
                    const SizedBox(height: 4),
                    Text(
                      finding.evidence,
                      style: AppTextStyles.muted.copyWith(height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final FinancialInsightsReport report;
  final ValueChanged<InsightAction> onOpen;
  const _Actions({required this.report, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Next steps'),
        const SizedBox(height: 10),
        if (report.actions.isEmpty)
          Text(
            'No extra step stands out from this month.',
            style: AppTextStyles.body,
          )
        else
          ...report.actions.map(
            (action) => _ActionTile(action: action, onOpen: onOpen),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final InsightAction action;
  final ValueChanged<InsightAction> onOpen;
  const _ActionTile({required this.action, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final destination = insightDestinationLabel(action.target);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 16,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => onOpen(action),
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(action.title, style: AppTextStyles.bodyStrong),
                        if (action.detail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            action.detail,
                            style: AppTextStyles.body.copyWith(height: 1.35),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          destination,
                          style: AppTextStyles.labelStrong.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
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

class _Context extends StatelessWidget {
  final FinancialInsightsReport report;
  const _Context({required this.report});

  @override
  Widget build(BuildContext context) {
    final goals = report.goalOutlook;
    final upcoming = report.commitments.upcoming;
    final notes = report.notes;
    if (goals.isEmpty && upcoming.isEmpty && notes.isEmpty) {
      return const SizedBox.shrink();
    }
    final money = report.currencyCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Goals and upcoming bills'),
        const SizedBox(height: 4),
        Text(
          'Current settings, not only this month.',
          style: AppTextStyles.muted,
        ),
        const SizedBox(height: 10),
        ...goals.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${goal.name}: ${formatInsightMoney(goal.savedAmount, money)} of ${formatInsightMoney(goal.targetAmount, money)} (${goal.progressPct.round()}%)',
              style: AppTextStyles.body.copyWith(height: 1.35),
            ),
          ),
        ),
        ...upcoming.map((bill) {
          final due = DateTime.tryParse(bill.dueAt);
          final when = due == null
              ? ''
              : ' · ${DateFormat('MMM d').format(due.toLocal())}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${bill.label}: ${formatInsightMoney(bill.amount, money)}$when',
              style: AppTextStyles.body.copyWith(height: 1.35),
            ),
          );
        }),
        ...notes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              note.text,
              style: AppTextStyles.body.copyWith(height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

class _Limitations extends StatelessWidget {
  final FinancialInsightsReport report;
  const _Limitations({required this.report});

  @override
  Widget build(BuildContext context) {
    final lines = report.dataCoverage.limitations;
    if (lines.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text('Data used and limitations', style: AppTextStyles.bodyStrong),
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                line,
                style: AppTextStyles.body.copyWith(height: 1.35),
              ),
            ),
          ),
      ],
    );
  }
}
