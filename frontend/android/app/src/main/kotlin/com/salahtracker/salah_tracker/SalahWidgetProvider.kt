package com.salahtracker.salah_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Android AppWidgetProvider for the Salah Tracker home screen widget.
 *
 * Renders a GitHub-style contribution heatmap grid showing the last ~16 weeks
 * of prayer data. Each day is a small colored rounded square whose color
 * reflects the number of Fardh prayers completed.
 */
class SalahWidgetProvider : HomeWidgetProvider() {

    companion object {
        // Color levels matching the Flutter app's calendar colors
        private val LEVEL_COLORS = intArrayOf(
            Color.parseColor("#2A2A2A"),   // 0 – no data (dark gray)
            Color.parseColor("#B71C1C"),   // 1 – 0 fardh (dark red)
            Color.parseColor("#E53935"),   // 2 – 1-2 fardh (red)
            Color.parseColor("#FDD835"),   // 3 – 3-4 fardh (yellow)
            Color.parseColor("#2E7D32"),   // 4 – all 5 fardh (dark green)
            Color.parseColor("#81C784"),   // 5 – all fardh + sunnah (light green)
        )

        private const val COLS = 16 // weeks (columns)
        private const val ROWS = 7  // days in a week (rows)
        private const val TOTAL_DAYS = COLS * ROWS // 112 days

        // Drawing constants
        private const val CELL_SIZE = 18f   // dp
        private const val CELL_GAP = 3f     // dp
        private const val CORNER_RADIUS = 4f // dp
        private const val LABEL_WIDTH = 28f  // dp – space for day labels on the left
        private const val HEADER_HEIGHT = 16f // dp – space for month labels on top
        private const val PADDING = 12f      // dp
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.salah_widget_layout)

            // Read heatmap JSON from SharedPreferences
            val heatmapJson = widgetData.getString("heatmap_data", null)
            val heatmap = parseHeatmap(heatmapJson)

            // Generate the heatmap bitmap
            val density = context.resources.displayMetrics.density
            val bitmap = renderHeatmap(heatmap, density)

            views.setImageViewBitmap(R.id.heatmap_image, bitmap)

            // Set click to open app
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 0, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    /**
     * Parse the heatmap JSON string into a map of date string -> color level.
     */
    private fun parseHeatmap(json: String?): Map<String, Int> {
        if (json.isNullOrEmpty()) return emptyMap()
        return try {
            val obj = JSONObject(json)
            val map = mutableMapOf<String, Int>()
            for (key in obj.keys()) {
                map[key] = obj.getInt(key)
            }
            map
        } catch (e: Exception) {
            emptyMap()
        }
    }

    /**
     * Render the heatmap grid as a Bitmap.
     *
     * Layout (like GitHub contribution graph rotated):
     *   - Columns = weeks (oldest on left, newest on right)
     *   - Rows = days of the week (Mon on top, Sun on bottom)
     *   - Left margin shows abbreviated day labels (M, W, F)
     *   - Top margin shows month labels
     */
    private fun renderHeatmap(heatmap: Map<String, Int>, density: Float): Bitmap {
        val cellPx = CELL_SIZE * density
        val gapPx = CELL_GAP * density
        val radiusPx = CORNER_RADIUS * density
        val labelWidthPx = LABEL_WIDTH * density
        val headerHeightPx = HEADER_HEIGHT * density
        val paddingPx = PADDING * density

        val gridWidth = COLS * (cellPx + gapPx) - gapPx
        val gridHeight = ROWS * (cellPx + gapPx) - gapPx
        val totalWidth = (paddingPx * 2 + labelWidthPx + gridWidth).toInt()
        val totalHeight = (paddingPx * 2 + headerHeightPx + gridHeight).toInt()

        val bitmap = Bitmap.createBitmap(totalWidth, totalHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Background
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1A1A2E")
            style = Paint.Style.FILL
        }
        canvas.drawRoundRect(
            RectF(0f, 0f, totalWidth.toFloat(), totalHeight.toFloat()),
            12f * density, 12f * density, bgPaint
        )

        // Build the date grid — we need to figure out which dates map to which cells
        val cal = Calendar.getInstance()
        val today = Calendar.getInstance()
        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)

        // Go back TOTAL_DAYS - 1 to find the start date
        cal.timeInMillis = today.timeInMillis
        cal.add(Calendar.DAY_OF_YEAR, -(TOTAL_DAYS - 1))

        // Adjust to start on a Monday
        val startDow = cal.get(Calendar.DAY_OF_WEEK)
        // Calendar.MONDAY = 2, Calendar.SUNDAY = 1
        val mondayOffset = if (startDow == Calendar.SUNDAY) -6
                           else Calendar.MONDAY - startDow
        cal.add(Calendar.DAY_OF_YEAR, mondayOffset)

        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val cellPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }

        // Draw month labels
        val monthPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#888888")
            textSize = 10f * density
            typeface = android.graphics.Typeface.DEFAULT
        }

        val dayLabelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#888888")
            textSize = 9f * density
            typeface = android.graphics.Typeface.DEFAULT
        }

        // Draw day-of-week labels (Mon, Wed, Fri)
        val dayLabels = arrayOf("M", "", "W", "", "F", "", "")
        for (row in 0 until ROWS) {
            val label = dayLabels[row]
            if (label.isNotEmpty()) {
                val y = paddingPx + headerHeightPx + row * (cellPx + gapPx) + cellPx * 0.75f
                canvas.drawText(label, paddingPx, y, dayLabelPaint)
            }
        }

        // Track months for header labels
        var lastMonth = -1

        // Draw cells
        val gridStartX = paddingPx + labelWidthPx
        val gridStartY = paddingPx + headerHeightPx
        val dateCal = cal.clone() as Calendar

        for (col in 0 until COLS) {
            for (row in 0 until ROWS) {
                val dateStr = dateFormat.format(dateCal.time)
                val level = heatmap[dateStr] ?: 0
                cellPaint.color = LEVEL_COLORS[level.coerceIn(0, 5)]

                // Check if this is a future date
                if (dateCal.after(today)) {
                    cellPaint.color = Color.parseColor("#1A1A2E") // same as background
                }

                val left = gridStartX + col * (cellPx + gapPx)
                val top = gridStartY + row * (cellPx + gapPx)
                val rect = RectF(left, top, left + cellPx, top + cellPx)
                canvas.drawRoundRect(rect, radiusPx, radiusPx, cellPaint)

                // Draw month label at top of each new month (only for row 0)
                if (row == 0) {
                    val currentMonth = dateCal.get(Calendar.MONTH)
                    if (currentMonth != lastMonth) {
                        lastMonth = currentMonth
                        val monthName = SimpleDateFormat("MMM", Locale.US).format(dateCal.time)
                        canvas.drawText(monthName, left, paddingPx + headerHeightPx - 3f * density, monthPaint)
                    }
                }

                dateCal.add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        return bitmap
    }
}
