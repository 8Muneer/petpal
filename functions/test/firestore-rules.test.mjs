// Firestore rules test suite for the auth/admin audit (see
// final_presentation/auth_audit/). Run with `npm run test:rules` from
// functions/, or `npm test` to run the full suite (rules + storage +
// functions). Requires the Firestore + Auth emulators, started
// automatically by `firebase emulators:exec` per the npm script.
//
// Covers: users (privilege-escalation guard), admin_audit, and the
// verification_requests/reports regression fixed in Phase 6b.

import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import {
  setDoc, doc, updateDoc, getDoc, getDocs, collection, query, where,
} from 'firebase/firestore';

const testEnv = await initializeTestEnvironment({
  projectId: 'petpal-platform',
  firestore: { rules: readFileSync('firestore.rules', 'utf8') },
});

let pass = 0;
let fail = 0;
const failures = [];

async function check(name, fn) {
  try {
    await fn();
    pass++;
    console.log('PASS:', name);
  } catch (e) {
    fail++;
    failures.push(name);
    console.log('FAIL:', name, '—', e.message);
  }
}

// ── users: privilege escalation guard (Phase 1) ─────────────────────────────

await check('self-create own doc with role petOwner is allowed', async () => {
  const db = testEnv.authenticatedContext('bob').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/bob'), { role: 'petOwner', name: 'Bob' }));
});

await check('self-create own doc with role admin is denied', async () => {
  const db = testEnv.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice'), { role: 'admin', name: 'Alice' }));
});

await check('isMock-branch create with role admin is denied', async () => {
  const db = testEnv.authenticatedContext('eve').firestore();
  await assertFails(setDoc(doc(db, 'users/someoneElse'), { role: 'admin', isMock: true }));
});

await check('isMock-branch create by a NON-admin is denied (seeding is admin-only now)', async () => {
  const db = testEnv.authenticatedContext('seeder').firestore();
  await assertFails(setDoc(doc(db, 'users/mockUser1'), { role: 'serviceProvider', isMock: true }));
});

await testEnv.withSecurityRulesDisabled(async (context) => {
  const db = context.firestore();
  await setDoc(doc(db, 'users/admin1'), { role: 'admin', name: 'Admin' });
  await setDoc(doc(db, 'users/target1'), { role: 'petOwner', name: 'Target', isActive: true });
});

await check('isMock-branch create by an ADMIN is allowed (seed_service.dart runs as admin)', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/mockUser1'), { role: 'serviceProvider', isMock: true }));
});

await check('admin updates another user\'s isActive (moderation)', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/target1'), { isActive: false }));
});

await check('admin direct role write to another user\'s doc is denied (must use setUserRole)', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertFails(updateDoc(doc(db, 'users/target1'), { role: 'admin' }));
});

await check('non-admin updating another user\'s isActive is denied', async () => {
  const db = testEnv.authenticatedContext('rando').firestore();
  await assertFails(updateDoc(doc(db, 'users/target1'), { isActive: true }));
});

await check('self update own non-restricted field is allowed', async () => {
  const db = testEnv.authenticatedContext('bob').firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/bob'), { name: 'Bob Updated' }));
});

await check('self role-escalation via update is still denied', async () => {
  const db = testEnv.authenticatedContext('bob').firestore();
  await assertFails(updateDoc(doc(db, 'users/bob'), { role: 'admin' }));
});

// ── admin_audit (Phase 2): admin-readable, never client-writable ───────────

await testEnv.withSecurityRulesDisabled(async (context) => {
  await setDoc(doc(context.firestore(), 'admin_audit/entry1'), {
    actorUid: 'admin1', targetUid: 'target1', previousRole: 'petOwner', newRole: 'admin',
  });
});

await check('admin can read admin_audit', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(getDoc(doc(db, 'admin_audit/entry1')));
});

await check('non-admin cannot read admin_audit', async () => {
  const db = testEnv.authenticatedContext('rando').firestore();
  await assertFails(getDoc(doc(db, 'admin_audit/entry1')));
});

await check('no client (not even admin) can write admin_audit directly', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertFails(setDoc(doc(db, 'admin_audit/entry2'), { actorUid: 'admin1' }));
});

// ── verification_requests (Phase 6b regression fix) ─────────────────────────

await testEnv.withSecurityRulesDisabled(async (context) => {
  await setDoc(doc(context.firestore(), 'verification_requests/v1'), { userId: 'owner1', status: 'pending' });
});

