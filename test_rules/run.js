// Firestore security-rules unit tests — escalation-proofing.
// Run via: npm test  (firebase emulators:exec wraps this against the firestore emulator)
//
// Faithfully replicates the real client write shapes from:
//   - role_selection_page._onRoleSelected / _checkAndApplyInvite  (users create)
//   - OfficeSetupService.createOfficeAsOwner                       (batch: office+membership+users)
//   - OfficeSetupService.joinOfficeWithInviteCode                 (membership+users+invite increment)
// plus crafted-client escalation attempts that MUST fail-closed.

import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from "@firebase/rules-unit-testing";
import {
  doc,
  setDoc,
  updateDoc,
  writeBatch,
  serverTimestamp,
} from "firebase/firestore";

const PROJECT_ID = "emlak-master";
const RULES = readFileSync(new URL("../firestore.rules", import.meta.url), "utf8");

const OWNER = "owner_uid";          // user who created OFFICE_A
const OTHER = "other_uid";          // a different existing office owner
const NEWBIE = "newbie_uid";        // fresh self-service signup
const INVITEE = "invitee_uid";      // accepts an office code-invite
const EMAIL_INVITEE = "email_invitee_uid";
const ATTACKER = "attacker_uid";

const OFFICE_A = "office_a";        // created by OWNER
const OFFICE_X = "office_x";        // created by OTHER (target for cross-tenant attacks)

let env;

function mid(uid, oid) { return `${uid}_${oid}`; }

