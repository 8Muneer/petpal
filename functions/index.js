const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
//  Lost & Found — constants
// ─────────────────────────────────────────────────────────────────────────────

/** Single source of truth for match threshold — used everywhere (auto + manual). */
const MATCH_THRESHOLD = 50;

/** How many days back to search for opposite-type posts. */
const CANDIDATE_WINDOW_DAYS = 120;

/** Max candidates fetched from Firestore before pre-filtering. */
const FETCH_LIMIT = 20;

/** Max candidates sent to Gemini after attribute pre-scoring. */
const GEMINI_CANDIDATE_LIMIT = 8;

/** Max Gemini calls running at the same time. */
const MAX_CONCURRENT = 3;

/** Max retry attempts per Gemini call on 429 / 5xx. */
const MAX_RETRIES = 3;

// ─────────────────────────────────────────────────────────────────────────────
//  Booking notifications (server-side, Blaze)
//
//  Notifications for the booking lifecycle are written here, on Firestore
//  triggers, instead of client-side. This makes them reliable: they fire even
//  if the app that made the change is killed mid-write, and they can't be
//  forged by a client. The document schema matches what the app's
//  AppNotificationModel.fromFirestore expects (see app_notification_model.dart).
// ─────────────────────────────────────────────────────────────────────────────

