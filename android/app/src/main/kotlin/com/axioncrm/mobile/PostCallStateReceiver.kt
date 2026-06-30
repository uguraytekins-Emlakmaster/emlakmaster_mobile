package com.axioncrm.mobile

import android.app.ActivityManager
import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.CallLog
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import androidx.core.app.RemoteInput
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * Android tarafında çağrı bitişini uygulamadan bağımsız yakalar.
 *
 * Notlar:
 * - Yalnızca çağrı state geçişini dinler (RINGING/OFFHOOK -> IDLE).
 * - Aday numarayı Flutter SharedPreferences alanına yazar.
 * - Uygulama foreground'da değilse heads-up bildirim gösterir.
 */
class PostCallStateReceiver : BroadcastReceiver() {
    private val remoteInputResultKey = "axion_capture_name_input"

    override fun onReceive(context: Context, intent: Intent) {
        try {
            if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
            val incoming = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            if (!incoming.isNullOrBlank()) {
                lastNumber = incoming.trim()
            }

            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING,
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    lastState = state
                }

                TelephonyManager.EXTRA_STATE_IDLE -> {
                    val wasInCall = lastState == TelephonyManager.EXTRA_STATE_RINGING ||
                        lastState == TelephonyManager.EXTRA_STATE_OFFHOOK
                    val number = if (!incoming.isNullOrBlank()) {
                        incoming.trim()
                    } else {
                        lastNumber ?: resolveRecentCallNumber(context)
                    }
                    lastState = state
                    lastNumber = null
                    if (!wasInCall || number.isNullOrBlank()) return

                    val normalized = number.replace(Regex("\\D"), "")
                    if (normalized.length < 7) return
                    val now = System.currentTimeMillis()
                    val duplicate = lastCapturedNormalized == normalized &&
                        now - lastCapturedAtMs < 12_000
                    if (duplicate) return
                    lastCapturedNormalized = normalized
                    lastCapturedAtMs = now

                    persistCandidate(context, number)

                    // Foreground'da Flutter popup akışı zaten devrede; çift bildirim verme.
                    if (!isAppInForeground(context)) {
                        showCaptureNotification(context, number)
                    }
                }
            }
        } catch (_: Throwable) {
            // BroadcastReceiver hatası uygulamayı asla çökertmemeli.
        }
    }

    private fun resolveRecentCallNumber(context: Context): String? {
        if (!hasReadCallLogPermission(context)) return null
        return try {
            val projection = arrayOf(
                CallLog.Calls.NUMBER,
                CallLog.Calls.DATE,
                CallLog.Calls.TYPE,
            )
            context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                null,
                null,
                "${CallLog.Calls.DATE} DESC LIMIT 1",
            )?.use { cursor ->
                if (!cursor.moveToFirst()) return null
                val number = cursor.getString(0)?.trim().orEmpty()
                val dateMs = cursor.getLong(1)
                val type = cursor.getInt(2)
                if (number.isBlank()) return null
                val ageMs = System.currentTimeMillis() - dateMs
                val recent = ageMs in 0..120_000
                val validType = type == CallLog.Calls.INCOMING_TYPE ||
                    type == CallLog.Calls.OUTGOING_TYPE ||
                    type == CallLog.Calls.MISSED_TYPE ||
                    type == CallLog.Calls.REJECTED_TYPE ||
                    type == CallLog.Calls.BLOCKED_TYPE
                if (!recent || !validType) return null
                number
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun hasReadCallLogPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALL_LOG,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun persistCandidate(context: Context, rawNumber: String) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val queue = JSONArray(
            prefs.getString("flutter.axion_native_capture_queue_v1", "[]") ?: "[]"
        )
        val normalized = rawNumber.replace(Regex("\\D"), "")
        val kept = JSONArray()
        val now = System.currentTimeMillis()

        // Aynı numara için eski adayı düşür; kuyruk en fazla 25 kalsın.
        for (i in 0 until queue.length()) {
            val obj = queue.optJSONObject(i) ?: continue
            val n = obj.optString("normalized")
            if (n == normalized) continue
            kept.put(obj)
        }
        kept.put(
            JSONObject()
                .put("number", rawNumber)
                .put("normalized", normalized)
                .put("at", now)
        )
        var out = kept
        while (out.length() > 25) {
            // en eskiyi at
            val trimmed = JSONArray()
            for (i in 1 until out.length()) {
                trimmed.put(out.opt(i))
            }
            out = trimmed
        }
        prefs.edit().putString("flutter.axion_native_capture_queue_v1", out.toString()).apply()
    }

    private fun showCaptureNotification(context: Context, rawNumber: String) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return

        createChannel(context)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("axion_capture_number", rawNumber)
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            rawNumber.hashCode(),
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val quickSaveIntent = Intent(context, PostCallQuickSaveReceiver::class.java).apply {
            putExtra("axion_capture_number", rawNumber)
        }
        val quickSavePendingIntent = PendingIntent.getBroadcast(
            context,
            rawNumber.hashCode() + 7000,
            quickSaveIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_IMMUTABLE
                },
        )
        val remoteInput = RemoteInput.Builder(remoteInputResultKey)
            .setLabel("Müşteri adı")
            .build()
        val quickSaveAction = NotificationCompat.Action.Builder(
            0,
            "İsim yaz & kaydet",
            quickSavePendingIntent,
        ).addRemoteInput(remoteInput).build()

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Kayıtsız numara olabilir")
            .setContentText("$rawNumber · Hemen kaydetmek için dokunun")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true)
            .setContentIntent(openPendingIntent)
            .addAction(quickSaveAction)

        try {
            manager.notify(rawNumber.hashCode(), builder.build())
        } catch (_: Throwable) {
            // Bildirim başarısızsa akış queue ile devam eder.
        }
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = nm.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return

        val sound = Uri.parse("android.resource://${context.packageName}/${R.raw.axion_capture_chime}")
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val ch = NotificationChannel(
            CHANNEL_ID,
            "Kayıtsız numara uyarıları",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Çağrı sonrası hızlı müşteri kaydı önerileri"
            setSound(sound, attrs)
            enableVibration(true)
        }
        nm.createNotificationChannel(ch)
    }

    private fun isAppInForeground(context: Context): Boolean {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return false
        val packageName = context.packageName
        val processes = am.runningAppProcesses ?: return false
        return processes.any {
            it.processName == packageName &&
                it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        }
    }

    companion object {
        private const val CHANNEL_ID = "axion_capture_native_v1"
        @Volatile private var lastState: String? = null
        @Volatile private var lastNumber: String? = null
        @Volatile private var lastCapturedNormalized: String? = null
        @Volatile private var lastCapturedAtMs: Long = 0L
    }
}

