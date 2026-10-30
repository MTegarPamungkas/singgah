package dev.singgah.singgah

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.location.GeofencingEvent
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) return
        val transitionType = event.geofenceTransition
        if (transitionType != com.google.android.gms.location.Geofence.GEOFENCE_TRANSITION_ENTER &&
            transitionType != com.google.android.gms.location.Geofence.GEOFENCE_TRANSITION_EXIT
        ) {
            return
        }
        val triggering = event.triggeringGeofences ?: return
        for (geofence in triggering) {
            handle(context, geofence.requestId)
        }
    }

    private fun handle(context: Context, requestId: String) {
        val row = GeofenceStore.requestFor(context, requestId) ?: return
        if (!GeofenceStore.isScheduledNow(context, row)) return
        if (!GeofenceStore.canFire(context, requestId)) return

        val kind = row["kind"]?.toString() ?: "mission"
        val title = row["title"]?.toString() ?: "Singgah"
        val body = row["body"]?.toString() ?: ""
        val transition = row["transition"]?.toString() ?: "arrive"
        GeofenceStore.queueTransition(
            context,
            mapOf(
                "request_id" to requestId,
                "kind" to kind,
                "transition" to transition,
                "occurred_at" to isoNow(),
                "title" to title,
                "body" to body,
                "place_id" to row["place_id"],
                "place_name" to row["place_name"],
                "mission_id" to row["mission_id"],
                "titipan_id" to row["titipan_id"],
            ),
        )
        notify(context, requestId, kind, title, body)
    }

    private fun isoNow(): String {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return format.format(Date())
    }

    private fun notify(
        context: Context,
        requestId: String,
        kind: String,
        title: String,
        body: String,
    ) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = if (kind == "titipan") "singgah_titipan" else "singgah_reminders"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                if (kind == "titipan") "Titipan" else "Singgah reminders",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Singgah place reminders"
            }
            manager.createNotificationChannel(channel)
        }
        val launch = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("singgah_request_id", requestId)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val contentIntent = PendingIntent.getActivity(
            context,
            requestId.hashCode(),
            launch,
            flags,
        )
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .build()
        try {
            NotificationManagerCompat.from(context)
                .notify(requestId.hashCode() and 0x7fffffff, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS was revoked; the transition is still queued so
            // history and in-app badges stay correct.
        }
    }
}
