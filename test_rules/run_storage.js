// Firebase Storage security-rules unit tests — escalation-proofing.
// Run via: npm run test:storage  (firebase emulators:exec wraps this against
// the firestore + storage emulators; the storage rules read Firestore for
// role / office-membership checks, so Firestore is seeded first with rules
// disabled).
//
// Faithfully replicates the real client write shapes from:
//   - LogoStorageService.uploadLogo*            -> listing_display/company_logo_*.jpg
//   - OfficeLogoStorageService.uploadOfficeLogo -> offices/{officeId}/logo/*.jpg
//   - avatar upload                             -> users/{uid}/avatar/avatar_256.jpg
//   - office import upload                      -> offices/{officeId}/imports/{sessionId}/*.csv
// plus crafted-client escalation / cross-tenant attempts that MUST fail-closed.

import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from "@firebase/rules-unit-testing";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import {
  ref,
  uploadBytes,
  getBytes,
  deleteObject,
} from "firebase/storage";

const PROJECT_ID = "emlak-master";
const FIRESTORE_RULES = readFileSync(new URL("../firestore.rules", import.meta.url), "utf8");
const STORAGE_RULES = readFileSync(new URL("../storage.rules", import.meta.url), "utf8");

// Users (Firestore users/{uid}.role)
const SUPER = "super_uid";           // super_admin, no office
const BROKER_GLOBAL = "broker_global_uid"; // broker_owner, NO office context (legit global showcase uploader)
const OWNER_A = "owner_a_uid";       // broker_owner, owner membership of OFFICE_A
const ADMIN_A = "admin_a_uid";       // office_manager, admin membership of OFFICE_A
const MGR_A = "mgr_a_uid";           // office_manager, manager membership of OFFICE_A
const AGENT_A = "agent_a_uid";       // agent, consultant membership of OFFICE_A
const OWNER_B = "owner_b_uid";       // broker_owner, owner membership of OFFICE_B
const OM_NOOFFICE = "om_nooffice_uid"; // office_manager, NO membership (cross-tenant attacker)
const PLAIN_AGENT = "plain_agent_uid"; // agent, no office

const OFFICE_A = "office_a";
const OFFICE_B = "office_b";

let env;

function mid(uid, oid) { return `${uid}_${oid}`; }
function membershipDoc(uid, oid, role, status = "active") {
  return { officeId: oid, userId: uid, role, status,
    joinedAt: serverTimestamp(), updatedAt: serverTimestamp() };
}
function userDoc(uid, role, extra = {}) {
  return { uid, role, name: "X", email: `${uid}@t.co`, isActive: true,
    updatedAt: serverTimestamp(), createdAt: serverTimestamp(), ...extra };
}

