package com.practicechords.practice_chords

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 2x2 home-screen widget. When more than 6 hours have passed since the last
 * recorded practice (or the user has never practised), it shows an animated
 * red "Time to practice!" reminder. Otherwise it shows a calm "Keep it up!"
 * state with how long ago the last session was.
 */
class PracticeWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val KEY_LAST_PRACTICE = "last_practice"
        private const val SIX_HOURS_MS = 6L * 60L * 60L * 1000L
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val now = System.currentTimeMillis()
        val last = widgetData.getString(KEY_LAST_PRACTICE, null)?.toLongOrNull()
        val overdue = last == null || (now - last) >= SIX_HOURS_MS

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.practice_widget)

            if (overdue) {
                views.setViewVisibility(R.id.reminder_state, View.VISIBLE)
                views.setViewVisibility(R.id.ok_state, View.GONE)
            } else {
                views.setViewVisibility(R.id.reminder_state, View.GONE)
                views.setViewVisibility(R.id.ok_state, View.VISIBLE)
                views.setTextViewText(R.id.ok_subtitle, lastPractisedLabel(now - last!!))
            }

            // Tapping the widget opens the app.
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pending = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun lastPractisedLabel(elapsedMs: Long): String {
        val minutes = elapsedMs / 60000L
        return when {
            minutes < 1L -> "Practised just now"
            minutes < 60L -> "Practised ${minutes}m ago"
            else -> "Practised ${minutes / 60L}h ago"
        }
    }
}
