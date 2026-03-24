# Firestore: `external_connections` & `integration_listings`

Üretim kuralları `firestore.rules` (repo kökü) ile tek kaynak; aşağısı özet.

## `external_connections`

- **Okuma:** Giriş yapmış kullanıcı, kendi `userId == request.auth.uid` olan kayıtları veya yönetici (`isManager()`).
- **Yazma:** İstemci kapalı — yalnızca Admin SDK (Cloud Functions / backend).

```text
match /external_connections/{connId} {
  allow read: if isSignedIn()
    && (resource.data.userId == request.auth.uid || isManager());
  allow create, update, delete: if false;
}
```

Index: `userId` eşitlik sorgusu (varsayılan tek alan indeksi).

## `integration_listings` (Benim İlanlarım)

- **Okuma:** `ownerUserId == request.auth.uid` veya yönetici.
- **Yazma:** İstemci kapalı — yalnızca Admin SDK. Sunucu **mutlaka** `ownerUserId` (Firebase Auth uid) yazar.

```text
match /integration_listings/{listingId} {
  allow read: if isSignedIn()
    && (resource.data.ownerUserId == request.auth.uid || isManager());
  allow create, update, delete: if false;
}
```

Index: `ownerUserId` eşitlik sorgusu (varsayılan tek alan indeksi).

Detaylı şema ve Node örneği: `doc/INTEGRATION_LISTINGS_SERVER_CONTRACT.md`.

## Deploy

```bash
firebase deploy --only firestore:rules
```

Proje: `.firebaserc` → `emlak-master` (varsayılan).