// byte buffers
function bytes(n) { return new Uint8Array(n); }
const SMALL = bytes(1024);                 // 1 KB
const IMG_META = { contentType: "image/jpeg" };
const CSV_META = { contentType: "text/csv" };
const PDF_META = { contentType: "application/pdf" };
const XLSX_META = { contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" };
const OVER_2MB = bytes(2 * 1024 * 1024 + 1);
const OVER_3MB = bytes(3 * 1024 * 1024 + 1);

const results = [];
async function check(name, kind, fn) {
  try {
    if (kind === "PASS") await assertSucceeds(fn());
    else await assertFails(fn());
    results.push({ name, kind, ok: true });
    console.log(`  \u2713 [${kind}] ${name}`);
  } catch (e) {
    results.push({ name, kind, ok: false, err: e.message });
    console.log(`  \u2717 [${kind}] ${name}\n      ${String(e.message).split("\n")[0]}`);
  }
}

function st(uid) { return env.authenticatedContext(uid).storage(); }
function stUnauth() { return env.unauthenticatedContext().storage(); }

async function seedFirestore() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "users", SUPER), userDoc(SUPER, "super_admin"));
    await setDoc(doc(db, "users", BROKER_GLOBAL), userDoc(BROKER_GLOBAL, "broker_owner"));
    await setDoc(doc(db, "users", OWNER_A), userDoc(OWNER_A, "broker_owner", { officeId: OFFICE_A }));
    await setDoc(doc(db, "users", ADMIN_A), userDoc(ADMIN_A, "office_manager", { officeId: OFFICE_A }));
    await setDoc(doc(db, "users", MGR_A), userDoc(MGR_A, "office_manager", { officeId: OFFICE_A }));
    await setDoc(doc(db, "users", AGENT_A), userDoc(AGENT_A, "agent", { officeId: OFFICE_A }));
    await setDoc(doc(db, "users", OWNER_B), userDoc(OWNER_B, "broker_owner", { officeId: OFFICE_B }));
    await setDoc(doc(db, "users", OM_NOOFFICE), userDoc(OM_NOOFFICE, "office_manager"));
    await setDoc(doc(db, "users", PLAIN_AGENT), userDoc(PLAIN_AGENT, "agent"));

    await setDoc(doc(db, "office_memberships", mid(OWNER_A, OFFICE_A)), membershipDoc(OWNER_A, OFFICE_A, "owner"));
    await setDoc(doc(db, "office_memberships", mid(ADMIN_A, OFFICE_A)), membershipDoc(ADMIN_A, OFFICE_A, "admin"));
    await setDoc(doc(db, "office_memberships", mid(MGR_A, OFFICE_A)), membershipDoc(MGR_A, OFFICE_A, "manager"));
    await setDoc(doc(db, "office_memberships", mid(AGENT_A, OFFICE_A)), membershipDoc(AGENT_A, OFFICE_A, "consultant"));
    await setDoc(doc(db, "office_memberships", mid(OWNER_B, OFFICE_B)), membershipDoc(OWNER_B, OFFICE_B, "owner"));
  });
}

// Seed storage objects (rules disabled) so read tests have something to fetch.
async function seedStorage() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const s = ctx.storage();
    await uploadBytes(ref(s, `users/${OWNER_A}/avatar/avatar_256.jpg`), SMALL, IMG_META);
    await uploadBytes(ref(s, `offices/${OFFICE_A}/logo/office_logo_1.jpg`), SMALL, IMG_META);
    await uploadBytes(ref(s, `offices/${OFFICE_A}/imports/sess1/data.csv`), SMALL, CSV_META);
    await uploadBytes(ref(s, `listing_display/company_logo_1.jpg`), SMALL, IMG_META);
  });
}