/** Writes a single notification document, matching the app's schema. */
async function writeNotification(db, { userId, title, body, type, bookingId }) {
  if (!userId) return;
  await db.collection('notifications').add({
    userId,
    title,
    body,
    type,
    isRead: false,
    data: { bookingId },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** New booking request → tell the provider. */
exports.onBookingCreate = functions.firestore
  .document('booking_requests/{bookingId}')
  .onCreate(async (snap, context) => {
    const d = snap.data() || {};
    if (d.isMock === true) return null; // don't notify for seeded demo data
    const ownerName = d.ownerName || 'משתמש';
    await writeNotification(admin.firestore(), {
      userId: d.providerUid,
      title: 'בקשת הזמנה חדשה',
      body: `${ownerName} שלח/ה אליך בקשת הזמנה`,
      type: 'bookingNew',
      bookingId: context.params.bookingId,
    });
    return null;
  });

/** Booking status change → tell the other party the right thing. */
exports.onBookingStatusChange = functions.firestore
  .document('booking_requests/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (after.isMock === true) return null;
    if (before.status === after.status) return null; // only act on status moves

    const db = admin.firestore();
    const bookingId = context.params.bookingId;
    const ownerUid = after.ownerUid;
    const providerUid = after.providerUid;
    const ownerName = after.ownerName || 'בעל החיות';
    const providerName = after.providerName || 'הנותן שירות';
    const prev = before.status;
    const next = after.status;

    let n = null;
    if (next === 'accepted' && prev === 'pending') {
      n = {
        userId: ownerUid,
        title: 'הזמנה אושרה',
        body: `${providerName} אישר/ה את ההזמנה שלך`,
        type: 'bookingAccepted',
      };
    } else if (next === 'accepted' && prev === 'awaitingConfirmation') {
      // owner disputed the provider's completion request
      n = {
        userId: providerUid,
        title: 'השירות טרם הושלם',
        body: `${ownerName} ציין/ה שהשירות עדיין לא בוצע`,
        type: 'bookingCompletionDisputed',
      };
    } else if (next === 'awaitingConfirmation') {
      n = {
        userId: ownerUid,
        title: 'אישור סיום שירות',
        body: `${providerName} סימן/ה שהשירות הושלם. אשר/י כדי לדרג את החוויה`,
        type: 'bookingCompletionRequested',
      };
    } else if (next === 'completed') {
      n = {
        userId: providerUid,
        title: 'השירות אושר',
        body: `${ownerName} אישר/ה שהשירות הושלם`,
        type: 'bookingCompleted',
      };
    } else if (next === 'declined') {
      n = {
        userId: ownerUid,
        title: 'הזמנה נדחתה',
        body: `${providerName} דחה/תה את ההזמנה שלך`,
        type: 'bookingDeclined',
      };
    } else if (next === 'cancelled') {
      // Firestore triggers don't carry the identity of who made the write,
      // so the client stamps `cancelledBy` (validated by firestore.rules to
      // match the actual auth.uid's role) and we use it to notify whichever
      // party didn't do the cancelling.
      n = after.cancelledBy === 'provider'
        ? {
            userId: ownerUid,
            title: 'הזמנה בוטלה',
            body: `${providerName} ביטל/ה את ההזמנה`,
            type: 'bookingCancelled',
          }
        : {
            userId: providerUid,
            title: 'הזמנה בוטלה',
            body: `${ownerName} ביטל/ה את ההזמנה`,
            type: 'bookingCancelled',
          };
    }

    if (n) await writeNotification(db, { ...n, bookingId });
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
//  Review rating aggregation (server-side, Blaze)
//
//  The provider's ratingAverage/reviewCount (on their /users doc and on every
//  walk_services/sitting_services listing they own) used to be recomputed by
//  the client inside a Firestore transaction. That required the security rules
//  to allow any authenticated client to PATCH those aggregate fields directly,
//  which meant any signed-in user could overwrite a provider's rating without
//  ever writing a review. Recomputing here — where only the Admin SDK (which
//  bypasses rules) can write the aggregates — closes that hole; the client now
//  only ever writes the `reviews/{bookingId}` document itself.
// ─────────────────────────────────────────────────────────────────────────────
exports.onReviewWrite = functions.firestore
  .document('reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return null; // review deletes don't affect aggregates here
    if (after.isMock === true) return null;

    const providerId = after.providerId;
    if (!providerId) return null;

    const before = change.before.exists ? change.before.data() : null;
    const isNew = !before;
    const oldRating = before ? Number(before.rating) : null;
    const newRating = Number(after.rating);

    // Rating unchanged (e.g. a comment-only edit) — nothing to recompute.
    if (!isNew && oldRating === newRating) return null;

    const db = admin.firestore();
    const providerRef = db.collection('users').doc(providerId);

    const [sittingServicesQuery, walkServicesQuery] = await Promise.all([
      db.collection('sitting_services').where('providerUid', '==', providerId).get(),
      db.collection('walk_services').where('providerUid', '==', providerId).get(),
    ]);

    await db.runTransaction(async (transaction) => {
      const providerSnap = await transaction.get(providerRef);
      const providerData = providerSnap.data() || {};
      const currentAvg = Number(providerData.ratingAverage) || 0;
      const currentCount = Number(providerData.reviewCount) || 0;

      let newAvg;
      let newCount;
      if (isNew) {
        newCount = currentCount + 1;
        newAvg = (currentAvg * currentCount + newRating) / newCount;
        transaction.set(providerRef, { ratingAverage: newAvg, reviewCount: newCount }, { merge: true });
      } else {
        newCount = currentCount;
        newAvg = currentCount > 0
          ? (currentAvg * currentCount - oldRating + newRating) / currentCount
          : newRating;
        transaction.set(providerRef, { ratingAverage: newAvg }, { merge: true });
      }

      for (const doc of [...sittingServicesQuery.docs, ...walkServicesQuery.docs]) {
        transaction.update(doc.ref, { rating: newAvg, reviewCount: newCount });
      }
    });

    if (isNew) {
      await writeNotification(db, {
        userId: providerId,
        title: 'חוות דעת חדשה',
        body: `קיבלת חוות דעת עם דירוג ${newRating} כוכבים`,
        type: 'newReview',
        bookingId: after.bookingId,
      });
    }
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
//  Chat push notifications (server-side, Blaze)
//
//  The client (notification_service.dart) has always registered each device's
//  FCM token on login and kept it fresh on token refresh — but nothing ever
//  sent a push through those tokens. A new message only ever produced an
//  in-app `notifications` doc, invisible while the app is closed or
//  backgrounded. This trigger is the missing other half: it reads the
//  recipient's registered tokens and actually sends the push, the same way
//  onReviewWrite owns the review notification.
// ─────────────────────────────────────────────────────────────────────────────
exports.onMessageCreate = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const msg = snap.data() || {};
    // Context cards (offer-sheet previews) carry no human-readable text and
    // never drive the in-app notification either — nothing to push.
    if (msg.type === 'context' || !msg.text) return null;

    const db = admin.firestore();
    const conversationId = context.params.conversationId;
    const convoSnap = await db.collection('conversations').doc(conversationId).get();
    const convo = convoSnap.data();
    if (!convo) return null;

    const participants = convo.participants || [];
    const recipientId = participants.find((uid) => uid !== msg.senderId);
    if (!recipientId) return null;

    const recipientSnap = await db.collection('users').doc(recipientId).get();
    const tokens = recipientSnap.data()?.fcmTokens || [];
    if (tokens.length === 0) return null;

    const senderName = msg.senderName || 'משתמש';
    const body = msg.text.length > 80 ? `${msg.text.slice(0, 80)}…` : msg.text;

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: senderName, body },
      // `otherName` is what NotificationShell/_navigateTo read to label the chat
      // header on tap — from the recipient's side, the sender is the "other"
      // person. Without it, tapping a push opened the chat with a blank name.
      data: { type: 'newMessage', conversationId, otherName: senderName },
    });

    // Prune tokens FCM reports as dead (uninstalled app, expired registration)
    // so they stop being retried on every future message.
    const deadTokens = [];
    response.responses.forEach((r, i) => {
      const code = r.error?.code;
      if (code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered') {
        deadTokens.push(tokens[i]);
      }
    });
    if (deadTokens.length > 0) {
      await db.collection('users').doc(recipientId).update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...deadTokens),
      });
    }
    return null;
  });

