package com.axioncrm.mobile

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        consumeCaptureIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeCaptureIntent(intent)
    }

    private fun consumeCaptureIntent(intent: Intent?) {
        val number = intent?.getStringExtra("axion_capture_number")?.trim().orEmpty()
        if (number.isEmpty()) return
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val queue = JSONArray(
                prefs.getString("flutter.axion_native_capture_queue_v1", "[]") ?: "[]"
            )
            val normalized = number.replace(Regex("\\D"), "")
            val kept = JSONArray()
            val now = System.currentTimeMillis()
            for (i in 0 until queue.length()) {
                val obj = queue.optJSONObject(i) ?: continue
                if (obj.optString("normalized") == normalized) continue
                kept.put(obj)
            }
            kept.put(
                JSONObject()
                    .put("number", number)
                    .put("normalized", normalized)
                    .put("at", now)
            )
            var out = kept
            while (out.length() > 25) {
                val trimmed = JSONArray()
                for (i in 1 until out.length()) trimmed.put(out.opt(i))
                out = trimmed
            }
            prefs.edit().putString("flutter.axion_native_capture_queue_v1", out.toString()).apply()
        } catch (_: Throwable) {
            // Uygulama açılışını asla kırma.
        }
    }
}
