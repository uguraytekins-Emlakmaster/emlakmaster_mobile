# GitHub Actions — Sahibinden → Firestore

| Dosya | Açıklama |
|--------|-----------|
| `ingest_sahibinden.py` | Playwright + parse + Firestore |
| `firebase_credentials.py` | Kimlik: env, dosya yolu veya `.service_account.json` |
| `import_csv.py` | Plan B: CSV → Firestore |
| `sample_listings.csv` | CSV örneği |
| `env.local.example` | `.env.local` şablonu |

**Repo kökünden:** `./scripts/run_listings_ingest_local.sh` (önce `.service_account.json` ve isteğe `.env.local`)

**GitHub secret:** `./scripts/github_listings_push_secret.sh ~/Downloads/firebase-adminsdk….json`

Tam kurulum: **`doc/GITHUB_ACTIONS_LISTINGS_INGEST.md`**