/**
 * Triggered when a post document is deleted.
 * Cleans up all comments in the nested subcollection in chunks of 100 docs.
 */
exports.onPostDelete = functions.firestore
  .document('posts/{postId}')
  .onDelete(async (snap, context) => {
    const postId = context.params.postId;
    const db = admin.firestore();
    const commentsRef = db.collection('posts').doc(postId).collection('comments');

    const batchSize = 100;
    return new Promise((resolve, reject) => {
      deleteCollectionBatch(db, commentsRef.limit(batchSize), resolve).catch(reject);
    });
  });

async function deleteCollectionBatch(db, query, resolve) {
  const snapshot = await query.get();

  if (snapshot.size === 0) {
    resolve();
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  // Recursively process next batch using nextTick
  process.nextTick(() => {
    deleteCollectionBatch(db, query, resolve);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Lost & Found AI Matching (server-side, Blaze)
//
//  onLostFoundCreate   — Firestore trigger, fires for every new post.
//  rerunLostFoundMatching — Callable, lets the owner request a fresh run.
//  compareLostFoundPair   — Callable, powers the manual AI Compare screen.
//
//  The Gemini key lives in Firebase secret GEMINI_KEY and is never shipped in
//  the client binary.  Set it once:
//    firebase functions:secrets:set GEMINI_KEY
// ─────────────────────────────────────────────────────────────────────────────

/** Auto-matching: fires whenever a new lost_found_post document is created. */
exports.onLostFoundCreate = functions
  .runWith({})
  .firestore.document('lost_found_posts/{docId}')
  .onCreate(async (snap, context) => {
    const docId = context.params.docId;
    const post = snap.data() || {};

    if (post.isMock === true) return null;
    if (!post.imageUrl) {
      await _setMatchingStatus(docId, 'done');
      return null;
    }

    await _setMatchingStatus(docId, 'searching');

    try {
      await _runMatchingPipeline(docId, post, process.env.GEMINI_KEY);
      await _setMatchingStatus(docId, 'done');
    } catch (err) {
      console.error('[LostFound] onLostFoundCreate failed for', docId, err);
      await _setMatchingStatus(docId, 'pending');
    }

    return null;
  });

/** Re-run callable: owner calls this to retry matching on an existing post. */
exports.rerunLostFoundMatching = functions
  .runWith({})
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');

    const postId = data && data.postId;
    if (!postId) throw new functions.https.HttpsError('invalid-argument', 'postId is required.');

    const db = admin.firestore();
    const snap = await db.collection('lost_found_posts').doc(postId).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'Post not found.');

    const post = snap.data();
    if (post.reporterUid !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Only the reporter can re-run matching.');
    }
    if (!post.imageUrl) throw new functions.https.HttpsError('failed-precondition', 'Post has no image.');

    // Clear stale matches from previous run
    await db.collection('lost_found_posts').doc(postId).update({
      matches: [],
      matchingStatus: 'searching',
    });

    try {
      await _runMatchingPipeline(postId, post, process.env.GEMINI_KEY);
      await _setMatchingStatus(postId, 'done');
    } catch (err) {
      console.error('[LostFound] rerun failed for', postId, err);
      await _setMatchingStatus(postId, 'pending');
      throw new functions.https.HttpsError('internal', 'Matching failed, please try again.');
    }

    return { success: true };
  });

/** Manual compare callable: powers the AI Compare screen for any two posts. */
exports.compareLostFoundPair = functions
  .runWith({})
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');

    const { postId1, postId2 } = data || {};
    if (!postId1 || !postId2) {
      throw new functions.https.HttpsError('invalid-argument', 'postId1 and postId2 are required.');
    }

    const db = admin.firestore();
    const [snap1, snap2] = await Promise.all([
      db.collection('lost_found_posts').doc(postId1).get(),
      db.collection('lost_found_posts').doc(postId2).get(),
    ]);

    if (!snap1.exists || !snap2.exists) {
      throw new functions.https.HttpsError('not-found', 'One or both posts not found.');
    }

    const post1 = snap1.data();
    const post2 = snap2.data();

    if (!post1.imageUrl || !post2.imageUrl) {
      throw new functions.https.HttpsError('failed-precondition', 'Both posts must have images.');
    }

    const result = await _callGemini(post1.imageUrl, post2.imageUrl, process.env.GEMINI_KEY);
    if (!result) throw new functions.https.HttpsError('internal', 'Gemini comparison failed.');

    return {
      isMatch: result.confidence >= MATCH_THRESHOLD,
      confidence: result.confidence,
      reason: result.reason,
      comparisonTable: result.comparisonTable,
    };
  });

