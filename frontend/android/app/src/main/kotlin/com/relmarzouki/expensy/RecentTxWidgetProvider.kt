package com.relmarzouki.expensy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Recent-transactions widget: up to 3 fixed rows (category chip, label/note,
/// signed amount, relative date). Tapping opens the transactions list
/// (expensy://transactions).
///
/// Uses fixed rows rather than a collection (RemoteViewsService) for simplicity;
/// switch to a collection widget if a dynamic-length list is ever needed.
class RecentTxWidgetProvider : HomeWidgetProvider() {

    private val rowIds = intArrayOf(R.id.tx_row_0, R.id.tx_row_1, R.id.tx_row_2)
    private val chipIds = intArrayOf(R.id.tx0_chip, R.id.tx1_chip, R.id.tx2_chip)
    private val labelIds = intArrayOf(R.id.tx0_label, R.id.tx1_label, R.id.tx2_label)
    private val noteIds = intArrayOf(R.id.tx0_note, R.id.tx1_note, R.id.tx2_note)
    private val amountIds = intArrayOf(R.id.tx0_amount, R.id.tx1_amount, R.id.tx2_amount)
    private val dateIds = intArrayOf(R.id.tx0_date, R.id.tx1_date, R.id.tx2_date)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val successColor = context.getColor(R.color.widget_success)

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_recent_tx)

            val isDark = WidgetStyle.applyBackground(
                context, appWidgetManager, id, views, "recent", widgetData,
            )
            val inkColor = WidgetStyle.inkColor(context, isDark)
            val mutedColor = WidgetStyle.mutedColor(context, isDark)

            views.setTextColor(R.id.recent_title, inkColor)
            views.setTextColor(R.id.tx_empty, mutedColor)

            val count = widgetData.getString("tx_count", "0")?.toIntOrNull() ?: 0

            views.setViewVisibility(
                R.id.tx_empty,
                if (count == 0) View.VISIBLE else View.GONE,
            )

            for (i in 0 until 3) {
                if (i < count) {
                    views.setViewVisibility(rowIds[i], View.VISIBLE)

                    val abbr = widgetData.getString("tx${i}_abbr", "") ?: ""
                    val label = widgetData.getString("tx${i}_label", "") ?: ""
                    val note = widgetData.getString("tx${i}_note", "") ?: ""
                    val amount = widgetData.getString("tx${i}_amount", "") ?: ""
                    val date = widgetData.getString("tx${i}_date", "") ?: ""
                    val isIncome = widgetData.getBoolean("tx${i}_income", false)
                    val chipColor = parseColorOrNull(
                        widgetData.getString("tx${i}_color", null),
                    ) ?: inkColor

                    views.setTextViewText(chipIds[i], abbr)
                    views.setTextColor(chipIds[i], chipColor)
                    views.setTextViewText(labelIds[i], label)
                    views.setTextColor(labelIds[i], inkColor)
                    views.setTextViewText(amountIds[i], amount)
                    views.setTextColor(amountIds[i], if (isIncome) successColor else inkColor)
                    views.setTextViewText(dateIds[i], date)
                    views.setTextColor(dateIds[i], mutedColor)

                    if (note.isEmpty()) {
                        views.setViewVisibility(noteIds[i], View.GONE)
                    } else {
                        views.setViewVisibility(noteIds[i], View.VISIBLE)
                        views.setTextViewText(noteIds[i], note)
                        views.setTextColor(noteIds[i], mutedColor)
                    }
                } else {
                    views.setViewVisibility(rowIds[i], View.GONE)
                }
            }

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("expensy://transactions"),
            )
            views.setOnClickPendingIntent(R.id.recent_root, pendingIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun parseColorOrNull(hex: String?): Int? {
        if (hex.isNullOrBlank()) return null
        return try {
            Color.parseColor(hex)
        } catch (_: IllegalArgumentException) {
            null
        }
    }
}