function officeDoc(createdBy, name = "Test Office") {
  return { name, createdBy, isActive: true, planType: "free", settings: {},
    createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
}
function membershipDoc(uid, oid, role, status = "active", extra = {}) {
  return { officeId: oid, userId: uid, role, status,
    joinedAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra };
}
function officeInviteDoc(oid, createdBy, roleToAssign, code = "ABCD12") {
  return { officeId: oid, code, createdBy, maxUses: 5, usedCount: 0,
    roleToAssign, isActive: true, createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
}
function emailInviteDoc(email, role, createdBy) {
  return { email: email.toLowerCase(), role, createdBy,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
}
function userDoc(uid, role, extra = {}) {
  return { uid, role, name: "X", email: `${uid}@t.co`, isActive: true,
    updatedAt: serverTimestamp(), createdAt: serverTimestamp(), ...extra };
}

const results = [];
async function check(name, kind, fn) {
  // kind: "PASS" => expect success (legit flow); "FAIL" => expect denial (escalation)
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

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    // Existing offices.
    await setDoc(doc(db, "offices", OFFICE_A), officeDoc(OWNER, "Rainbow A"));
    await setDoc(doc(db, "offices", OFFICE_X), officeDoc(OTHER, "Rival X"));
    // OWNER is an active owner member of OFFICE_A.
    await setDoc(doc(db, "office_memberships", mid(OWNER, OFFICE_A)), membershipDoc(OWNER, OFFICE_A, "owner"));
    await setDoc(doc(db, "users", OWNER), userDoc(OWNER, "broker_owner", { officeId: OFFICE_A }));
    // A manager in OFFICE_A who can create email invites (isManager via users.role).
    await setDoc(doc(db, "users", "mgr_uid"), userDoc("mgr_uid", "office_manager", { officeId: OFFICE_A }));
    // Pending email invite (keyed by normalized email) for EMAIL_INVITEE -> office_manager.
    await setDoc(doc(db, "invites", `${EMAIL_INVITEE}@t.co`),
      emailInviteDoc(`${EMAIL_INVITEE}@t.co`, "office_manager", "mgr_uid"));
    // Active office code-invite for INVITEE granting consultant on OFFICE_A.
    await setDoc(doc(db, "office_invites", "inv_consultant"),
      officeInviteDoc(OFFICE_A, OWNER, "consultant", "JOIN01"));
    // ATTACKER already has a benign agent users doc (for update-escalation test).
    await setDoc(doc(db, "users", ATTACKER), userDoc(ATTACKER, "agent"));
    // NEWBIE pre-existing agent doc (for office-creation update path).
    await setDoc(doc(db, "users", NEWBIE), userDoc(NEWBIE, "agent"));
  });
}

function authed(uid, email) {
  return env.authenticatedContext(uid, email ? { email } : undefined).firestore();
}

async function run() {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: RULES, host: "127.0.0.1", port: 8080 },
  });

  console.log("\n=== Firestore Rules: escalation-proofing ===\n");

  // ---------- LEGIT FLOWS (must PASS) ----------
  console.log("LEGIT FLOWS:");
  await env.clearFirestore(); await seed();

  await check("self role-selection: create users as agent", "PASS", () => {
    const db = authed(NEWBIE + "_b", `x@t.co`);
    return setDoc(doc(db, "users", NEWBIE + "_b"), userDoc(NEWBIE + "_b", "agent"));
  });

  await check("createOfficeAsOwner batch (office+owner membership+users role sync)", "PASS", () => {
    const db = authed(NEWBIE, `${NEWBIE}@t.co`);
    const oid = "office_new";
    const b = writeBatch(db);
    b.set(doc(db, "offices", oid), officeDoc(NEWBIE, "Newbie Office"));
    b.set(doc(db, "office_memberships", mid(NEWBIE, oid)), membershipDoc(NEWBIE, oid, "owner"));
    b.set(doc(db, "users", NEWBIE), userDoc(NEWBIE, "broker_owner", { officeId: oid }), { merge: true });
    return b.commit();
  });

  await check("code-invite accept: consultant membership + users sync + invite increment", "PASS", () => {
    const db = authed(INVITEE, `${INVITEE}@t.co`);
    const b = writeBatch(db);
    b.set(doc(db, "office_memberships", mid(INVITEE, OFFICE_A)),
      membershipDoc(INVITEE, OFFICE_A, "consultant", "active", { inviteId: "inv_consultant" }));
    b.set(doc(db, "users", INVITEE), userDoc(INVITEE, "agent", { officeId: OFFICE_A }), { merge: true });
    b.update(doc(db, "office_invites", "inv_consultant"), {
      officeId: OFFICE_A, code: "JOIN01", createdBy: OWNER, maxUses: 5,
      usedCount: 1, roleToAssign: "consultant", isActive: true, updatedAt: serverTimestamp(),
    });
    return b.commit();
  });

  await check("email-invite: create users with office_manager (matching pending invite)", "PASS", () => {
    const db = authed(EMAIL_INVITEE, `${EMAIL_INVITEE}@t.co`);
    return setDoc(doc(db, "users", EMAIL_INVITEE), userDoc(EMAIL_INVITEE, "office_manager"));
  });

  // ---------- ESCALATION ATTEMPTS (must FAIL) ----------
  console.log("\nESCALATION ATTEMPTS:");
  await env.clearFirestore(); await seed();

  await check("E1 self-create users role=broker_owner (no office, no invite)", "FAIL", () => {
    const db = authed("e1_uid", "e1@t.co");
    return setDoc(doc(db, "users", "e1_uid"), userDoc("e1_uid", "broker_owner"));
  });

  await check("E1b self-create users role=super_admin", "FAIL", () => {
    const db = authed("e1b_uid", "e1b@t.co");
    return setDoc(doc(db, "users", "e1b_uid"), userDoc("e1b_uid", "super_admin"));
  });

  await check("E1c self-create users role=office_manager WITHOUT email invite", "FAIL", () => {
    const db = authed("e1c_uid", "e1c@t.co");
    return setDoc(doc(db, "users", "e1c_uid"), userDoc("e1c_uid", "office_manager"));
  });

  await check("E2 self-claim owner membership on existing OTHER office", "FAIL", () => {
    const db = authed(ATTACKER, `${ATTACKER}@t.co`);
    return setDoc(doc(db, "office_memberships", mid(ATTACKER, OFFICE_X)),
      membershipDoc(ATTACKER, OFFICE_X, "owner"));
  });

  await check("E3 self-create manager membership WITHOUT invite", "FAIL", () => {
    const db = authed(ATTACKER, `${ATTACKER}@t.co`);
    return setDoc(doc(db, "office_memberships", mid(ATTACKER, OFFICE_A)),
      membershipDoc(ATTACKER, OFFICE_A, "manager"));
  });

  await check("E3b self-create consultant membership with FAKE inviteId", "FAIL", () => {
    const db = authed(ATTACKER, `${ATTACKER}@t.co`);
    return setDoc(doc(db, "office_memberships", mid(ATTACKER, OFFICE_A)),
      membershipDoc(ATTACKER, OFFICE_A, "consultant", "active", { inviteId: "does_not_exist" }));
  });

  await check("E4 self-update own users.role agent->broker_owner", "FAIL", () => {
    const db = authed(ATTACKER, `${ATTACKER}@t.co`);
    return updateDoc(doc(db, "users", ATTACKER), { role: "broker_owner", updatedAt: serverTimestamp() });
  });

  await env.cleanup();

  // ---------- SUMMARY ----------
  const failed = results.filter((r) => !r.ok);
  console.log(`\n=== SUMMARY: ${results.length - failed.length}/${results.length} as-expected ===`);
  if (failed.length) {
    console.log("UNEXPECTED:");
    for (const r of failed) console.log(`  - [${r.kind}] ${r.name}`);
    process.exitCode = 1;
  } else {
    console.log("All assertions matched expectations.");
  }
}

run().catch((e) => { console.error(e); process.exitCode = 1; });
