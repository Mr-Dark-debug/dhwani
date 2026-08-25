package com.prashant.dhwani

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.view.KeyEvent
import android.widget.RemoteViews

class RetroTunerWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "dhwani_widget_prefs"

        const val ACTION_PLAY_PAUSE = "com.prashant.dhwani.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.prashant.dhwani.ACTION_NEXT"
        const val ACTION_PREVIOUS = "com.prashant.dhwani.ACTION_PREVIOUS"
        const val ACTION_REWIND = "com.prashant.dhwani.ACTION_REWIND"
        const val ACTION_FAST_FORWARD = "com.prashant.dhwani.ACTION_FAST_FORWARD"
        const val ACTION_TUNE_FAV = "com.prashant.dhwani.ACTION_TUNE_FAV"
        const val EXTRA_STATION_ID = "extra_station_id"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, RetroTunerWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                val intent = Intent(context, RetroTunerWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val stationName = prefs.getString("station_name", "Dhwani Radio") ?: "Dhwani Radio"
        val frequency = prefs.getString("station_frequency", "97.2") ?: "97.2"
        val freqUnit = prefs.getString("station_freq_unit", " MHz") ?: " MHz"
        val band = prefs.getString("station_band", "FM") ?: "FM"
        val stationIndex = prefs.getString("station_index", "1") ?: "1"
        val country = prefs.getString("station_country", "Global") ?: "Global"
        val icyTitle = prefs.getString("icy_title", "") ?: ""
        val isPlaying = prefs.getBoolean("is_playing", false)

        val dial1 = prefs.getString("dial_1", "96") ?: "96"
        val dial2 = prefs.getString("dial_2", "97") ?: "97"
        val dial3 = prefs.getString("dial_3", "98") ?: "98"
        val dial4 = prefs.getString("dial_4", "99") ?: "99"

        val fav1Name = prefs.getString("fav1_name", "Station 1") ?: "Station 1"
        val fav1Freq = prefs.getString("fav1_freq", "95.7") ?: "95.7"
        val fav1Id = prefs.getString("fav1_id", "") ?: ""

        val fav2Name = prefs.getString("fav2_name", "Station 2") ?: "Station 2"
        val fav2Freq = prefs.getString("fav2_freq", "107.5") ?: "107.5"
        val fav2Id = prefs.getString("fav2_id", "") ?: ""

        val displayTitle = if (icyTitle.isNotBlank()) icyTitle else stationName

        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.retro_tuner_widget)

            // Update text fields
            views.setTextViewText(R.id.tv_widget_band, band)
            views.setTextViewText(R.id.tv_widget_station_num, stationIndex)
            views.setTextViewText(R.id.tv_widget_frequency, frequency)
            views.setTextViewText(R.id.tv_widget_freq_unit, freqUnit)
            views.setTextViewText(R.id.tv_widget_title, displayTitle)
            views.setTextViewText(R.id.tv_widget_area, country)

            views.setTextViewText(R.id.tv_dial_1, dial1)
            views.setTextViewText(R.id.tv_dial_2, dial2)
            views.setTextViewText(R.id.tv_dial_3, dial3)
            views.setTextViewText(R.id.tv_dial_4, dial4)

            views.setTextViewText(R.id.tv_widget_fav1_name, fav1Name)
            views.setTextViewText(R.id.tv_widget_fav1_freq, fav1Freq)
            views.setTextViewText(R.id.tv_widget_fav2_name, fav2Name)
            views.setTextViewText(R.id.tv_widget_fav2_freq, fav2Freq)

            // Play / Pause Icon
            views.setImageViewResource(
                R.id.btn_widget_play_pause,
                if (isPlaying) R.drawable.ic_widget_pause else R.drawable.ic_widget_play
            )

            // Open app on widget background tap
            val appIntent = Intent(context, MainActivity::class.java).apply {
                setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("route", "/retro")
            }
            val appPendingIntent = PendingIntent.getActivity(
                context,
                0,
                appIntent,
                pendingFlags
            )
            views.setOnClickPendingIntent(R.id.widget_root, appPendingIntent)

            // Play / Pause click
            val playPauseIntent = Intent(context, RetroTunerWidgetProvider::class.java).apply {
                action = ACTION_PLAY_PAUSE
            }
            views.setOnClickPendingIntent(
                R.id.btn_widget_play_pause,
                PendingIntent.getBroadcast(context, 101, playPauseIntent, pendingFlags)
            )

            // Skip Next click
            val nextIntent = Intent(context, RetroTunerWidgetProvider::class.java).apply {
                action = ACTION_NEXT
            }
            views.setOnClickPendingIntent(
                R.id.btn_widget_next,
                PendingIntent.getBroadcast(context, 102, nextIntent, pendingFlags)
            )

            // Skip Previous click
            val prevIntent = Intent(context, RetroTunerWidgetProvider::class.java).apply {
                action = ACTION_PREVIOUS
            }
            views.setOnClickPendingIntent(
                R.id.btn_widget_prev,
                PendingIntent.getBroadcast(context, 103, prevIntent, pendingFlags)
            )

            // Rewind click
            val rewindIntent = Intent(context, RetroTunerWidgetProvider::class.java).apply {
                action = ACTION_REWIND
            }
            views.setOnClickPendingIntent(
                R.id.btn_widget_rewind,
                PendingIntent.getBroadcast(context, 104, rewindIntent, pendingFlags)
            )

            // Fast forward click
            val ffIntent = Intent(context, RetroTunerWidgetProvider::class.java).apply {
                action = ACTION_FAST_FORWARD
            }
            views.setOnClickPendingIntent(
                R.id.btn_widget_fast_forward,
                PendingIntent.getBroadcast(context, 105, ffIntent, pendingFlags)
            )

            // Fav 1 tap
            if (fav1Id.isNotBlank()) {
                val fav1Intent = Intent(context, RetroTunerWidgetProvider::class.java).apply {
                    action = ACTION_TUNE_FAV
                    putExtra(EXTRA_STATION_ID, fav1Id)
                }
                views.setOnClickPendingIntent(
                    R.id.btn_widget_fav1,
                    PendingIntent.getBroadcast(context, 106, fav1Intent, pendingFlags)
                )
            }

            // Fav 2 tap
            if (fav2Id.isNotBlank()) {
                val fav2Intent = Intent(context, RetroTunerWidgetProvider::class.java).apply {
                    action = ACTION_TUNE_FAV
                    putExtra(EXTRA_STATION_ID, fav2Id)
                }
                views.setOnClickPendingIntent(
                    R.id.btn_widget_fav2,
                    PendingIntent.getBroadcast(context, 107, fav2Intent, pendingFlags)
                )
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return

        when (action) {
            ACTION_PLAY_PAUSE -> {
                sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            }
            ACTION_NEXT -> {
                sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_NEXT)
            }
            ACTION_PREVIOUS -> {
                sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            }
            ACTION_REWIND -> {
                sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            }
            ACTION_FAST_FORWARD -> {
                sendMediaKeyEvent(context, KeyEvent.KEYCODE_MEDIA_NEXT)
            }
            ACTION_TUNE_FAV -> {
                val stationId = intent.getStringExtra(EXTRA_STATION_ID)
                if (!stationId.isNullOrBlank()) {
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        putExtra("tune_station_id", stationId)
                    }
                    context.startActivity(launchIntent)
                }
            }
        }
    }

    private fun sendMediaKeyEvent(context: Context, keyCode: Int) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager != null) {
                audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
                audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
            }
        } catch (e: Exception) {
            // Fallback: launch app intent
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            context.startActivity(launchIntent)
        }
    }
}