/** Updates matchingStatus on a lost_found_posts document. */
async function _setMatchingStatus(docId, status) {
  await admin.firestore().collection('lost_found_posts').doc(docId).update({ matchingStatus: status });
}

/**
 * Full matching pipeline:
 *  1. Fetch opposite-type candidates (Phase 2)
 *  2. Attribute pre-score & trim to top GEMINI_CANDIDATE_LIMIT (Phase 2)
 *  3. Call Gemini for each with concurrency cap (Phase 3)
 *  4. Write bidirectional matches sorted by confidence (Phase 4)
 */
async function _runMatchingPipeline(postId, post, geminiKey) {
  const db = admin.firestore();

  // ── Phase 2: candidate retrieval ──────────────────────────────────────────
  const candidates = await _fetchCandidates(db, post);
  console.log(`[LostFound] ${postId}: ${candidates.length} raw candidates`);

  const ranked = _preScoreCandidates(post, candidates);
  const top = ranked.slice(0, GEMINI_CANDIDATE_LIMIT);
  console.log(`[LostFound] ${postId}: ${top.length} candidates sent to Gemini`);

  // ── Phase 3: Gemini calls with concurrency cap ────────────────────────────
  const matchResults = await _compareAll(postId, post, top, geminiKey);
  console.log(`[LostFound] ${postId}: ${matchResults.length} matches above threshold`);

  // ── Phase 4: write bidirectional matches, sorted by confidence ────────────
  if (matchResults.length > 0) {
    matchResults.sort((a, b) => b.confidence - a.confidence);
    await _writeMatches(db, postId, post, matchResults);
  }
}

/**
 * Fetches opposite-type, same-species, active posts within CANDIDATE_WINDOW_DAYS.
 * Sorted newest-first so .limit(FETCH_LIMIT) gives the most recent candidates
 * (fixes the B1 bug where the oldest 20 were being compared).
 */
async function _fetchCandidates(db, post) {
  const oppositeType = post.type === 'lost' ? 'found' : 'lost';
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - CANDIDATE_WINDOW_DAYS);

  const snap = await db.collection('lost_found_posts')
    .where('type', '==', oppositeType)
    .where('species', '==', post.species)
    .where('status', '==', 'active')
    .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(cutoff))
    .orderBy('createdAt', 'desc')
    .limit(FETCH_LIMIT)
    .get();

  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

/**
 * Cheap attribute pre-filter — scores each candidate 0-4 on species/breed/
 * color/area overlap so only the most promising get a Gemini call.
 */
function _preScoreCandidates(post, candidates) {
  return candidates
    .filter(c => c.imageUrl)
    .map(c => {
      let score = 0;
      if (c.species && post.species && c.species === post.species) score++;
      if (c.breed && post.breed && c.breed.trim().toLowerCase() === post.breed.trim().toLowerCase()) score++;
      if (c.color && post.color && c.color.trim().toLowerCase() === post.color.trim().toLowerCase()) score++;
      if (c.area && post.area && c.area.trim().toLowerCase() === post.area.trim().toLowerCase()) score++;
      if (c.size && post.size && c.size === post.size) score++;
      return { ...c, _preScore: score };
    })
    .sort((a, b) => b._preScore - a._preScore);
}

