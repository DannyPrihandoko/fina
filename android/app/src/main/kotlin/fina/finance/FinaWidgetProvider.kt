package fina.finance

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.graphics.Color
import android.app.PendingIntent
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

class FinaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.fina_widget)
            
            // PendingIntent to open the app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            
            val streakCount = widgetData.getInt("streak_count", 0)
            val lastLoggedDate = widgetData.getLong("last_logged_date", 0L)
            
            val calendar = Calendar.getInstance()
            val now = calendar.timeInMillis
            val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
            
            val lastLoggedCalendar = Calendar.getInstance()
            lastLoggedCalendar.timeInMillis = lastLoggedDate
            
            val isLoggedToday = if (lastLoggedDate > 0) {
                calendar.get(Calendar.YEAR) == lastLoggedCalendar.get(Calendar.YEAR) &&
                calendar.get(Calendar.DAY_OF_YEAR) == lastLoggedCalendar.get(Calendar.DAY_OF_YEAR)
            } else {
                false
            }

            if (isLoggedToday) {
                // Happy state
                views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_happy)
                views.setImageViewResource(R.id.widget_image, R.drawable.sunflower_cheerful)
                views.setTextViewText(R.id.widget_title, "Hebat! Lanjutkan rutinitas mencatat kamu!")
                views.setTextColor(R.id.widget_title, Color.parseColor("#333333"))
                views.setTextViewText(R.id.widget_subtitle, "Streak kamu: $streakCount Hari!")
            } else {
                // Withered state
                views.setImageViewResource(R.id.widget_image, R.drawable.sunflower_withered)
                views.setTextViewText(R.id.widget_subtitle, "Streak kamu: $streakCount Hari!")
                
                when {
                    currentHour < 15 -> {
                        // Siang (Normal)
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_normal)
                        views.setTextViewText(R.id.widget_title, "Ayo catat pengeluaran kamu sekarang!")
                        views.setTextColor(R.id.widget_title, Color.parseColor("#333333"))
                    }
                    currentHour in 15..17 -> {
                        // Sore (Medium)
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_warning)
                        views.setTextViewText(R.id.widget_title, "Ingat untuk mencatat keuangan hari ini!")
                        views.setTextColor(R.id.widget_title, Color.parseColor("#E65100")) // Darker orange
                    }
                    else -> {
                        // Malam (Harsh)
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_alert)
                        views.setTextViewText(R.id.widget_title, "Segera catat pengeluaran sebelum terlambat!")
                        views.setTextColor(R.id.widget_title, Color.parseColor("#C62828")) // Darker red
                    }
                }
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
