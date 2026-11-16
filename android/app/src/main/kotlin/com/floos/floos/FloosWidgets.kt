package com.floos.floos

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.content.SharedPreferences

/** Shared rendering for the two widget sizes; data is written by the Dart side. */
abstract class BaseFloosWidget(private val layout: Int) : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, layout)
            views.setTextViewText(R.id.label_spent, widgetData.getString("label_spent", "") ?: "")
            views.setTextViewText(R.id.spent_month, widgetData.getString("spent_month", "—") ?: "—")
            if (layout == R.layout.floos_widget_medium) {
                views.setTextViewText(R.id.label_income, widgetData.getString("label_income", "") ?: "")
                views.setTextViewText(R.id.income_month, widgetData.getString("income_month", "—") ?: "—")
                views.setTextViewText(R.id.label_balance, widgetData.getString("label_balance", "") ?: "")
                views.setTextViewText(R.id.balance, widgetData.getString("balance", "—") ?: "—")
                views.setTextViewText(R.id.top_budget, widgetData.getString("top_budget", "") ?: "")
            }
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("floos://add")).setPackage(context.packageName)
            val pending = PendingIntent.getActivity(
                context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.add_button, pending)
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

class FloosSmallWidgetProvider : BaseFloosWidget(R.layout.floos_widget_small)

class FloosMediumWidgetProvider : BaseFloosWidget(R.layout.floos_widget_medium)
