# FCM CRM payload sözleşmesi

İstemci yönlendirme: `lib/core/notifications/crm_push_navigation.dart`

`users/{uid}.fcmToken` alanı giriş sonrası güncellenir (`PushNotificationService`).

## Payload alanları

| `type` | Zorunlu alanlar | Açılış |
|--------|-----------------|--------|
| `team_chat` | `officeId`, `channelId` | Mesaj kanalı |
| `execution_reminder` | `customerId` | Müşteri detay |
| `task_due` | `customerId` (opsiyonel) | Müşteri detay veya görev sekmesi |
| `customer` | `customerId` | Müşteri detay |
| `listing` | `listingId` | İlan detay |

## Örnek (Cloud Functions / Admin SDK)

```json
{
  "notification": {
    "title": "Acil takip",
    "body": "Ayşe Yılmaz — bugün net adım"
  },
  "data": {
    "type": "execution_reminder",
    "customerId": "abc123"
  }
}
```

## Yerel bildirim köprüleri (FCM öncesi)

- İcra hatırlatıcıları: `ExecutionReminderNotificationBridge`
- Görev vadesi: `TaskDueNotificationBridge`
- Ekip mesajı: Firestore inbox + `TeamChatInboxListener`

Sunucu tarafı FCM gönderimi eklendiğinde aynı `type` değerleri kullanılmalıdır.
