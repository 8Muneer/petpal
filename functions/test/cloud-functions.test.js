// Cloud Functions test suite for setUserRole (see
// final_presentation/auth_audit/, Phases 2 and 6). Run with
// `npm run test:functions` from functions/, or `npm test` for the full
// suite. Requires the Firestore + Auth emulators (both needed since this
// function writes to Firestore AND sets a custom claim via Admin Auth).
//
// CommonJS (not .mjs) to match firebase-functions-test's require()-based
// wrap() API, which calls the real, unmodified setUserRole export directly.

process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.GCLOUD_PROJECT = 'petpal-platform';

const test = require('firebase-functions-test')({ projectId: 'petpal-platform' });
const myFunctions = require('../index.js');
const admin = require('firebase-admin');

let pass = 0;
let fail = 0;
const failures = [];

function report(name, ok, extra) {
  if (ok) {
    pass++;
    console.log('PASS:', name);
  } else {
    fail++;
    failures.push(name);
    console.log('FAIL:', name, extra || '');
  }
}

async function main() {
  const db = admin.firestore();
  const wrapped = test.wrap(myFunctions.setUserRole);

  for (const uid of ['admin1', 'admin2', 'target', 'rando']) {
    await admin.auth().createUser({ uid });
  }
  await db.collection('users').doc('admin1').set({ role: 'admin', name: 'Admin One' });
  await db.collection('users').doc('admin2').set({ role: 'admin', name: 'Admin Two' });
  await db.collection('users').doc('target').set({ role: 'petOwner', name: 'Target' });
  await db.collection('users').doc('rando').set({ role: 'petOwner', name: 'Rando' });

  // ── Input validation & authorization ──────────────────────────────────────

  try {
    await wrapped({ targetUid: 'target', newRole: 'admin' }, { auth: { uid: 'rando' } });
    report('non-admin caller is denied', false);
  } catch (e) { report('non-admin caller is denied', e.code === 'permission-denied', e.code); }

  try {
    await wrapped({ targetUid: 'target', newRole: 'admin' }, {});
    report('unauthenticated call is denied', false);
  } catch (e) { report('unauthenticated call is denied', e.code === 'unauthenticated', e.code); }

  try {
    await wrapped({ targetUid: 'target', newRole: 'superuser' }, { auth: { uid: 'admin1' } });
    report('invalid role is rejected', false);
  } catch (e) { report('invalid role is rejected', e.code === 'invalid-argument', e.code); }

  try {
    await wrapped({ targetUid: 'ghost', newRole: 'admin' }, { auth: { uid: 'admin1' } });
    report('missing target is rejected', false);
  } catch (e) { report('missing target is rejected', e.code === 'not-found', e.code); }

  // ── Promotion: Firestore role + custom claim + audit log ───────────────────

  const promote = await wrapped({ targetUid: 'target', newRole: 'admin' }, { auth: { uid: 'admin1' } });
  report('promote succeeds', promote.success === true && promote.unchanged === false);

  const targetDoc = await db.collection('users').doc('target').get();
  report('target Firestore role is now admin', targetDoc.data().role === 'admin');

  const targetAuthUser = await admin.auth().getUser('target');
  report('target custom claim role is now admin', targetAuthUser.customClaims?.role === 'admin');

  const auditSnap = await db.collection('admin_audit')
    .where('targetUid', '==', 'target').where('newRole', '==', 'admin').get();
  report('audit log entry written for the promotion', auditSnap.size === 1);
  if (auditSnap.size === 1) {
    const entry = auditSnap.docs[0].data();
    report('audit log records correct actor and previous role',
      entry.actorUid === 'admin1' && entry.previousRole === 'petOwner');
  }

  // ── No-op (bootstrap-admin) path ────────────────────────────────────────────

  const noop = await wrapped({ targetUid: 'target', newRole: 'admin' }, { auth: { uid: 'admin1' } });
  report('setting the same role again returns unchanged', noop.unchanged === true);

  const auditSnap2 = await db.collection('admin_audit').where('targetUid', '==', 'target').get();
  report('no-op does not write a second audit entry', auditSnap2.size === 1);

  // ── Last-admin guard ─────────────────────────────────────────────────────

  const demote = await wrapped({ targetUid: 'target', newRole: 'petOwner' }, { auth: { uid: 'admin1' } });
  report('demoting an admin while others remain succeeds', demote.success === true);

  const targetAuthAfterDemote = await admin.auth().getUser('target');
  report('demotion updates the custom claim away from admin',
    targetAuthAfterDemote.customClaims?.role === 'petOwner');

  const demote2 = await wrapped({ targetUid: 'admin2', newRole: 'petOwner' }, { auth: { uid: 'admin1' } });
  report('demoting down to exactly one remaining admin succeeds', demote2.success === true);

  try {
    await wrapped({ targetUid: 'admin1', newRole: 'petOwner' }, { auth: { uid: 'admin1' } });
    report('demoting the last remaining admin is blocked', false);
  } catch (e) { report('demoting the last remaining admin is blocked', e.code === 'failed-precondition', e.code); }

  console.log(`\n${pass} passed, ${fail} failed`);
  if (failures.length) console.log('Failed:', failures.join(', '));
  process.exit(fail > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error('FATAL', e);
  process.exit(1);
});