/**
 * Runs Gemini comparisons with MAX_CONCURRENT concurrency cap.
 * Returns only results that meet MATCH_THRESHOLD.
 */
async function _compareAll(postId, post, candidates, geminiKey) {
  const results = [];

  for (let i = 0; i < candidates.length; i += MAX_CONCURRENT) {
    const batch = candidates.slice(i, i + MAX_CONCURRENT);
    const batchResults = await Promise.all(
      batch.map(async candidate => {
        const geminiResult = await _callGemini(post.imageUrl, candidate.imageUrl, geminiKey);
        if (!geminiResult) return null;
        if (geminiResult.confidence < MATCH_THRESHOLD) return null;
        return { candidate, geminiResult };
      })
    );
    for (const r of batchResults) {
      if (r) results.push(r);
    }
  }

  return results;
}

/**
 * Calls Gemini 2.5 Flash with JSON mode + responseSchema.
 * Retries up to MAX_RETRIES times on 429 / 5xx with exponential backoff.
 * Returns null on total failure (candidate is silently skipped — caller decides).
 */
async function _callGemini(imageUrl1, imageUrl2, geminiKey) {
  const endpoint =
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiKey}`;

  const [bytes1, bytes2] = await Promise.all([
    _downloadImageBase64(imageUrl1),
    _downloadImageBase64(imageUrl2),
  ]);
  if (!bytes1 || !bytes2) return null;

  const body = JSON.stringify({
    contents: [{
      parts: [
        { text: _buildPrompt() },
        { inline_data: { mime_type: _mimeFromUrl(imageUrl1), data: bytes1 } },
        { inline_data: { mime_type: _mimeFromUrl(imageUrl2), data: bytes2 } },
      ],
    }],
    generationConfig: {
      temperature: 0.1,
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'OBJECT',
        properties: {
          confidence: { type: 'INTEGER' },
          reason:     { type: 'STRING'  },
          comparisonTable: {
            type: 'ARRAY',
            items: {
              type: 'OBJECT',
              properties: {
                featureName: { type: 'STRING' },
                pet1Value:   { type: 'STRING' },
                pet2Value:   { type: 'STRING' },
                status:      { type: 'STRING', enum: ['MATCH', 'MISMATCH', 'CANNOT_DETERMINE'] },
              },
              required: ['featureName', 'pet1Value', 'pet2Value', 'status'],
            },
          },
        },
        required: ['confidence', 'reason', 'comparisonTable'],
      },
    },
  });

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body,
        signal: AbortSignal.timeout(90_000),
      });

      if (res.status === 429 || res.status >= 500) {
        const delay = Math.pow(2, attempt) * 1000;
        console.warn(`[Gemini] ${res.status} on attempt ${attempt}, retrying in ${delay}ms`);
        await _sleep(delay);
        continue;
      }

      if (!res.ok) {
        console.error('[Gemini] API error', res.status, await res.text());
        return null;
      }

      const decoded = await res.json();
      const text = decoded?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!text) return null;

      const parsed = JSON.parse(text);
      return {
        confidence: parsed.confidence ?? 0,
        reason: parsed.reason ?? '',
        comparisonTable: parsed.comparisonTable ?? [],
      };
    } catch (err) {
      if (attempt === MAX_RETRIES) {
        console.error('[Gemini] All retries exhausted:', err);
        return null;
      }
      await _sleep(Math.pow(2, attempt) * 1000);
    }
  }
  return null;
}

/**
 * Recalibrated prompt — balanced between the original "forensic skeptic" (which
 * capped valid same-pet matches at ≤25) and a loose similarity scorer.
 * Same-species + same-colour + same-area → 50-65.
 * Clear individual identifiers (unique patch, scar, collar) → 70-90.
 * Confirmed different animal (visible mismatch in unique feature) → 0-30.
 * All Hebrew text fields in the JSON.
 */
function _buildPrompt() {
  return `You are a veterinary photo analyst helping reunite lost pets with their owners.
Your task: decide whether Photo 1 and Photo 2 show the SAME individual animal.

