package com.habitos.cleanstep.core.notification

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.habitos.cleanstep.presentation.MainActivity

class NotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_ID_MID_AFTERNOON = "cleanstep_channel_mid_afternoon"
        const val CHANNEL_ID_NIGHT_ROUTINE = "cleanstep_channel_night_routine"

        const val NOTIFICATION_ID_MID_AFTERNOON = 1001
        const val NOTIFICATION_ID_NIGHT_ROUTINE = 1002

        const val EXTRA_DESTINATION = "extra_notification_destination"
        const val DESTINATION_CRAVINGS = "destination_cravings"
        const val DESTINATION_NIGHT_ROUTINE = "destination_night_routine"

        const val DEFAULT_MID_AFTERNOON_TITLE = "¿Sed o antojo?"
        const val DEFAULT_MID_AFTERNOON_BODY =
            "¿Sed o antojo? Tómate un vaso de agua o prepara tu agua mineral con limón. ¡Tu racha limpia continúa!"

        const val DEFAULT_NIGHT_ROUTINE_TITLE = "Rutina Nocturna de Movilidad"
        const val DEFAULT_NIGHT_ROUTINE_BODY =
            "Son las 10:00 PM. Tu rutina de 15 min de descompresión y movilidad te espera antes de dormir."

        /**
         * Static utility to create channels during Application startup.
         */
        fun createNotificationChannels(context: Context) {
            NotificationHelper(context).createChannels()
        }
    }

    /**
     * Initializes notification channels for Android 8.0+ (Oreo / API 26+).
     * Includes a nocturnal-friendly, low-noise channel for the 10:00 PM reminder.
     */
    fun createChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return

            // 1. Canal de media tarde (4:30 PM) - Alerta de antojos e hidratación
            val afternoonChannel = NotificationChannel(
                CHANNEL_ID_MID_AFTERNOON,
                "CleanStep - Pausa de la Tarde (Antojos y Agua)",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Recordatorio a las 4:30 PM (caída de dopamina) para sustitución de chatarra e hidratación."
                enableLights(true)
                lightColor = Color.parseColor("#10B981") // Emerald Green
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 150, 250)
                setShowBadge(true)
            }

            // 2. Canal nocturno (10:00 PM) - Canal de bajo ruido / amigable con el descanso nocturno
            val nightChannel = NotificationChannel(
                CHANNEL_ID_NIGHT_ROUTINE,
                "CleanStep - Rutina Nocturna (10:00 PM)",
                NotificationManager.IMPORTANCE_LOW // Low-noise, no intrusive popups or loud alarms
            ).apply {
                description = "Recordatorio suave y silencioso para relajación y movilidad antes de dormir."
                enableLights(true)
                lightColor = Color.parseColor("#34D399") // Mint green suave
                enableVibration(false) // Sin vibración intrusiva a altas horas de la noche
                setSound(null, null) // Silencioso para respetar el entorno familiar
                setShowBadge(true)
            }

            notificationManager.createNotificationChannels(listOf(afternoonChannel, nightChannel))
        }
    }

    /**
     * Shows the 4:30 PM Mid-Afternoon reminder notification.
     */
    fun showMidAfternoonNotification(
        title: String = DEFAULT_MID_AFTERNOON_TITLE,
        body: String = DEFAULT_MID_AFTERNOON_BODY
    ) {
        if (!hasNotificationPermission()) return

        val pendingIntent = createActivityPendingIntent(
            requestCode = NOTIFICATION_ID_MID_AFTERNOON,
            destination = DESTINATION_CRAVINGS
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID_MID_AFTERNOON)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setColor(0xFF10B981.toInt())
            .setContentIntent(pendingIntent)
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID_MID_AFTERNOON, notification)
    }

    /**
     * Shows the 10:00 PM Night Routine reminder notification using the nocturnal low-noise channel.
     */
    fun showNightRoutineNotification(
        title: String = DEFAULT_NIGHT_ROUTINE_TITLE,
        body: String = DEFAULT_NIGHT_ROUTINE_BODY
    ) {
        if (!hasNotificationPermission()) return

        val pendingIntent = createActivityPendingIntent(
            requestCode = NOTIFICATION_ID_NIGHT_ROUTINE,
            destination = DESTINATION_NIGHT_ROUTINE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID_NIGHT_ROUTINE)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_LOW) // Nocturnal-friendly
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setColor(0xFF0F172A.toInt()) // Deep nocturnal surface color
            .setSilent(true) // Respeta el ambiente de descanso
            .setContentIntent(pendingIntent)
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID_NIGHT_ROUTINE, notification)
    }

    /**
     * Creates a PendingIntent targeting MainActivity with an optional extra destination flag.
     */
    private fun createActivityPendingIntent(requestCode: Int, destination: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_DESTINATION, destination)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    /**
     * Verifies if POST_NOTIFICATIONS permission is granted on Android 13+ and notifications are enabled.
     */
    fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permissionGranted = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (!permissionGranted) return false
        }
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }
}
