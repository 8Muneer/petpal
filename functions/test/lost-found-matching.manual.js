// Manual smoke test for the lost & found AI matching pipeline, specifically
// the embedding-based candidate ranking added to replace the exact-string
// pre-filter (see _rankCandidates in index.js). Not part of `npm test` (hence
// ".manual.js", excluded from the default suite) because it makes real
// network calls to the Gemini API (free tier) and to placedog.net for test
// images — run it deliberately with:
//   node test/lost-found-matching.manual.js
// from functions/, with the Firestore emulator running (npm run serve, or
// `firebase emulators:start --only firestore,functions` in another shell).
//
// Requires GEMINI_KEY in the environment or functions/.env.petpal-platform
// (already present locally) — the emulator loads it automatically.

process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.GCLOUD_PROJECT = 'petpal-platform';

// Plain `node` (unlike the Functions runtime) doesn't auto-load .env files —
// load GEMINI_KEY from it manually so this script can make real API calls.
if (!process.env.GEMINI_KEY) {
  const fs = require('fs');
  const path = require('path');
  const envPath = path.join(__dirname, '..', '.env.petpal-platform');
  if (fs.existsSync(envPath)) {
    for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
      const m = line.match(/^([A-Z_]+)=(.*)$/);
      if (m) process.env[m[1]] = m[2].trim();
    }
  }
}

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
    console.log('FAIL:', name, extra !== undefined ? JSON.stringify(extra) : '');
  }
}

const basePost = {
  reporterUid: 'tester',
  reporterName: 'Tester',
  petName: 'Rex',
  species: 'כלב',
  status: 'active',
  matchingStatus: 'pending',
  matches: [],
  createdAt: admin.firestore.Timestamp.now(),
};

async function main() {
  const db = admin.firestore();
  const col = db.collection('lost_found_posts');
  const wrapped = test.wrap(myFunctions.onLostFoundCreate);

  // Same dog photo (placedog.net id=10) reused for the "found" post and the
  // new "lost" post — a trivial true-positive: identical image, near-identical
  // text, so both the embedding ranking AND Gemini's vision call should agree.
  const foundRef = await col.add({
    ...basePost,
    type: 'found',
    breed: 'לברדור',
    color: 'שחור',
    area: 'תל אביב',
    description: 'כלב ידידותי עם רצועה כחולה, נמצא ליד הפארק',
    imageUrl: 'https://placedog.net/500/400?id=10',
  });

  // A different dog (different photo, different breed/colour/description) —
  // should rank low and, even if sent to Gemini, should not match.
  const decoyRef = await col.add({
    ...basePost,
    type: 'found',
    breed: 'פודל',
    color: 'לבן',
    area: 'חיפה',
    description: 'כלב ביישן, נראה מפוחד',
    imageUrl: 'https://placedog.net/500/400?id=25',
  });

  const lostData = {
    ...basePost,
    type: 'lost',
    breed: 'לברדור מעורב', // "labrador mix" — deliberately NOT an exact string
                            // match to "לברדור", to test that embedding
                            // similarity (not exact string equality) drives
                            // ranking.
    color: 'שחור',
    area: 'תל אביב',
    description: 'כלב חמוד עם רצועה כחולה, אבד ליד הפארק',
    imageUrl: 'https://placedog.net/500/400?id=10',
  };
  const lostRef = await col.add(lostData);
  const lostSnap = await lostRef.get();

  console.log('\n--- running onLostFoundCreate ---\n');
  await wrapped(lostSnap, { params: { docId: lostRef.id } });
  console.log('\n--- pipeline finished ---\n');

  const [lostAfter, foundAfter, decoyAfter] = await Promise.all([
    lostRef.get(), foundRef.get(), decoyRef.get(),
  ]);
  const lostData2 = lostAfter.data();
  const foundData2 = foundAfter.data();
  const decoyData2 = decoyAfter.data();

  report('matchingStatus reaches done', lostData2.matchingStatus === 'done', lostData2.matchingStatus);

  report('embedding cached on the new post',
    Array.isArray(lostData2.matchEmbedding) && lostData2.matchEmbedding.length > 0);
  report('embedding cached on the true-match candidate',
    Array.isArray(foundData2.matchEmbedding) && foundData2.matchEmbedding.length > 0);
  report('embedding cached on the decoy candidate',
    Array.isArray(decoyData2.matchEmbedding) && decoyData2.matchEmbedding.length > 0);

  const matchedIds = (lostData2.matches || []).map(m => m.postId);
  report('true-match candidate (same photo) is matched', matchedIds.includes(foundRef.id), matchedIds);

  const trueMatch = (lostData2.matches || []).find(m => m.postId === foundRef.id);
  if (trueMatch) {
    console.log(`   true-match confidence: ${trueMatch.confidence}, reason: ${trueMatch.reason}`);
    report('true-match confidence is above threshold (50)', trueMatch.confidence >= 50, trueMatch.confidence);
  }

  report('decoy candidate (different dog/photo) is NOT matched', !matchedIds.includes(decoyRef.id), matchedIds);

  console.log(`\n${pass} passed, ${fail} failed`);
  if (failures.length) console.log('Failed:', failures.join(', '));
  process.exit(fail > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error('FATAL', e);
  process.exit(1);
});
