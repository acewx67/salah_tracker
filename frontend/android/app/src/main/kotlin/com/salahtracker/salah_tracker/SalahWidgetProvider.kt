package com.salahtracker.salah_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * Android AppWidgetProvider for the Salah Tracker home screen widget.
 * Displays a monthly calendar rendered in Flutter.
 */
class SalahWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.salah_widget_layout)

            // Read the image path saved by Flutter
            val imagePath = widgetData.getString("calendar_image", null)
            
            if (imagePath != null && File(imagePath).exists()) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                views.setImageViewBitmap(R.id.heatmap_image, bitmap)
            } else {
                // Optional: set a placeholder or clear the image if path missing
                views.setImageViewResource(R.id.heatmap_image, 0)
            }

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
}
