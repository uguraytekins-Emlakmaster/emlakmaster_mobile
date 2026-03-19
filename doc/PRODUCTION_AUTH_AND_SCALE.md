# Üretim: kimlik, ölçek (yüzlerce kullanıcı), güvenlik

## Uygulama tarafı (yapıldı)

| Özellik | Açıklama |
|---------|----------|
| **Oturum tazeleme** | Uygulama öne gelince `reload()` + `getIdToken(true)` (3 dk throttle) — uzun arka plandan sonra Firestore/JWT uyumu. |
| **Giriş hız sınırı** | 5 dk içinde 12 başarısız denemeden sonra kısa bekleme mesajı (Firebase sunucu limitine ek). |
| **Google + e-posta çıkış** | Çıkışta Google oturumu da kapanır; paylaşımlı cihazda hesap karışması azalır. |
| **Firestore offline** | Sınırsız önbellek + persistence — çok kullanıcıda ağ dalgalanmasında veri kaybı azalır. |

## Firestore kuralları (kritik)

- **`users/{uid}` güncelleme:** Normal kullanıcı **role, isActive, teamId, managerId, createdAt** değiştiremez; yalnızca yönetici (`isManager`). Profil alanları (`name`, `email`, `avatarUrl`, `fcmToken` vb.) güncellenebilir. **Yetki yükseltmesi istemci ile engellenir.**
- Dağıtım: `./scripts/deploy_firestore_rules.sh` veya `firebase deploy --only firestore:rules`

## Firebase Console (sizin kontrol listeniz)

1. **Authentication** → Google + E-posta açık; gereksiz sağlayıcıları kapatın.  
2. **Şifre politikası** → mümkünse minimum uzunluk / zayıf şifre listesi.  
3. **E-posta doğrulama** → hassas işlemler için (isteğe bağlı) `emailVerified` zorunluluğu düşünün.  
4. **App Check** → bot/istismara karşı (ileri seviye).  
5. **Blaze** → çok yüksek trafikte kota ve faturalama.  
6. **İlk süper admin** → mümkünse yalnızca güvenilir ilk kayıt veya Console’dan manuel `users/{uid}` ile `super_admin` atayın.

## Ölçek notları

- Firestore dinleyicileri rol başına sınırlı tutun; liste sorgularında `limit` kullanın.  
- `users` dokümanı başına FCM token tek alanda; çok cihaz için ileride `fcmTokens` array + Cloud Function temizliği düşünülebilir.  
- Analytics/Crashlytics ile giriş hatalarını izleyin.
