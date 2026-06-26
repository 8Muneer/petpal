// Storage rules test suite for the auth/admin audit (see
// final_presentation/auth_audit/, Phase 6). Run with `npm run test:storage`
// from functions/, or `npm test` for the full suite.
//
// Covers the poi_images custom-claim fix found by the Phase 6 security
// review: writes must check request.auth.token.role == 'admin', not just
// "is signed in" — Storage rules can't query Firestore the way isAdmin()
// does in firestore.rules, so the role has to live on the auth token.

import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { ref, uploadBytes } from 'firebase/storage';

const testEnv = await initializeTestEnvironment({
  projectId: 'petpal-platform',
  storage: { rules: readFileSync('storage.rules', 'utf8') },
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

const data = new Uint8Array([1, 2, 3]);

await check('non-admin (no custom claim) cannot write poi_images', async () => {
  const storage = testEnv.authenticatedContext('rando', {}).storage();
  await assertFails(uploadBytes(ref(storage, 'poi_images/test.jpg'), data));
});

await check('admin (role claim) can write poi_images', async () => {
  const storage = testEnv.authenticatedContext('admin1', { role: 'admin' }).storage();
  await assertSucceeds(uploadBytes(ref(storage, 'poi_images/test.jpg'), data));
});

await check('serviceProvider claim is still denied (checks claim VALUE, not just presence)', async () => {
  const storage = testEnv.authenticatedContext('provider1', { role: 'serviceProvider' }).storage();
  await assertFails(uploadBytes(ref(storage, 'poi_images/test2.jpg'), data));
});

await check('any authenticated user can still read poi_images', async () => {
  const storage = testEnv.authenticatedContext('rando2', {}).storage();
  await assertSucceeds(uploadBytes(ref(storage, 'profile_images/rando2'), data));
});

await check('a user can write their own profile_images (regression sanity)', async () => {
  const storage = testEnv.authenticatedContext('owner1', {}).storage();
  await assertSucceeds(uploadBytes(ref(storage, 'profile_images/owner1'), data));
});

await check('a user cannot write someone else\'s profile_images', async () => {
  const storage = testEnv.authenticatedContext('owner1', {}).storage();
  await assertFails(uploadBytes(ref(storage, 'profile_images/owner2'), data));
});

console.log(`\n${pass} passed, ${fail} failed`);
if (failures.length) console.log('Failed:', failures.join(', '));
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
