package com.axioncrm.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput
import org.json.JSONArray
import org.json.JSONObject

/**
 * Native bildirim aksiyonu: uygulama açılmadan "isim yaz & kaydet".
 *
 * CRM yazımı Flutter açılınca yapılır; burada yalnızca AxionPendingCaptureStore'un
 * okuduğu kuyruğa kayıt düşülür.
 */
class PostCallQuickSaveReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val number = intent.getStringExtra("axion_capture_number")?.trim().orEmpty()
            if (number.isEmpty()) return

            val input = RemoteInput.getResultsFromIntent(intent)
            val name = input?.getCharSequence("axion_capture_name_input")?.toString()?.trim()
                .takeUnless { it.isNullOrEmpty() } ?: number

            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val list = JSONArray(
                prefs.getString("flutter.axion_pending_capture_saves_v1", "[]") ?: "[]"
            )
            // Aynı telefonu güncelle (en yeni isim kazansın).
            val out = JSONArray()
            for (i in 0 until list.length()) {
                val obj = list.optJSONObject(i) ?: continue
                val phone = obj.optString("phone", "")
                if (phone == number) continue
                out.put(obj)
            }
            out.put(
                JSONObject()
                    .put("name", name)
                    .put("phone", number)
                    .put("at", System.currentTimeMillis())
            )
            while (out.length() > 25) {
                val trimmed = JSONArray()
                for (i in 1 until out.length()) trimmed.put(out.opt(i))
                prefs.edit().putString("flutter.axion_pending_capture_saves_v1", trimmed.toString()).apply()
                return
            }
            prefs.edit().putString("flutter.axion_pending_capture_saves_v1", out.toString()).apply()
        } catch (_: Throwable) {
            // Aksiyon alındığında receiver hatası uygulamayı çökertmemeli.
        }
    }
}

