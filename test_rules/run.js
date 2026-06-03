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
  getDoc,
  setDoc,
  updateDoc,
  writeBatch,
  serverTimestamp,
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
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
// Mirrors ListingDisplaySettingsRepository.set (app_settings/listing_display_settings).
function listingDisplayDoc(companyName = "Rainbow Emlak") {
  return { cityCode: "21", cityName: "Diyarbakır", districtCode: null,
    districtName: null, companyName, logoUrl: null, updatedAt: serverTimestamp() };
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

    // app_settings authority: owner/admin whose users.role is STALE 'agent'
    // (legacy / unsynced) but who hold an active membership. Authority must come
    // from office_memberships (role_source_of_truth), not users.role.
    await setDoc(doc(db, "office_memberships", mid("legacy_owner_uid", OFFICE_A)),
      membershipDoc("legacy_owner_uid", OFFICE_A, "owner"));
    await setDoc(doc(db, "users", "legacy_owner_uid"),
      userDoc("legacy_owner_uid", "agent", { officeId: OFFICE_A }));
    await setDoc(doc(db, "office_memberships", mid("legacy_admin_uid", OFFICE_A)),
      membershipDoc("legacy_admin_uid", OFFICE_A, "admin"));
    await setDoc(doc(db, "users", "legacy_admin_uid"),
      userDoc("legacy_admin_uid", "agent", { officeId: OFFICE_A }));
    // Manager-tier membership ('manager' -> team_lead users.role) with STALE users.role.
    await setDoc(doc(db, "office_memberships", mid("legacy_manager_uid", OFFICE_A)),
      membershipDoc("legacy_manager_uid", OFFICE_A, "manager"));
    await setDoc(doc(db, "users", "legacy_manager_uid"),
      userDoc("legacy_manager_uid", "agent", { officeId: OFFICE_A }));
    // Escalation guard: an owner membership that is NOT active (removed) must NOT
    // grant manager — status gating is enforced by isManagerBySelfMembership.
    await setDoc(doc(db, "office_memberships", mid("removed_owner_uid", OFFICE_A)),
      membershipDoc("removed_owner_uid", OFFICE_A, "owner", "removed"));
    await setDoc(doc(db, "users", "removed_owner_uid"),
      userDoc("removed_owner_uid", "agent", { officeId: OFFICE_A }));
    // Consultant (and an office-less plain agent) must NOT be able to write settings.
    await setDoc(doc(db, "office_memberships", mid("consultant2_uid", OFFICE_A)),
      membershipDoc("consultant2_uid", OFFICE_A, "consultant"));
    await setDoc(doc(db, "users", "consultant2_uid"),
      userDoc("consultant2_uid", "agent", { officeId: OFFICE_A }));
    await setDoc(doc(db, "users", "plain_agent_uid"), userDoc("plain_agent_uid", "agent"));
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

  // ---------- APP SETTINGS: listing display (owner can save, others cannot) ----------
  console.log("\nAPP SETTINGS (listing_display_settings):");
  await env.clearFirestore(); await seed();

  await check("S1 broker_owner (users.role) saves listing display settings", "PASS", () => {
    const db = authed(OWNER, `${OWNER}@t.co`);
    return setDoc(doc(db, "app_settings", "listing_display_settings"),
      listingDisplayDoc("Owner Co"), { merge: true });
  });

  await check("S2 office_manager (users.role) saves listing display settings", "PASS", () => {
    const db = authed("mgr_uid", "mgr_uid@t.co");
    return setDoc(doc(db, "app_settings", "listing_display_settings"),
      listingDisplayDoc("Mgr Co"), { merge: true });
  });

  await check("S3 owner with STALE users.role=agent (membership owner) saves settings", "PASS", () => {
    const db = authed("legacy_owner_uid", "legacy_owner_uid@t.co");
    return setDoc(doc(db, "app_settings", "listing_display_settings"),
      listingDisplayDoc("Legacy Owner Co"), { merge: true });
  });

  await check("S4 admin with STALE users.role=agent (membership admin) saves settings", "PASS", () => {
    const db = authed("legacy_admin_uid", "legacy_admin_uid@t.co");
    return setDoc(doc(db, "app_settings", "listing_display_settings"),
      listingDisplayDoc("Legacy Admin Co"), { merge: true });
  });

  await check("S5 consultant membership CANNOT save listing display settings", "FAIL", () => {
    const db = authed("consultant2_uid", "consultant2_uid@t.co");
    return setDoc(doc(db, "app_settings", "listing_display_settings"),
      listingDisplayDoc("Hacker Co"), { merge: true });
  });

  await check("S6 plain agent (no office) CANNOT save listing display settings", "FAIL", () => {
    const db = authed("plain_agent_uid", "plain_agent_uid@t.co");
    return setDoc(doc(db, "app_settings", "listing_display_settings"),
      listingDisplayDoc("Nope Co"), { merge: true });
  });

  await check("S7 any signed-in user can READ listing display settings", "PASS", () => {
    const db = authed("plain_agent_uid", "plain_agent_uid@t.co");
    return getDoc(doc(db, "app_settings", "listing_display_settings"));
  });

  // ---------- MEMBERSHIP-AWARE isManager() across representative collections ----------
  // Proves the central helper is consistent for EVERY isManager()-gated collection:
  // (a) stale users.role='agent' + active owner/admin/manager membership => manager ops OK;
  // (b) consultant membership / office-less agent => denied;
  // (c) legacy users.role manager + global broker_owner regress clean;
  // plus escalation guard: non-active (removed) owner membership must NOT grant manager.
  console.log("\nMEMBERSHIP-AWARE MANAGER (listings / teams / users-read / invites):");
  await env.clearFirestore(); await seed();

  const listingDoc = () => ({ title: "Daire", officeId: OFFICE_A, createdAt: serverTimestamp() });
  const teamDoc = () => ({ name: "Team A", officeId: OFFICE_A, createdAt: serverTimestamp() });

  // listings: create/update gated by isManager() only.
  await check("M1 stale-agent OWNER membership creates listing", "PASS", () => {
    const db = authed("legacy_owner_uid", "legacy_owner_uid@t.co");
    return setDoc(doc(db, "listings", "l_owner"), listingDoc());
  });
  await check("M2 stale-agent ADMIN membership creates listing", "PASS", () => {
    const db = authed("legacy_admin_uid", "legacy_admin_uid@t.co");
    return setDoc(doc(db, "listings", "l_admin"), listingDoc());
  });
  await check("M3 stale-agent MANAGER membership creates listing", "PASS", () => {
    const db = authed("legacy_manager_uid", "legacy_manager_uid@t.co");
    return setDoc(doc(db, "listings", "l_manager"), listingDoc());
  });
  await check("M4 consultant membership CANNOT create listing", "FAIL", () => {
    const db = authed("consultant2_uid", "consultant2_uid@t.co");
    return setDoc(doc(db, "listings", "l_consultant"), listingDoc());
  });
  await check("M5 office-less plain agent CANNOT create listing", "FAIL", () => {
    const db = authed("plain_agent_uid", "plain_agent_uid@t.co");
    return setDoc(doc(db, "listings", "l_agent"), listingDoc());
  });
  await check("M6 REGRESSION: broker_owner (users.role) creates listing", "PASS", () => {
    const db = authed(OWNER, `${OWNER}@t.co`);
    return setDoc(doc(db, "listings", "l_legacy_mgr"), listingDoc());
  });
  await check("M7 ESCALATION GUARD: removed owner membership CANNOT create listing", "FAIL", () => {
    const db = authed("removed_owner_uid", "removed_owner_uid@t.co");
    return setDoc(doc(db, "listings", "l_removed"), listingDoc());
  });

  // teams: read+write gated by isManager().
  await check("M8 stale-agent OWNER membership writes team", "PASS", () => {
    const db = authed("legacy_owner_uid", "legacy_owner_uid@t.co");
    return setDoc(doc(db, "teams", "t_owner"), teamDoc());
  });
  await check("M9 consultant membership CANNOT write team", "FAIL", () => {
    const db = authed("consultant2_uid", "consultant2_uid@t.co");
    return setDoc(doc(db, "teams", "t_consultant"), teamDoc());
  });

  // analytics_monthly: write gated by isManager().
  const monthlyDoc = () => ({ officeId: OFFICE_A, total: 1, updatedAt: serverTimestamp() });
  await check("M10 stale-agent ADMIN membership writes analytics_monthly", "PASS", () => {
    const db = authed("legacy_admin_uid", "legacy_admin_uid@t.co");
    return setDoc(doc(db, "analytics_monthly", "2026-06"), monthlyDoc());
  });
  await check("M11 office-less plain agent CANNOT write analytics_monthly", "FAIL", () => {
    const db = authed("plain_agent_uid", "plain_agent_uid@t.co");
    return setDoc(doc(db, "analytics_monthly", "2026-07"), monthlyDoc());
  });

  // invites: create gated by isManager().
  await check("M12 stale-agent OWNER membership creates email invite", "PASS", () => {
    const db = authed("legacy_owner_uid", "legacy_owner_uid@t.co");
    return setDoc(doc(db, "invites", "new_hire@t.co"),
      emailInviteDoc("new_hire@t.co", "office_manager", "legacy_owner_uid"));
  });
  await check("M13 consultant membership CANNOT create email invite", "FAIL", () => {
    const db = authed("consultant2_uid", "consultant2_uid@t.co");
    return setDoc(doc(db, "invites", "evil@t.co"),
      emailInviteDoc("evil@t.co", "office_manager", "consultant2_uid"));
  });

  // ===========================================================================
  // READ ISOLATION — replicates the app's ACTUAL list/get/count query shapes
  // across TWO offices and every role. Validates that flipping the root catch-all
  // to DENY (1) closes cross-office reads on the now-active isolated collections
  // and (2) does NOT break the legit query shapes the app issues (incl. the CRM
  // transactional collections that remain intentionally signed-in-readable).
  // ===========================================================================
  console.log("\nREAD ISOLATION (multi-office, real query shapes):");

  const A = "iso_office_a", B = "iso_office_b";
  const MGRA = "iso_mgr_a";              // office_manager of A (users.role)
  const AG_A1 = "iso_agent_a1", AG_A2 = "iso_agent_a2"; // agents in A
  const AG_B1 = "iso_agent_b1";          // agent in B
  const SUPER = "iso_super";             // super_admin (all offices)

  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const u = (uid, role, oid) => setDoc(doc(db, "users", uid),
      { uid, role, name: uid, email: `${uid}@t.co`, isActive: true, officeId: oid,
        managerId: role === "agent" ? MGRA : null });
    const mem = (uid, oid, role) => setDoc(doc(db, "office_memberships", `${uid}_${oid}`),
      membershipDoc(uid, oid, role));
    await Promise.all([
      u(MGRA, "office_manager", A), u(AG_A1, "agent", A), u(AG_A2, "agent", A),
      u(AG_B1, "agent", B), u(SUPER, "super_admin", ""),
      setDoc(doc(db, "offices", A), officeDoc(MGRA, "Office A")),
      setDoc(doc(db, "offices", B), officeDoc(AG_B1, "Office B")),
      mem(MGRA, A, "manager"), mem(AG_A1, A, "consultant"), mem(AG_A2, A, "consultant"),
      mem(AG_B1, B, "consultant"),
      // CRM transactional docs (assignedAgentId / agentId+advisorId / customerId / officeId)
      setDoc(doc(db, "customers", "cust_a1"), { assignedAgentId: AG_A1, fullName: "A1", createdAt: serverTimestamp(), updatedAt: serverTimestamp() }),
      setDoc(doc(db, "customers", "cust_a2"), { assignedAgentId: AG_A2, fullName: "A2", createdAt: serverTimestamp(), updatedAt: serverTimestamp() }),
      setDoc(doc(db, "customers", "cust_b1"), { assignedAgentId: AG_B1, fullName: "B1", createdAt: serverTimestamp(), updatedAt: serverTimestamp() }),
      setDoc(doc(db, "calls", "call_a1"), { agentId: AG_A1, advisorId: AG_A1, officeId: A, customerId: "cust_a1", outcome: "handoff_pending", done: false, createdAt: serverTimestamp() }),
      setDoc(doc(db, "calls", "call_b1"), { agentId: AG_B1, advisorId: AG_B1, officeId: B, customerId: "cust_b1", outcome: "connected", createdAt: serverTimestamp() }),
      setDoc(doc(db, "notes", "note_a1"), { advisorId: AG_A1, customerId: "cust_a1", content: "x", createdAt: serverTimestamp() }),
      setDoc(doc(db, "visits", "visit_a1"), { advisorId: AG_A1, customerId: "cust_a1", scheduledAt: serverTimestamp(), createdAt: serverTimestamp() }),
      setDoc(doc(db, "offers", "offer_a1"), { advisorId: AG_A1, customerId: "cust_a1", amount: 1, createdAt: serverTimestamp() }),
      setDoc(doc(db, "deals", "deal_a1"), { agentId: AG_A1, createdAt: serverTimestamp() }),
      setDoc(doc(db, "call_summaries", "cs_a1"), { agentId: AG_A1, assignedAgentId: AG_A1, callId: "call_a1", customerId: "cust_a1", createdAt: serverTimestamp() }),
      setDoc(doc(db, "tasks", "task_a1"), { advisorId: AG_A1, customerId: "cust_a1", done: false, dueAt: serverTimestamp(), createdAt: serverTimestamp() }),
      // isolation-target docs
      setDoc(doc(db, "pipeline_items", "pi_a1"), { advisorId: AG_A1, stage: "new", updatedAt: serverTimestamp() }),
      setDoc(doc(db, "pipeline_items", "pi_b1"), { advisorId: AG_B1, stage: "new", updatedAt: serverTimestamp() }),
      setDoc(doc(db, "notifications", "ntf_a1"), { userId: AG_A1, createdAt: serverTimestamp() }),
      setDoc(doc(db, "notifications", "ntf_b1"), { userId: AG_B1, createdAt: serverTimestamp() }),
      setDoc(doc(db, "integration_listings", "il_a1"), { ownerUserId: AG_A1, title: "L" }),
      setDoc(doc(db, "integration_listings", "il_b1"), { ownerUserId: AG_B1, title: "L" }),
      setDoc(doc(db, "external_connections", "ec_a1"), { userId: AG_A1 }),
      setDoc(doc(db, "external_connections", "ec_b1"), { userId: AG_B1 }),
      setDoc(doc(db, "audit_logs", "al_1"), { action: "x", createdAt: serverTimestamp() }),
      setDoc(doc(db, "app_config", "superAdminGate"), { codeSha256: "deadbeef" }),
      setDoc(doc(db, "listing_metrics", "lm_a1"), { momentum: 1 }),
      setDoc(doc(db, "teams", "team_a1"), { name: "T", managerId: MGRA, memberIds: [AG_A1], officeId: A, createdAt: serverTimestamp() }),
      setDoc(doc(db, "app_settings", "listing_display_settings"), listingDisplayDoc("Co")),
    ]);
  });

  const dbOf = (uid) => env.authenticatedContext(uid).firestore();

  // --- users: agent cross-office read CLOSED; same-office colleague OPEN; self OPEN ---
  await check("users: agent A1 reads OWN doc", "PASS", () =>
    getDoc(doc(dbOf(AG_A1), "users", AG_A1)));
  await check("users: agent A1 reads same-office MANAGER doc (colleague branch)", "PASS", () =>
    getDoc(doc(dbOf(AG_A1), "users", MGRA)));
  await check("users: agent A1 reads same-office colleague A2", "PASS", () =>
    getDoc(doc(dbOf(AG_A1), "users", AG_A2)));
  await check("users: agent A1 reads CROSS-OFFICE agent B1 -> DENY", "FAIL", () =>
    getDoc(doc(dbOf(AG_A1), "users", AG_B1)));
  await check("users: agent B1 reads CROSS-OFFICE manager A -> DENY", "FAIL", () =>
    getDoc(doc(dbOf(AG_B1), "users", MGRA)));
  await check("users: super reads cross-office B1", "PASS", () =>
    getDoc(doc(dbOf(SUPER), "users", AG_B1)));

  // --- office_memberships: member office-scoped query OK; cross-office DENY ---
  await check("office_memberships: agent A1 query where officeId==A", "PASS", () =>
    getDocs(query(collection(dbOf(AG_A1), "office_memberships"), where("officeId", "==", A))));
  await check("office_memberships: agent A1 query where officeId==B -> DENY", "FAIL", () =>
    getDocs(query(collection(dbOf(AG_A1), "office_memberships"), where("officeId", "==", B))));
  await check("office_memberships: agent A1 reads OWN membership doc", "PASS", () =>
    getDoc(doc(dbOf(AG_A1), "office_memberships", `${AG_A1}_${A}`)));
  await check("office_memberships: manager A query where officeId==A", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "office_memberships"), where("officeId", "==", A))));

  // --- offices: member get OK; cross-office DENY ---
  await check("offices: agent A1 reads office A", "PASS", () =>
    getDoc(doc(dbOf(AG_A1), "offices", A)));
  await check("offices: agent A1 reads CROSS office B -> DENY", "FAIL", () =>
    getDoc(doc(dbOf(AG_A1), "offices", B)));

  // --- pipeline_items: own OK; cross-agent DENY ---
  await check("pipeline_items: agent A1 where advisorId==self", "PASS", () =>
    getDocs(query(collection(dbOf(AG_A1), "pipeline_items"), where("advisorId", "==", AG_A1), orderBy("updatedAt", "desc"), limit(100))));
  await check("pipeline_items: agent A1 where advisorId==B1 -> DENY", "FAIL", () =>
    getDocs(query(collection(dbOf(AG_A1), "pipeline_items"), where("advisorId", "==", AG_B1))));

  // --- notifications: own OK; other-user DENY ---
  await check("notifications: agent A1 where userId==self", "PASS", () =>
    getDocs(query(collection(dbOf(AG_A1), "notifications"), where("userId", "==", AG_A1), orderBy("createdAt", "desc"), limit(50))));
  await check("notifications: agent A1 where userId==B1 -> DENY", "FAIL", () =>
    getDocs(query(collection(dbOf(AG_A1), "notifications"), where("userId", "==", AG_B1))));

  // --- integration_listings / external_connections: owner OK; cross-owner DENY ---
  await check("integration_listings: agent A1 where ownerUserId==self", "PASS", () =>
    getDocs(query(collection(dbOf(AG_A1), "integration_listings"), where("ownerUserId", "==", AG_A1))));
  await check("integration_listings: agent A1 where ownerUserId==B1 -> DENY", "FAIL", () =>
    getDocs(query(collection(dbOf(AG_A1), "integration_listings"), where("ownerUserId", "==", AG_B1))));
  await check("external_connections: agent A1 where userId==self", "PASS", () =>
    getDocs(query(collection(dbOf(AG_A1), "external_connections"), where("userId", "==", AG_A1))));
  await check("external_connections: agent A1 where userId==B1 -> DENY", "FAIL", () =>
    getDocs(query(collection(dbOf(AG_A1), "external_connections"), where("userId", "==", AG_B1))));

  // --- audit_logs: manager OK; agent DENY ---
  await check("audit_logs: manager reads", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "audit_logs"), limit(10))));
  await check("audit_logs: agent reads -> DENY", "FAIL", () =>
    getDocs(query(collection(dbOf(AG_A1), "audit_logs"), limit(10))));

  // --- app_config: super OK; agent/manager DENY ---
  await check("app_config: super reads superAdminGate", "PASS", () =>
    getDoc(doc(dbOf(SUPER), "app_config", "superAdminGate")));
  await check("app_config: agent reads superAdminGate -> DENY", "FAIL", () =>
    getDoc(doc(dbOf(AG_A1), "app_config", "superAdminGate")));
  await check("app_config: manager reads superAdminGate -> DENY", "FAIL", () =>
    getDoc(doc(dbOf(MGRA), "app_config", "superAdminGate")));

  // --- listing_metrics: signed-in get OK (derived from public listings) ---
  await check("listing_metrics: agent reads single metric doc", "PASS", () =>
    getDoc(doc(dbOf(AG_A1), "listing_metrics", "lm_a1")));

  // --- undefined collection: locked by deny catch-all ---
  await check("undefined collection: any read -> DENY (catch-all deny)", "FAIL", () =>
    getDoc(doc(dbOf(MGRA), "totally_unknown_collection", "x")));

  // --- CRM transactional (intentionally signed-in-readable): legit shapes must NOT break ---
  console.log("\nREAD ISOLATION — CRM permissive (must NOT break app flows):");
  await check("customers: agent A1 where assignedAgentId==self", "PASS", () =>
    getDocs(query(collection(dbOf(AG_A1), "customers"), where("assignedAgentId", "==", AG_A1), orderBy("createdAt", "desc"), limit(40))));
  await check("customers: manager UNFILTERED (customersStream)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "customers"), limit(200))));
  await check("customers: manager office whereIn [a1,a2] (officeWideCustomersStream)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "customers"), where("assignedAgentId", "in", [AG_A1, AG_A2]))));
  await check("customers: manager recentLeads orderBy updatedAt", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "customers"), orderBy("updatedAt", "desc"), limit(25))));
  await check("calls: consultant A1 where advisorId==self (consultant stream)", "PASS", () =>
    getDocs(query(collection(dbOf(AG_A1), "calls"), where("advisorId", "==", AG_A1), orderBy("createdAt", "desc"), limit(60))));
  await check("calls: manager where officeId==A (Cagri Merkezi)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "calls"), where("officeId", "==", A), orderBy("createdAt", "desc"), limit(500))));
  await check("calls: manager UNFILTERED (War Room live count)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "calls"), orderBy("createdAt", "desc"), limit(500))));
  await check("calls: manager where customerId (customer detail)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "calls"), where("customerId", "==", "cust_a1"), orderBy("createdAt", "desc"), limit(25))));
  await check("notes: where customerId (customer timeline)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "notes"), where("customerId", "==", "cust_a1"), orderBy("createdAt", "desc"), limit(50))));
  await check("visits: where customerId", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "visits"), where("customerId", "==", "cust_a1"), orderBy("scheduledAt", "desc"), limit(50))));
  await check("offers: where customerId", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "offers"), where("customerId", "==", "cust_a1"), orderBy("createdAt", "desc"), limit(50))));
  await check("call_summaries: where customerId", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "call_summaries"), where("customerId", "==", "cust_a1"), orderBy("createdAt", "desc"), limit(50))));
  await check("deals: manager UNFILTERED count (dealsCountStream)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "deals"), limit(500))));
  await check("tasks: manager where done==false (openTasksCountStream)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "tasks"), where("done", "==", false), limit(100))));
  await check("teams: manager UNFILTERED list (teamsStream)", "PASS", () =>
    getDocs(query(collection(dbOf(MGRA), "teams"), limit(100))));
  await check("teams: agent reads single team (onboarding teamDocStream)", "PASS", () =>
    getDoc(doc(dbOf(AG_A1), "teams", "team_a1")));

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
