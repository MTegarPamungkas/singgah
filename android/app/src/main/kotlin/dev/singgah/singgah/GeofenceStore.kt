package dev.singgah.singgah

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Native source of truth for registered geofences and pending transitions.
 *
 * The Dart side owns the plan; this object only persists the metadata the
 * broadcast receiver needs while the Flutter engine is asleep.
 */
object GeofenceStore {
    const val CHANNEL = "dev.singgah/geofencing"
    const val PREFS = "singgah_geofences"
    const val KEY_REQUESTS = "requests"
    const val KEY_TRANSITIONS = "transitions"
    const val KEY_LAST_FIRED = "last_fired_"
    const val ACTION_GEOFENCE = "dev.singgah.GEOFENCE"
    const val COOLDOWN_MS = 5 * 60 * 1000L
    const val MAX_TRANSITIONS = 200

    fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun hasLocationPermission(context: Context): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        )
        val coarse = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        return fine == PackageManager.PERMISSION_GRANTED ||
            coarse == PackageManager.PERMISSION_GRANTED
    }

    fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java).apply {
            action = ACTION_GEOFENCE
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }
        return PendingIntent.getBroadcast(context, 0, intent, flags)
    }

    fun loadRequests(context: Context): List<Map<String, Any?>> {
        val raw = prefs(context).getString(KEY_REQUESTS, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { index ->
                val row = array.optJSONObject(index) ?: return@mapNotNull null
                row.toMap()
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun JSONObject.toMap(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        keys().forEach { key -> map[key] = get(key) }
        return map
    }

    fun requestFor(context: Context, id: String): Map<String, Any?>? =
        loadRequests(context).firstOrNull { it["id"]?.toString() == id }

    fun saveRequests(context: Context, requests: List<Map<String, Any?>>) {
        val array = JSONArray()
        requests.forEach { row -> array.put(JSONObject(row)) }
        prefs(context).edit().putString(KEY_REQUESTS, array.toString()).apply()
    }

    fun clearRequests(context: Context) {
        prefs(context).edit().remove(KEY_REQUESTS).apply()
    }

    fun clearAll(context: Context, done: () -> Unit) {
        val client = LocationServices.getGeofencingClient(context)
        client.removeGeofences(pendingIntent(context))
            .addOnCompleteListener {
                clearRequests(context)
                done()
            }
    }

    private fun geofenceFor(row: Map<String, Any?>): Geofence? {
        val id = row["id"]?.toString() ?: return null
        val lat = (row["latitude"] as? Number)?.toDouble() ?: return null
        val lon = (row["longitude"] as? Number)?.toDouble() ?: return null
        val radius = (row["radius"] as? Number)?.toInt() ?: 150
        val transition = if (row["transition"]?.toString() == "leave") {
            Geofence.GEOFENCE_TRANSITION_EXIT
        } else {
            Geofence.GEOFENCE_TRANSITION_ENTER
        }
        return Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(lat, lon, radius.toFloat().coerceIn(100f, 2000f))
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(transition)
            .build()
    }

    fun register(
        context: Context,
        requests: List<Map<String, Any?>>,
        done: (Boolean) -> Unit,
    ) {
        if (!hasLocationPermission(context)) {
            done(false)
            return
        }
        val client = LocationServices.getGeofencingClient(context)
        val pending = pendingIntent(context)
        val geofences = requests.mapNotNull(::geofenceFor)
        if (geofences.isEmpty()) {
            // An empty plan (all Missions paused) must also remove stale
            // registrations, otherwise the OS keeps firing old reminders.
            client.removeGeofences(pending).addOnCompleteListener {
                clearRequests(context)
                done(requests.isEmpty())
            }
            return
        }
        client.removeGeofences(pending).addOnCompleteListener {
            val builder = GeofencingRequest.Builder()
                .setInitialTrigger(0)
                .addGeofences(geofences)
            try {
                client.addGeofences(builder.build(), pending)
                    .addOnCompleteListener { task ->
                        if (task.isSuccessful) {
                            saveRequests(context, requests)
                        }
                        done(task.isSuccessful)
                    }
            } catch (_: SecurityException) {
                done(false)
            } catch (_: Exception) {
                done(false)
            }
        }
    }

    fun reregister(context: Context) {
        val requests = loadRequests(context)
        if (requests.isNotEmpty()) register(context, requests) { }
    }

    fun queueTransition(context: Context, transition: Map<String, Any?>) {
        val array = try {
            JSONArray(prefs(context).getString(KEY_TRANSITIONS, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        array.put(JSONObject(transition))
        val trimmed = JSONArray()
        val start = maxOf(0, array.length() - MAX_TRANSITIONS)
        for (index in start until array.length()) {
            trimmed.put(array.get(index))
        }
        prefs(context).edit().putString(KEY_TRANSITIONS, trimmed.toString()).apply()
    }

    fun drainTransitions(context: Context): List<Map<String, Any?>> {
        val raw = prefs(context).getString(KEY_TRANSITIONS, null) ?: return emptyList()
        prefs(context).edit().remove(KEY_TRANSITIONS).apply()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { index ->
                array.optJSONObject(index)?.toMap()
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    /** Mirrors the Dart time-window / repeat-day rules in the receiver. */
    fun isScheduledNow(context: Context, row: Map<String, Any?>): Boolean {
        val calendar = Calendar.getInstance()
        val isoDay = ((calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1
        val days = row["repeat_days"] as? JSONArray ?: JSONArray()
        if (days.length() in 1..6) {
            var allowed = false
            for (index in 0 until days.length()) {
                if (days.optInt(index) == isoDay) {
                    allowed = true
                    break
                }
            }
            if (!allowed) return false
        }
        val start = (row["window_start_minutes"] as? Number)?.toInt() ?: 0
        val end = (row["window_end_minutes"] as? Number)?.toInt() ?: (24 * 60 - 1)
        val now = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        if (start == end) return true
        return if (start < end) now in start..end else now >= start || now <= end
    }

    fun canFire(context: Context, id: String, now: Long = System.currentTimeMillis()): Boolean {
        val last = prefs(context).getLong(KEY_LAST_FIRED + id, 0L)
        if (now - last < COOLDOWN_MS) return false
        prefs(context).edit().putLong(KEY_LAST_FIRED + id, now).apply()
        return true
    }
}
