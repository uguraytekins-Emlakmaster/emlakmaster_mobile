# Firestore Rules — Escalation-Proofing Tests

Faithful unit tests for `../firestore.rules` run against the Firestore emulator.
They replicate the real client write shapes (office creation, invite acceptance,
email-invite onboarding, self role-selection) and assert that every legitimate
flow succeeds while every privilege-escalation attempt fails closed.

## Run

```bash
cd test_rules
npm install                # once
# Java 17 compatible: a local firebase-tools@13 is used via node_modules/.bin
cd ..
test_rules/node_modules/.bin/firebase emulators:exec --only firestore --project emlak-master "node test_rules/run.js"
```

(The repo's globally installed `firebase` may require Java 21+. The pinned
local `firebase-tools@13` works with Java 17.)

## What is covered

LEGIT (must pass):
- self role-selection → `users` create as `agent`
- `createOfficeAsOwner` batch (office + owner membership + `users` role sync)
- code-invite accept (`joinOfficeWithInviteCode`): membership + `users` sync + invite increment
- email-invite → `users` create with a privileged role matching a pending `invites/{email}`

ESCALATION (must fail closed):
- self-create `users` with `broker_owner` / `super_admin` / `office_manager` (no invite)
- self-claim `owner` membership on an existing office created by someone else
- self-create `manager` membership without an invite / with a fake `inviteId`
- self-update own `users.role` to a privileged value

## Storage rules tests

`run_storage.js` tests `../storage.rules` against the Firestore **and** Storage
emulators together (the storage rules read `users/{uid}` and
`office_memberships/{uid}_{officeId}` from Firestore, so Firestore is seeded with
rules disabled first). Faithful to the real upload call sites:
`LogoStorageService` (`listing_display/`), `OfficeLogoStorageService`
(`offices/{officeId}/logo/`), avatar upload, and office import upload.

```bash
cd test_rules
npm install                # once
cd ..
test_rules/node_modules/.bin/firebase emulators:exec --only firestore,storage --project emlak-master "node test_rules/run_storage.js"
# or: cd test_rules && npm run test:storage
```

LEGIT (must pass): own-avatar upload/read/delete; any signed-in user reads any
avatar; office owner/admin/manager upload+delete office logo & imports;
super_admin manages office logo; super_admin / global broker_owner upload the
global `listing_display` showcase logo.

ESCALATION (must fail closed): upload to another user's avatar; non-member /
wrong-office / consultant uploads of office logo or imports; oversized or
wrong-content-type uploads; **cross-tenant `listing_display` write/delete by an
office_manager** (the hardened scope is super_admin / broker_owner only); writes
and reads on the catch-all path; legacy `users/{uid}/imports` writes.
