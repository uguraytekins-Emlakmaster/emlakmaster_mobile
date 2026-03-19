# Firestore Indexes (EmlakMaster)

Aşağıdaki index'ler gerekebilir. Firebase Console → Firestore → Indexes üzerinden oluşturabilir veya `firebase deploy --only firestore:indexes` ile deploy edebilirsiniz.

## 1. War Room – Lead Pulse (son lead'ler)

**Koleksiyon:** `customers`  
**Alanlar:** `updatedAt` (Descending)  
**Sorgu:** `orderBy('updatedAt', descending: true).limit(25)`

- Index yoksa `recentLeadsStream()` try/catch ile boş döner; uygulama çökmez.
- Index eklemek için: Firestore → Indexes → Composite → Collection ID: `customers`, Field: `updatedAt`, Order: Descending.

## 2. VIP Yatırımcı bildirimi

**Koleksiyon:** `customers`  
**Alanlar:** `is_vip_investor` (Ascending), `investment_alert_enabled` (Ascending)  
**Sorgu:** `where('is_vip_investor', isEqualTo: true).where('investment_alert_enabled', isEqualTo: true).limit(50)`

- Yatırım Radarı VIP bildirimi için gerekli.

## 3. Property Vault (Mülk Sağlık Karnesi)

**Koleksiyon:** `listings/{listingId}/property_vault`  
**Alanlar:** `occurredAt` (Descending)  
**Sorgu:** `orderBy('occurredAt', descending: true).limit(50)`

- İlan bazlı timeline için.

## 4. Dashboard KPI – bugünkü çağrı ve açık görev

**calls:** `where('createdAt', isGreaterThanOrEqualTo: bugün_00:00)` — `todayCallsCountStream()`.  
**tasks:** `where('done', isEqualTo: false)` — `openTasksCountStream()`.  

- Tek alan sorguları; Firestore varsayılan single-field index ile çalışır, ek composite gerekmez.

## firestore.indexes.json örneği

```json
{
  "indexes": [
    {
      "collectionGroup": "customers",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "customers",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_vip_investor", "order": "ASCENDING" },
        { "fieldPath": "investment_alert_enabled", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "property_vault",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "occurredAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Proje kökünde `firestore.indexes.json` oluşturup yukarıdaki gibi tanımlayabilirsiniz.
