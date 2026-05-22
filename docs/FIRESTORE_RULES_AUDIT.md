# Firestore rules audit (ofis sınırı)

Son güncelleme: 2026-05-21

## Özet

`customers` koleksiyonu zaten ofis sınırı (`canAccessCustomerOfficeWide`) kullanıyordu. Aynı model **calls**, **deals**, **call_summaries**, **notes**, **tasks**, **visits**, **offers** ve **pipeline_items** için genişletildi: blanket `isManager()` kaldırıldı; yönetici yalnızca **aynı ofisteki** danışman verisine erişir.

## Yardımcılar

| Fonksiyon | Amaç |
|-----------|------|
| `canAccessAgentOwnedDoc(agentId)` | Okuma / silme |
| `canCreateAgentOwnedDoc(agentId)` | Oluşturma |
| `advisorIdFieldMatchesOnUpdate(advisorId)` | Güncellemede `advisorId` değişmez + yetki |

## Bilinçli istisnalar

- `agents`: tüm giriş yapmış kullanıcılar okuyabilir (dashboard roster).
- `listings`: tüm giriş yapmış kullanıcılar okur; yazma yalnızca yönetici tier.
- `super_admin`: müşteri ve agent-owned dokümanlarda global erişim.

## Doğrulama

Firebase Console → Rules Playground veya `firebase emulators:exec` ile ofis A danışanı / ofis B yöneticisi senaryolarını test edin.
