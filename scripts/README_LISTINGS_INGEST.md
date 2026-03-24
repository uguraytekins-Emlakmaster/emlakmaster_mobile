# Listings ingest — script indeksi

| Script | Açıklama |
|--------|-----------|
| `listings_ingest_do_everything.sh` | Pytest + Playwright + `.env.local` + (varsa) ingest + (varsa) gh secret |
| `run_listings_ingest_local.sh` | Sadece yerel `ingest_sahibinden.py` |
| `github_listings_push_secret.sh` | `gh secret set` ile Firebase JSON |
| `github_listings_set_variables.sh` | `gh variable set` (MAX_LISTINGS, CITY_NAME, …) |

Detay: `doc/GITHUB_ACTIONS_LISTINGS_INGEST.md`
