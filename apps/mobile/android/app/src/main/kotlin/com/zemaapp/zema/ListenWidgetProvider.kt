package com.zemaapp.zema

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.widget.RemoteViews

class ListenWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, views(context))
    }

    companion object {
        private const val PREFS = "zema_listen_widget"

        fun setLast(context: Context, title: String?, artist: String?) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString("title", title)
                .putString("artist", artist)
                .apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ListenWidgetProvider::class.java),
            )
            if (ids.isNotEmpty()) manager.updateAppWidget(ids, views(context))
        }

        private fun views(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val title = prefs.getString("title", null)
            val artist = prefs.getString("artist", null)
            val views = RemoteViews(context.packageName, R.layout.listen_widget)
            if (title == null) {
                views.setTextViewText(R.id.listen_widget_title, context.getString(R.string.listen_widget_title))
                views.setTextViewText(R.id.listen_widget_detail, context.getString(R.string.listen_widget_none))
            } else {
                views.setTextViewText(R.id.listen_widget_title, title)
                views.setTextViewText(
                    R.id.listen_widget_detail,
                    if (artist.isNullOrBlank()) {
                        context.getString(R.string.listen_widget_last)
                    } else {
                        context.getString(R.string.listen_widget_last_by, artist)
                    },
                )
            }
            val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            views.setOnClickPendingIntent(
                R.id.listen_widget_mic,
                PendingIntent.getActivity(context, 1, QuickListenActivity.intent(context), flags),
            )
            views.setOnClickPendingIntent(
                R.id.listen_widget_text,
                PendingIntent.getActivity(context, 2, LaunchChannel.historyIntent(context), flags),
            )
            return views
        }
    }
}
