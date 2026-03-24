# Listings ingest — komut çalışmıyorsa

## 1) Doğru klasör

Scriptler **`emlakmaster_mobile`** içinde (Flutter projesinin kökü).  
**`Projeler` kökünden `./scripts/...` çalışmaz** — önce proje klasörüne gir:

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
```

*(Kendi kullanıcı adına göre `uguraytekin` kısmını değiştir.)*

## 2) Secret’ı GitHub’a yükle (önerilen)

`…` yerine **gerçek dosya adını** yaz (ör. `firebase-adminsdk-ab12c.json`). Tam yol kullan:

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile

bash push_firebase_secret_to_github.sh "$HOME/Downloads/firebase-adminsdk-XXXX.json"
```

veya:

```bash
bash scripts/github_listings_push_secret.sh "$HOME/Downloads/firebase-adminsdk-XXXX.json"
```

**`./` yerine `bash ...` kullanmak** izin sorunlarında işe yarar.

Önkoşul: `brew install gh` ve `gh auth login` (bir kez).

## 3) Tam kurulum scripti

```bash
cd /Users/uguraytekin/Projeler/EmlakMaster_Proje/emlakmaster_mobile
bash run_listings_ingest_do_everything.sh
```

## 4) Sık hatalar

| Hata | Çözüm |
|------|--------|
| `No such file or directory` | `cd` ile **emlakmaster_mobile** içinde olduğundan emin ol. |
| `gh: command not found` | `brew install gh` |
| `You are not logged into any GitHub hosts` | `gh auth login` |
| `Dosya bulunamadı` | İndirilen JSON’un tam yolunu kopyala (Finder: Option + sağ tık → yol). |
| `git deposu değil` | Komutu **içinde `.git` olan** `emlakmaster_mobile` klasöründe çalıştır. |
