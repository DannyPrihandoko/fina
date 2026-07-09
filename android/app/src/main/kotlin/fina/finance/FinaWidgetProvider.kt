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
            val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
            
            // Normalize calendar to date-only (midnight) for day comparison
            val todayMidnight = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val lastLoggedCalendar = Calendar.getInstance().apply {
                timeInMillis = lastLoggedDate
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            // Compute difference in days between today and last logged date
            val diffMillis = todayMidnight.timeInMillis - lastLoggedCalendar.timeInMillis
            val diffDays = (diffMillis / (1000 * 60 * 60 * 24)).toInt()

            val isLoggedToday = lastLoggedDate > 0 && diffDays == 0

            // If more than 1 day has passed since last activity, streak is broken.
            // Display 0 so the widget reflects the real state even before the app is opened.
            val displayedStreak = if (lastLoggedDate == 0L || diffDays > 1) 0 else streakCount

            if (isLoggedToday) {
                // Happy state — activity recorded today
                views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_happy)
                views.setImageViewResource(R.id.widget_image, R.drawable.sunflower_cheerful)
                views.setTextViewText(R.id.widget_title, "Streak: $displayedStreak Hari")
                views.setTextColor(R.id.widget_title, Color.parseColor("#333333"))
            } else {
                // Withered state — activity not recorded today (or streak broken)
                views.setImageViewResource(R.id.widget_image, R.drawable.sunflower_withered)
                
                when {
                    currentHour < 15 -> {
                        // Siang (Normal)
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_normal)
                        views.setTextViewText(R.id.widget_title, "Streak: $displayedStreak Hari")
                        views.setTextColor(R.id.widget_title, Color.parseColor("#333333"))
                    }
                    currentHour in 15..17 -> {
                        // Sore (Medium)
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_warning)
                        views.setTextViewText(R.id.widget_title, "Streak: $displayedStreak Hari")
                        views.setTextColor(R.id.widget_title, Color.parseColor("#E65100")) // Darker orange
                    }
                    else -> {
                        // Malam (Harsh)
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.widget_bg_alert)
                        views.setTextViewText(R.id.widget_title, "Streak: $displayedStreak Hari")
                        views.setTextColor(R.id.widget_title, Color.parseColor("#C62828")) // Darker red
                    }
                }
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
