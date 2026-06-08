package com.relmarzouki.expensy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Budget-usage widget: monthly progress bar plus "x% used" and the
/// "spent of amount" line. Tapping opens the app home (expensy://home).
class BudgetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_budget)

            val isDark = WidgetStyle.applyBackground(
                context, appWidgetManager, id, views, "budget", widgetData,
            )
            views.setTextColor(R.id.budget_title, WidgetStyle.inkColor(context, isDark))
            views.setTextColor(R.id.budget_detail, WidgetStyle.mutedColor(context, isDark))

            val isSet = widgetData.getBoolean("budget_is_set", false)
            val pct = widgetData.getString("budget_pct", "0")?.toIntOrNull() ?: 0

            if (isSet) {
                val spent = widgetData.getString("budget_spent", "") ?: ""
                val amount = widgetData.getString("budget_amount", "") ?: ""
                views.setTextViewText(R.id.budget_status, "$pct% used")
                views.setTextViewText(
                    R.id.budget_detail,
                    "$spent of $amount spent this month",
                )
                views.setProgressBar(R.id.budget_progress, 100, pct.coerceIn(0, 100), false)
            } else {
                views.setTextViewText(
                    R.id.budget_status,
                    context.getString(R.string.widget_budget_not_set),
                )
                views.setTextViewText(
                    R.id.budget_detail,
                    context.getString(R.string.widget_budget_hint),
                )
                views.setProgressBar(R.id.budget_progress, 100, 0, false)
            }

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("expensy://home"),
            )
            views.setOnClickPendingIntent(R.id.budget_root, pendingIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