async function run() {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: FIRESTORE_RULES, host: "127.0.0.1", port: 8080 },
    storage: { rules: STORAGE_RULES, host: "127.0.0.1", port: 9199 },
  });

  console.log("\n=== Storage Rules: escalation-proofing ===\n");
  await env.clearFirestore();
  await env.clearStorage();
  await seedFirestore();
  await seedStorage();

  // ---------- LEGIT FLOWS (must PASS) ----------
  console.log("LEGIT FLOWS:");

  await check("avatar: user uploads OWN avatar (image, <2MB)", "PASS", () =>
    uploadBytes(ref(st(PLAIN_AGENT), `users/${PLAIN_AGENT}/avatar/avatar_256.jpg`), SMALL, IMG_META));

  await check("avatar (legacy flat path): user uploads OWN avatar_256.jpg", "PASS", () =>
    uploadBytes(ref(st(PLAIN_AGENT), `users/${PLAIN_AGENT}/avatar_256.jpg`), SMALL, IMG_META));

  await check("avatar: any signed-in user READS another user's avatar", "PASS", () =>
    getBytes(ref(st(PLAIN_AGENT), `users/${OWNER_A}/avatar/avatar_256.jpg`)));

  await check("avatar: user DELETES own avatar", "PASS", () =>
    deleteObject(ref(st(PLAIN_AGENT), `users/${PLAIN_AGENT}/avatar/avatar_256.jpg`)));

  await check("office logo: OWNER member uploads (image, <3MB)", "PASS", () =>
    uploadBytes(ref(st(OWNER_A), `offices/${OFFICE_A}/logo/office_logo_2.jpg`), SMALL, IMG_META));

  await check("office logo: ADMIN member uploads", "PASS", () =>
    uploadBytes(ref(st(ADMIN_A), `offices/${OFFICE_A}/logo/office_logo_3.jpg`), SMALL, IMG_META));

  await check("office logo: MANAGER member uploads", "PASS", () =>
    uploadBytes(ref(st(MGR_A), `offices/${OFFICE_A}/logo/office_logo_4.jpg`), SMALL, IMG_META));

  await check("office logo: super_admin (non-member) uploads", "PASS", () =>
    uploadBytes(ref(st(SUPER), `offices/${OFFICE_A}/logo/office_logo_sa.jpg`), SMALL, IMG_META));

  await check("office logo: active member (agent) READS office logo", "PASS", () =>
    getBytes(ref(st(AGENT_A), `offices/${OFFICE_A}/logo/office_logo_1.jpg`)));

  await check("office logo: OWNER deletes office logo", "PASS", () =>
    deleteObject(ref(st(OWNER_A), `offices/${OFFICE_A}/logo/office_logo_1.jpg`)));

  await check("imports: office MANAGER uploads CSV (<16MB)", "PASS", () =>
    uploadBytes(ref(st(MGR_A), `offices/${OFFICE_A}/imports/sess2/list.csv`), SMALL, CSV_META));

  await check("imports: office OWNER uploads XLSX", "PASS", () =>
    uploadBytes(ref(st(OWNER_A), `offices/${OFFICE_A}/imports/sess2/list.xlsx`), SMALL, XLSX_META));

  await check("imports: active member (agent) READS import", "PASS", () =>
    getBytes(ref(st(AGENT_A), `offices/${OFFICE_A}/imports/sess1/data.csv`)));

  await check("listing_display: super_admin uploads global showcase logo", "PASS", () =>
    uploadBytes(ref(st(SUPER), `listing_display/company_logo_sa.jpg`), SMALL, IMG_META));

  await check("listing_display: global broker_owner (no office) uploads showcase logo", "PASS", () =>
    uploadBytes(ref(st(BROKER_GLOBAL), `listing_display/company_logo_bo.jpg`), SMALL, IMG_META));

  await check("listing_display: any signed-in user READS global logo", "PASS", () =>
    getBytes(ref(st(PLAIN_AGENT), `listing_display/company_logo_1.jpg`)));

  // ---------- ESCALATION / CROSS-TENANT ATTEMPTS (must FAIL) ----------
  console.log("\nESCALATION ATTEMPTS:");

  await check("A1 avatar: upload to ANOTHER user's avatar path", "FAIL", () =>
    uploadBytes(ref(st(PLAIN_AGENT), `users/${OWNER_A}/avatar/avatar_256.jpg`), SMALL, IMG_META));

  await check("A2 avatar: unauthenticated read", "FAIL", () =>
    getBytes(ref(stUnauth(), `users/${OWNER_A}/avatar/avatar_256.jpg`)));

  await check("A3 avatar: oversized (>2MB) own upload", "FAIL", () =>
    uploadBytes(ref(st(PLAIN_AGENT), `users/${PLAIN_AGENT}/avatar/big.jpg`), OVER_2MB, IMG_META));

  await check("A4 avatar: wrong content-type (pdf) own upload", "FAIL", () =>
    uploadBytes(ref(st(PLAIN_AGENT), `users/${PLAIN_AGENT}/avatar/x.pdf`), SMALL, PDF_META));

  await check("A5 office logo: NON-member uploads", "FAIL", () =>
    uploadBytes(ref(st(PLAIN_AGENT), `offices/${OFFICE_A}/logo/hack.jpg`), SMALL, IMG_META));

  await check("A6 office logo: WRONG-office owner (B) uploads to A", "FAIL", () =>
    uploadBytes(ref(st(OWNER_B), `offices/${OFFICE_A}/logo/hack.jpg`), SMALL, IMG_META));

  await check("A7 office logo: active CONSULTANT member uploads", "FAIL", () =>
    uploadBytes(ref(st(AGENT_A), `offices/${OFFICE_A}/logo/hack.jpg`), SMALL, IMG_META));

  await check("A8 office logo: oversized (>3MB) by owner", "FAIL", () =>
    uploadBytes(ref(st(OWNER_A), `offices/${OFFICE_A}/logo/big.jpg`), OVER_3MB, IMG_META));

  await check("A9 office logo: NON-member reads", "FAIL", () =>
    getBytes(ref(st(PLAIN_AGENT), `offices/${OFFICE_A}/logo/office_logo_1.jpg`)));

  await check("A10 imports: active CONSULTANT member uploads", "FAIL", () =>
    uploadBytes(ref(st(AGENT_A), `offices/${OFFICE_A}/imports/sess9/hack.csv`), SMALL, CSV_META));

  await check("A11 imports: wrong content-type (image) by owner", "FAIL", () =>
    uploadBytes(ref(st(OWNER_A), `offices/${OFFICE_A}/imports/sess9/hack.jpg`), SMALL, IMG_META));

  await check("A12 imports: NON-member reads", "FAIL", () =>
    getBytes(ref(st(OWNER_B), `offices/${OFFICE_A}/imports/sess1/data.csv`)));

  await check("A13 listing_display: cross-tenant office_manager (member of A) writes global", "FAIL", () =>
    uploadBytes(ref(st(MGR_A), `listing_display/hack.jpg`), SMALL, IMG_META));

  await check("A14 listing_display: office_manager WITHOUT office writes global", "FAIL", () =>
    uploadBytes(ref(st(OM_NOOFFICE), `listing_display/hack.jpg`), SMALL, IMG_META));

  await check("A15 listing_display: plain agent writes global", "FAIL", () =>
    uploadBytes(ref(st(PLAIN_AGENT), `listing_display/hack.jpg`), SMALL, IMG_META));

  await check("A16 listing_display: super_admin wrong content-type (pdf)", "FAIL", () =>
    uploadBytes(ref(st(SUPER), `listing_display/x.pdf`), SMALL, PDF_META));

  await check("A17 listing_display: cross-tenant office_manager DELETES global", "FAIL", () =>
    deleteObject(ref(st(MGR_A), `listing_display/company_logo_1.jpg`)));

  await check("A18 catch-all: write to arbitrary path", "FAIL", () =>
    uploadBytes(ref(st(SUPER), `random/secret.txt`), SMALL, { contentType: "text/plain" }));

  await check("A19 catch-all: read arbitrary path", "FAIL", () =>
    getBytes(ref(st(SUPER), `random/secret.txt`)));

  await check("A20 legacy users/{uid}/imports: write disabled even for own uid", "FAIL", () =>
    uploadBytes(ref(st(PLAIN_AGENT), `users/${PLAIN_AGENT}/imports/old.csv`), SMALL, CSV_META));

  await env.cleanup();

  // ---------- SUMMARY ----------
  const failed = results.filter((r) => !r.ok);
  console.log(`\n=== SUMMARY: ${results.length - failed.length}/${results.length} as-expected ===`);
  if (failed.length) {
    console.log("UNEXPECTED:");
    for (const r of failed) console.log(`  - [${r.kind}] ${r.name}${r.err ? `  ::  ${String(r.err).split("\n")[0]}` : ""}`);
    process.exitCode = 1;
  } else {
    console.log("All assertions matched expectations.");
  }
}

run().catch((e) => { console.error(e); process.exitCode = 1; });
