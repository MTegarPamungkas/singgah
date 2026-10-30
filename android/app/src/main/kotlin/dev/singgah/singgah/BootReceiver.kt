package dev.singgah.singgah

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Android drops geofences on reboot; re-register the stored plan when possible. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            GeofenceStore.reregister(context.applicationContext)
        }
    }
}
