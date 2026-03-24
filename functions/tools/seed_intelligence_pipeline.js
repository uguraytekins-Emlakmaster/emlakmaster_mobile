#!/usr/bin/env node
/**
 * Firestore: app_settings/intelligence_pipeline dokümanını yazar (sunucu rollup + istemci demo kapatma).
 *
 * Gereksinim (birini kullanın):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 * veya:
 *   gcloud auth application-default login
 *   (Proje sahibi / Firestore yetkili hesap)
 *
 * Çalıştırma (proje kökü veya functions içinden):
 *   cd functions && npm install && node tools/seed_intelligence_pipeline.js
 */
"use strict";

const admin = require("firebase-admin");

function initAdmin() {
  if (admin.apps.length) return;
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  } catch (e) {
    console.error(
      "firebase-admin başlatılamadı. GOOGLE_APPLICATION_CREDENTIALS veya gcloud ADC ayarlayın.\n",
      e.message
    );
    process.exit(1);
  }
}

async function main() {
  initAdmin();
  const db = admin.firestore();

  const clientSeed = process.env.CLIENT_SEED_INTELLIGENCE;
  const clientSeedWritesEnabled =
    clientSeed === undefined || clientSeed === ""
      ? false
      : clientSeed === "true" || clientSeed === "1";

  const ratioRaw = process.env.OPPORTUNITY_PRICE_RATIO;
  const opportunityPriceRatio =
    ratioRaw && !Number.isNaN(Number(ratioRaw))
      ? Math.min(0.99, Math.max(0.5, Number(ratioRaw)))
      : 0.85;

  await db
    .collection("app_settings")
    .doc("intelligence_pipeline")
    .set(
      {
        clientSeedWritesEnabled,
        opportunityPriceRatio,
        seededAt: admin.firestore.FieldValue.serverTimestamp(),
        seededBy: "functions/tools/seed_intelligence_pipeline.js",
      },
      { merge: true }
    );

  console.log("✓ app_settings/intelligence_pipeline güncellendi:", {
    clientSeedWritesEnabled,
    opportunityPriceRatio,
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
