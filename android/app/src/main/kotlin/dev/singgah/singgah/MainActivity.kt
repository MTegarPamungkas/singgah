package dev.singgah.singgah

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = GeofenceStore.CHANNEL

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncGeofences" -> {
                    val raw = call.argument<List<Any?>>("geofences") ?: emptyList()
                    val requests = raw.filterIsInstance<Map<*, *>>().map { row ->
                        row.entries.associate { entry ->
                            entry.key.toString() to entry.value
                        }
                    }
                    val ids = requests.mapNotNull { it["id"]?.toString() }
                    GeofenceStore.register(this, requests) { success ->
                        runOnUiThread {
                            if (success) {
                                result.success(
                                    mapOf(
                                        "registered" to ids,
                                        "failed" to emptyList<String>(),
                                    ),
                                )
                            } else {
                                result.success(
                                    mapOf(
                                        "registered" to emptyList<String>(),
                                        "failed" to ids,
                                    ),
                                )
                            }
                        }
                    }
                }

                "clearGeofences" -> {
                    GeofenceStore.clearAll(this) {
                        runOnUiThread { result.success(null) }
                    }
                }

                "drainTransitions" -> {
                    result.success(GeofenceStore.drainTransitions(this))
                }

                else -> result.notImplemented()
            }
        }
    }
}