await check('user creates own verification_request', async () => {
  const db = testEnv.authenticatedContext('owner1').firestore();
  await assertSucceeds(setDoc(doc(db, 'verification_requests/v2'), { userId: 'owner1', status: 'pending' }));
});

await check('user reads own verification_request', async () => {
  const db = testEnv.authenticatedContext('owner1').firestore();
  await assertSucceeds(getDoc(doc(db, 'verification_requests/v1')));
});

await check('non-owner non-admin cannot read someone else\'s verification_request', async () => {
  const db = testEnv.authenticatedContext('rando').firestore();
  await assertFails(getDoc(doc(db, 'verification_requests/v1')));
});

await check('admin reads any verification_request', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(getDoc(doc(db, 'verification_requests/v1')));
});

await check('admin updates verification_request status', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(updateDoc(doc(db, 'verification_requests/v1'), { status: 'approved', reviewedBy: 'admin1' }));
});

// ── reports / content moderation (Phase 6b regression fix) ──────────────────

await testEnv.withSecurityRulesDisabled(async (context) => {
  await setDoc(doc(context.firestore(), 'reports/r1'), { reporterId: 'owner1', status: 'open' });
});

await check('user creates own report', async () => {
  const db = testEnv.authenticatedContext('owner1').firestore();
  await assertSucceeds(setDoc(doc(db, 'reports/r2'), { reporterId: 'owner1', status: 'open' }));
});

await check('user cannot create a report claiming someone else as reporter', async () => {
  const db = testEnv.authenticatedContext('rando').firestore();
  await assertFails(setDoc(doc(db, 'reports/r3'), { reporterId: 'someoneElse', status: 'open' }));
});

await check('non-admin (even the reporter) cannot read reports', async () => {
  const db = testEnv.authenticatedContext('owner1').firestore();
  await assertFails(getDoc(doc(db, 'reports/r1')));
});

await check('admin queries open reports', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(getDocs(query(collection(db, 'reports'), where('status', '==', 'open'))));
});

await check('admin resolves a report', async () => {
  const db = testEnv.authenticatedContext('admin1').firestore();
  await assertSucceeds(updateDoc(doc(db, 'reports/r1'), { status: 'resolved', resolvedBy: 'admin1' }));
});

// ── walk/sitting requests: owner-only updates (pre-judging hardening) ───────

await testEnv.withSecurityRulesDisabled(async (context) => {
  const db = context.firestore();
  await setDoc(doc(db, 'walk_requests/w1'), { ownerUid: 'owner1', status: 'open', budget: 50 });
  await setDoc(doc(db, 'sitting_requests/s1'), { ownerUid: 'owner1', status: 'open' });
});

await check('owner updates their own walk_request', async () => {
  const db = testEnv.authenticatedContext('owner1').firestore();
  await assertSucceeds(updateDoc(doc(db, 'walk_requests/w1'), { status: 'closed' }));
});

await check('stranger cannot update someone else\'s walk_request', async () => {
  const db = testEnv.authenticatedContext('rando').firestore();
  await assertFails(updateDoc(doc(db, 'walk_requests/w1'), { budget: 1 }));
});

await check('stranger cannot update someone else\'s sitting_request', async () => {
  const db = testEnv.authenticatedContext('rando').firestore();
  await assertFails(updateDoc(doc(db, 'sitting_requests/s1'), { status: 'closed' }));
});

// ── posts: interaction branch is an allow-list (likes/commentCount only) ────

await testEnv.withSecurityRulesDisabled(async (context) => {
  await setDoc(doc(context.firestore(), 'posts/p1'), {
    authorUid: 'owner1', content: 'hello', type: 'text', likes: [], commentCount: 0,
  });
});

await check('non-author can like a post (likes only)', async () => {
  const db = testEnv.authenticatedContext('rando').firestore();
  await assertSucceeds(updateDoc(doc(db, 'posts/p1'), { likes: ['rando'] }));
});

await check('non-author cannot tamper with other post fields', async () => {
  const db = testEnv.authenticatedContext('rando').firestore();
  await assertFails(updateDoc(doc(db, 'posts/p1'), { likes: ['rando'], imageUrls: ['x'] }));
});

await check('author can still edit their own post content', async () => {
  const db = testEnv.authenticatedContext('owner1').firestore();
  await assertSucceeds(updateDoc(doc(db, 'posts/p1'), { content: 'edited' }));
});

console.log(`\n${pass} passed, ${fail} failed`);
if (failures.length) console.log('Failed:', failures.join(', '));
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