SCORING GUIDE — assign a confidence integer (0-100):
- 85-100 : Strong individual match — same unique markings, scars, collar, or patch shapes clearly visible and matching.
- 65-84  : Likely same animal — most individual features align; minor angle/quality differences explain small gaps.
- 50-64  : Possible match — same species/breed/colour/area, individual features not fully visible but nothing contradicts.
- 30-49  : Weak match — same general type but no individual-level evidence confirmed.
- 0-29   : Not a match — same breed/colour but a unique feature visible in one photo is absent or different in the other.

RULES:
- Same breed + same colour alone = 35-45. Individual evidence must push it higher.
- A unique marker present in Photo 1 but clearly absent (not just hidden) in Photo 2 = drop to 0-30.
- Low photo quality or awkward angle: do NOT penalise heavily — score what you CAN see.
- "reason" must be in Hebrew and must name the specific feature(s) that drove the score up or down.
- All text fields (featureName, pet1Value, pet2Value, reason) MUST be in Hebrew.
- "status" must be exactly one of: MATCH, MISMATCH, CANNOT_DETERMINE.

Compare these 5 categories in the comparisonTable:
1. סוג וגזע (Species & Breed)
2. צבע ודוגמת פרווה (Colour & Coat Pattern)
3. מבנה פנים וראש (Face & Head — eyes, ears, nose, facial markings)
4. סימנים מיוחדים (Unique markings, scars, patches, ear notches)
5. אביזרים (Accessories — collar, harness, tag)`;
}

/**
 * Writes match results bidirectionally using Admin SDK batch writes.
 * The reporter perspective is swapped for the candidate's document
 * (pet1Value ↔ pet2Value) so each post sees itself as "pet 1".
 */
async function _writeMatches(db, postId, post, matchResults) {
  for (const { candidate, geminiResult } of matchResults) {
    const matchForPost = {
      postId: candidate.id,
      imageUrl: candidate.imageUrl || '',
      reporterName: candidate.reporterName || '',
      confidence: geminiResult.confidence,
      reason: geminiResult.reason,
      features: geminiResult.comparisonTable,
    };

    const matchForCandidate = {
      postId: postId,
      imageUrl: post.imageUrl || '',
      reporterName: post.reporterName || '',
      confidence: geminiResult.confidence,
      reason: geminiResult.reason,
      // Swap perspective: pet1Value and pet2Value are from candidate's viewpoint
      features: geminiResult.comparisonTable.map(f => ({
        featureName: f.featureName,
        pet1Value: f.pet2Value,
        pet2Value: f.pet1Value,
        status: f.status,
      })),
    };

    await Promise.all([
      _addMatchDeduped(db, postId, matchForPost),
      _addMatchDeduped(db, candidate.id, matchForCandidate),
    ]);

    console.log(`[LostFound] Match saved: ${postId} ↔ ${candidate.id} (${geminiResult.confidence}%)`);
  }
}

/**
 * Adds a match entry to a post's matches array, deduplicating by postId.
 * Uses a Firestore transaction — same pattern as the original client-side addMatch.
 */
async function _addMatchDeduped(db, targetPostId, matchData) {
  const docRef = db.collection('lost_found_posts').doc(targetPostId);
  await db.runTransaction(async tx => {
    const snap = await tx.get(docRef);
    if (!snap.exists) return;
    const existing = snap.data().matches || [];
    const filtered = existing.filter(m => m.postId !== matchData.postId);
    filtered.push(matchData);
    tx.update(docRef, { matches: filtered });
  });
}

/** Downloads an image and returns it as a base64 string, or null on failure. */
async function _downloadImageBase64(url) {
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    if (!res.ok) {
      console.warn('[LostFound] Image download failed', res.status, url);
      return null;
    }
    const buffer = await res.arrayBuffer();
    return Buffer.from(buffer).toString('base64');
  } catch (err) {
    console.warn('[LostFound] Image download error:', err.message, url);
    return null;
  }
}

/** Infers MIME type from a URL. Falls back to image/jpeg (covers Firebase Storage URLs). */
function _mimeFromUrl(url) {
  const path = url.split('?')[0].toLowerCase();
  if (path.endsWith('.png'))  return 'image/png';
  if (path.endsWith('.webp')) return 'image/webp';
  if (path.endsWith('.gif'))  return 'image/gif';
  return 'image/jpeg';
}

function _sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ─────────────────────────────────────────────────────────────────────────────
//  Admin — role assignment (server-side, Blaze)
//
//  Promoting/revoking admin must never be a direct client write to
//  /users/{uid}.role — firestore.rules deliberately excludes `role` from the
//  admin-update branch so this function is the only path. That buys us two
//  things a raw client write can't: a guard against locking the app out of
//  its own admin tooling by demoting the last admin, and an audit trail of
//  who changed whose role and when.
// ─────────────────────────────────────────────────────────────────────────────

const ASSIGNABLE_ROLES = ['petOwner', 'serviceProvider', 'admin'];

exports.setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }

  const targetUid = data && data.targetUid;
  const newRole = data && data.newRole;
  if (!targetUid || !ASSIGNABLE_ROLES.includes(newRole)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'targetUid and a valid newRole are required.'
    );
  }

  const db = admin.firestore();
  const callerRef = db.collection('users').doc(context.auth.uid);
  const callerSnap = await callerRef.get();
  if (callerSnap.data()?.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only an admin can change a user\'s role.'
    );
  }

  const targetRef = db.collection('users').doc(targetUid);
  const targetSnap = await targetRef.get();
  if (!targetSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Target user not found.');
  }
  const previousRole = targetSnap.data()?.role || null;

  if (previousRole === newRole) {
    // Still (re-)set the custom claim even on a no-op Firestore change — this
    // is what lets the very first bootstrapped admin (role: 'admin' already
    // set by hand in Firestore/console, but never granted the claim) pick up
    // `request.auth.token.role` by calling this once on themselves.
    await admin.auth().setCustomUserClaims(targetUid, { role: newRole });
    return { success: true, unchanged: true };
  }

  // Demoting the last admin would lock everyone out of admin tooling —
  // including the ability to promote a new admin back in.
  if (previousRole === 'admin' && newRole !== 'admin') {
    const adminCountSnap = await db.collection('users')
      .where('role', '==', 'admin')
      .count()
      .get();
    if ((adminCountSnap.data().count || 0) <= 1) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Cannot remove the last remaining admin.'
      );
    }
  }

  await targetRef.update({ role: newRole, userType: newRole });

  // Custom claims back the storage.rules poi_images admin check — Storage
  // rules can't query Firestore the way Firestore rules' isAdmin() can, so
  // the role has to be mirrored onto the auth token itself. Note: this only
  // takes effect on the target's NEXT ID token refresh (new sign-in, or an
  // explicit getIdToken(true)) — Firebase Auth doesn't push claim changes to
  // already-issued tokens.
  await admin.auth().setCustomUserClaims(targetUid, { role: newRole });

  await db.collection('admin_audit').add({
    actorUid: context.auth.uid,
    actorName: callerSnap.data()?.name || null,
    targetUid,
    targetName: targetSnap.data()?.name || null,
    previousRole,
    newRole,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, unchanged: false };
});

// ─────────────────────────────────────────────────────────────────────────────
//  Demo seeding — mock admins (server-side, Blaze)
//
//  firestore.rules blocks role:'admin' on every client create, including
//  isMock writes — no client write can self-promote to admin, by design. This
//  callable is the seed-data equivalent: it uses the Admin SDK to write a
//  small, fixed set of mock admin docs at hardcoded seed_admin_N ids, so demo
//  data can include admin accounts without weakening that rule. It never
//  touches the caller's own uid or any arbitrary uid, and these doc ids don't
//  correspond to any real Firebase Auth account — so this grants no one
//  real admin access (the app's actual admin gate is the caller's own
//  /users/{request.auth.uid}.role, checked by isAdmin() and mirrored onto the
//  auth token by setUserRole). It only produces mock rows for the admin user
//  directory to display.
// ─────────────────────────────────────────────────────────────────────────────

exports.seedMockAdmins = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }

  const admins = data && Array.isArray(data.admins) ? data.admins : [];
  if (admins.length === 0 || admins.length > 10) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Provide 1-10 admin profiles.'
    );
  }

  const db = admin.firestore();
  const batch = db.batch();
  admins.forEach((profile, i) => {
    const uid = `seed_admin_${i}`;
    batch.set(db.collection('users').doc(uid), {
      uid,
      name: profile.name || `Admin ${i}`,
      email: `admin${i}@demo.petpal.com`,
      phone: profile.phone || null,
      location: profile.location || null,
      bio: profile.bio || null,
      role: 'admin',
      userType: 'admin',
      isVerified: true,
      isMock: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();

  return { success: true, count: admins.length };
});
