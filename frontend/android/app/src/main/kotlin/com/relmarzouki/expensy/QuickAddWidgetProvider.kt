package com.relmarzouki.expensy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Quick-add widget: a single button that deep-links into the app's add-expense
/// modal (expensy://add). Holds no data of its own.
class QuickAddWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_quick_add)

            val isDark = WidgetStyle.applyBackground(
                context, appWidgetManager, id, views, "quick", widgetData,
            )
            views.setTextColor(R.id.quick_add_title, WidgetStyle.mutedColor(context, isDark))

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("expensy://add"),
            )
            views.setOnClickPendingIntent(R.id.quick_add_root, pendingIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
