#!/usr/bin/env node
/*
 * backfill_calls_officeid.js
 * --------------------------------------------------------------------------
 * Eski `calls` dokümanlarında boş/eksik `officeId` alanını, çağrının
 * danışmanının (`advisorId` / `agentId`) `users/{uid}.officeId` değeriyle
 * doldurur. Çok-ofisli yönetici görünümü (where('officeId'==oid)) eski
 * kayıtları da görebilsin diye GEREKLİDİR.
 *
 * Güvenli: yalnızca officeId boş/eksik olan dokümanları günceller (idempotent).
 *
 * Kullanım:
 *   1) Firebase Admin SDK servis hesabı anahtarını indir (Firebase Console →
 *      Project Settings → Service accounts → Generate new private key).
 *   2) export GOOGLE_APPLICATION_CREDENTIALS="/abs/path/serviceAccount.json"
 *   3) npm i firebase-admin   (geçici bir klasörde yeterli)
 *   4) node scripts/backfill_calls_officeid.js            # önce KURU çalışma
 *      node scripts/backfill_calls_officeid.js --commit   # gerçekten yaz
 *
 * Notlar:
 *   - Önce --commit OLMADAN çalıştır; kaç doküman güncelleneceğini raporlar.
 *   - users.officeId boş olan danışmanların çağrıları atlanır (doldurulamaz).
 */
'use strict';

const admin = require('firebase-admin');

const COMMIT = process.argv.includes('--commit');

admin.initializeApp();
const db = admin.firestore();

const userOfficeCache = new Map();

async function officeIdForAdvisor(advisorId) {
  if (!advisorId) return '';
  if (userOfficeCache.has(advisorId)) return userOfficeCache.get(advisorId);
  const snap = await db.collection('users').doc(advisorId).get();
  const oid = ((snap.exists && snap.data().officeId) || '').trim();
  userOfficeCache.set(advisorId, oid);
  return oid;
}

async function run() {
  console.log(`[backfill] mode=${COMMIT ? 'COMMIT' : 'DRY-RUN'}`);
  let scanned = 0;
  let toUpdate = 0;
  let updated = 0;
  let skippedNoOffice = 0;

  const pageSize = 400;
  let last = null;

  // createdAt sırası önemli değil; tüm koleksiyonu sayfalı tara.
  // (Belge id'sine göre sayfalama, eksiksiz tarama için yeterli.)
  // eslint-disable-next-line no-constant-condition
  while (true) {
    let q = db.collection('calls').orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;

    let batch = db.batch();
    let batchCount = 0;

    for (const doc of snap.docs) {
      scanned++;
      const data = doc.data();
      const current = (data.officeId || '').trim();
      if (current) continue; // zaten dolu

      const advisorId = data.advisorId || data.agentId || '';
      const oid = await officeIdForAdvisor(advisorId);
      if (!oid) {
        skippedNoOffice++;
        continue;
      }
      toUpdate++;
      if (COMMIT) {
        batch.update(doc.ref, { officeId: oid });
        batchCount++;
        if (batchCount >= 400) {
          await batch.commit();
          updated += batchCount;
          batch = db.batch();
          batchCount = 0;
        }
      }
    }

    if (COMMIT && batchCount > 0) {
      await batch.commit();
      updated += batchCount;
    }

    last = snap.docs[snap.docs.length - 1];
    process.stdout.write(`  scanned=${scanned} toUpdate=${toUpdate} updated=${updated}\r`);
  }

  console.log('');
  console.log('[backfill] DONE');
  console.log(`  scanned          = ${scanned}`);
  console.log(`  needs officeId   = ${toUpdate}`);
  console.log(`  updated          = ${COMMIT ? updated : 0}`);
  console.log(`  skipped(no office on advisor) = ${skippedNoOffice}`);
  if (!COMMIT) console.log('  (DRY-RUN — yazmak için: --commit)');
}

run().then(() => process.exit(0)).catch((e) => {
  console.error('[backfill] ERROR', e);
  process.exit(1);
});
