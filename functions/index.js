const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

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
