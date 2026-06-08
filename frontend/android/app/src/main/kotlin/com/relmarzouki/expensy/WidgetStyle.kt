package com.relmarzouki.expensy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.widget.RemoteViews

/// Renders the configurable background for the home-screen widgets.
///
/// RemoteViews can't mutate a shape drawable's fill, and `setBackgroundColor`
/// flattens rounded corners — so we paint a rounded-rect bitmap sized to the
/// widget and set it on a background ImageView (`R.id.widget_bg`). This single
/// path supports arbitrary color + opacity + transparency with crisp corners on
/// every API level.
object WidgetStyle {

    private const val CORNER_DP = 18f

    /// Resolves the user's per-widget config, paints the background, and returns
    /// whether the effective background is dark — so the caller can pick legible
    /// text colors. Text contrast follows the color mode only (not opacity), so
    /// a transparent background stays predictable.
    fun applyBackground(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        views: RemoteViews,
        prefix: String,
        data: SharedPreferences,
    ): Boolean {
        val style = data.getString("wcfg_${prefix}_bg", "solid") ?: "solid"
        val opacity = data.getString("wcfg_${prefix}_opacity", "85")?.toIntOrNull() ?: 85
        val mode = data.getString("wcfg_${prefix}_color", "match") ?: "match"

        val isDark = when (mode) {
            "dark" -> true
            "light" -> false
            else -> systemInNightMode(context)
        }

        val base = context.getColor(
            if (isDark) R.color.widget_bg_dark else R.color.widget_bg_light,
        )
        val alpha = if (style == "transparent") 0 else (opacity.coerceIn(0, 100) * 255 / 100)
        val argb = (base and 0x00FFFFFF) or (alpha shl 24)

        val (wPx, hPx) = widgetSizePx(context, appWidgetManager, appWidgetId)
        val radius = dp(context, CORNER_DP)
        views.setImageViewBitmap(R.id.widget_bg, roundedRectBitmap(wPx, hPx, radius, argb))
        return isDark
    }

    /// Ink/muted colors for the resolved theme, for providers to apply to text.
    fun inkColor(context: Context, isDark: Boolean): Int =
        context.getColor(if (isDark) R.color.widget_ink_dark else R.color.widget_ink_light)

    fun mutedColor(context: Context, isDark: Boolean): Int =
        context.getColor(if (isDark) R.color.widget_muted_dark else R.color.widget_muted_light)

    private fun systemInNightMode(context: Context): Boolean {
        val mask = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return mask == Configuration.UI_MODE_NIGHT_YES
    }

    /// Best-effort widget pixel size from the host's options. Uses the portrait
    /// aspect (min width × max height) so fitXY keeps the corners circular in the
    /// common case; falls back to sane defaults before options are populated.
    private fun widgetSizePx(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ): Pair<Int, Int> {
        val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val density = context.resources.displayMetrics.density
        val minW = opts?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0
        val maxH = opts?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0) ?: 0
        val wDp = if (minW > 0) minW else 250
        val hDp = if (maxH > 0) maxH else 110
        val w = (wDp * density).toInt().coerceIn(1, 1500)
        val h = (hDp * density).toInt().coerceIn(1, 1500)
        return Pair(w, h)
    }

    private fun roundedRectBitmap(w: Int, h: Int, radius: Float, color: Int): Bitmap {
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = radius
            setColor(color)
            setBounds(0, 0, w, h)
            draw(canvas)
        }
        return bmp
    }

    private fun dp(context: Context, value: Float): Float = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        value,
        context.resources.displayMetrics,
    )
}
