# EmlakMaster — Performans Kuralları (No-Lag Rule)

Uygulama 60/120 FPS hedefiyle, takılma olmadan çalışacak şekilde yapılandırılmıştır.

## 1. Açılış (First Paint)

- **Kritik olmayan init ilk frame sonrasına ertelendi:** `SyncManager`, `OnboardingStore.warmUp()`, `AppCacheService` (Hive) `main()` içinde değil; ilk frame çizildikten sonra `addPostFrameCallback` ile çalışır. Böylece kullanıcı anında shell’i görür.
- **Ağır kütüphaneleri global import etmeyin.** Sadece ihtiyaç duyan ekranda import edin veya deferred kullanın.

## 2. Deferred Loading (Code Splitting)

- **Ağır modüller sadece ilgili sayfa açıldığında yüklenir:** War Room, Broker Command, Command Center `lib/core/lazy/deferred_dashboard_pages.dart` içinde `deferred as` ile import edilir. Route’a girildiğinde `loadLibrary()` çağrılır, sonra sayfa gösterilir.
- Yeni ağır özellik eklerken (ör. ROI Simulator, VR/AR ekranı): sayfayı ayrı bir library’de tutup route’ta lazy wrapper ile yükleyin.

## 3. UI Thread

- **Ağır hesaplama ve parsing:** Mümkünse `compute()` (isolate) veya Cloud Functions’a taşıyın. **Portfolio matchmaking** (`topMatchedListingsForCustomerProvider`) artık `compute(computeTopMatchedListings, input)` ile isolate’te çalışır; UI thread serbest kalır.
- **Listeler:** Uzun listelerde mutlaka `ListView.builder` / `ListView.separated` / `GridView.builder` kullanın. `children: [ ... ]` ile tüm item’ları tek seferde oluşturmayın.
- **RepaintBoundary:** Liste item’larında (müşteri kartı, ilan kartı, war room satırı) `RepaintBoundary` kullanıldı; böylece bir item repaint olduğunda diğerleri yeniden çizilmez.

## 4. Görseller

- **Ağ görselleri:** `Image.network` yerine `CachedNetworkImage` kullanılır. Placeholder olarak `ShimmerPlaceholder` ile shimmer gösterilir (listing detay, ilan listesi, ofis logosu).
- Görsel boyutları mümkünse sabit veya `LayoutBuilder` ile sınırlı tutulur (sonsuz constraint hatası önlenir).

## 5. State (Riverpod)

- **Gereksiz rebuild’i azaltın:** Sadece tek bir alan gerekiyorsa `ref.watch(provider.select((v) => v.alan))` kullanın. Örn. `currentUserProvider` için sadece `uid` gerekiyorsa: `ref.watch(currentUserProvider.select((v) => v.valueOrNull?.uid ?? ''))` — Pipeline, Görevler, Bildirimler, Danışman paneli bu şekilde güncellendi.
- **autoDispose:** Sayfa/ekran bazlı veri için `Provider.autoDispose` tercih edin.

## 6. Yerel Önbellek (Hive)

- **AppCacheService** (`lib/core/cache/app_cache_service.dart`): Hive ile hafif key-value cache. Init ilk frame sonrası yapılır. İlan önizleme, sık kullanılan küçük JSON vb. için kullanılabilir.
- Büyük veri setlerini bellekte tutmaktan kaçının; cache’e yazarken TTL veya boyut sınırı düşünün.

## 7. Navigasyon

- Rol bazlı shell (Admin/Agent/Client) zaten kullanılıyor. Ağır sayfalar deferred ile yüklendiği için sadece tıklandığında ilgili modül indirilir.

## 8. Özet Kontrol Listesi

- [ ] Ağır init `main()` veya ilk build’te değil, post-frame veya ilk kullanımda
- [ ] Uzun listelerde `.builder` / `.separated`
- [ ] Ağ görselleri `CachedNetworkImage` + placeholder
- [ ] Ağır sayfalar `deferred` + lazy wrapper
- [ ] Riverpod’da gerektiğinde `.select`
- [ ] Ağır hesaplama `compute()` veya backend

Bu kurallara uyulduğunda uygulama “asla takılmaz” hedefine yakın çalışır.
