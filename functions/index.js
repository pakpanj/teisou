/**
 * Sends a push notification the moment a chat message is written to
 * Firestore — the server-side half of what the Flutter app's in-app
 * CountBadge system can't do on its own: notify a learner whose app is
 * closed or backgrounded. Two triggers, one per chat surface
 * (`directMessages/{conversationId}/messages` for personal chat,
 * `clans/{code}/messages` for clan chat), deliberately kept separate
 * rather than a single generic "message written somewhere" trigger,
 * since recipients are found completely differently for each (one other
 * participant vs. every clan member).
 *
 * Runs with Admin SDK privileges, so `firestore.rules` (which normally
 * keeps a `friendRequests`/`fcmTokens` subcollection readable only by
 * its owner) does not apply here — this is exactly the trusted,
 * server-side context those rules were written assuming would exist
 * once real push notifications were built.
 *
 * **`initializeApp()`/`getFirestore()`/`getMessaging()` are lazy on
 * purpose, not called at module top level.** `firebase-tools` loads this
 * file once at deploy time just to discover which functions it exports,
 * with a hard 10-second timeout on that load — eagerly calling them at
 * import time made the very first deploy attempt fail outright with
 * "User code failed to load ... Timeout after 10000", confirmed by
 * reproducing it locally (a bare `require('./index.js')` measurably took
 * longer than 10s with eager init, near-instant once deferred). This is
 * Firebase's own documented fix for exactly this failure, not a
 * workaround invented here — see the link in that error message.
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp, getApps} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

function ensureAppInitialized() {
  if (getApps().length === 0) {
    initializeApp();
  }
}

function db() {
  ensureAppInitialized();
  return getFirestore();
}

function messaging() {
  ensureAppInitialized();
  return getMessaging();
}

const MAX_PREVIEW_LENGTH = 80;
const DEFAULT_SENDER_NAME = "Pelajar Kana";

function truncate(text) {
  if (!text) return "";
  return text.length > MAX_PREVIEW_LENGTH ?
    `${text.slice(0, MAX_PREVIEW_LENGTH)}…` :
    text;
}

/** Every FCM token this uid's devices have registered — see `FcmService`
 * (Flutter side) for how `users/{uid}/fcmTokens/{token}` gets written.
 * A user with notifications never enabled, or who's uninstalled the app
 * without a token ever being cleaned up, simply has none — nothing to
 * send to, not an error. */
async function tokensFor(uid) {
  const snap = await db().collection("users").doc(uid).collection("fcmTokens").get();
  return snap.docs.map((doc) => doc.id);
}

/** Sends one notification to every token [uid] has registered, and
 * deletes whichever tokens FCM reports as no-longer-registered (the
 * device uninstalled the app, or the token rotated) — otherwise a stale
 * token list only grows, and every future send keeps paying for
 * doomed-to-fail deliveries to it. */
async function sendToUid(uid, {title, body, data}) {
  const tokens = await tokensFor(uid);
  if (tokens.length === 0) return;

  const response = await messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data,
    android: {
      priority: "high",
      notification: {channelId: "chat_messages"},
    },
  });

  const staleTokens = [];
  response.responses.forEach((result, index) => {
    const code = result.error && result.error.code;
    if (!result.success && code === "messaging/registration-token-not-registered") {
      staleTokens.push(tokens[index]);
    }
  });
  if (staleTokens.length > 0) {
    const batch = db().batch();
    const tokensRef = db().collection("users").doc(uid).collection("fcmTokens");
    for (const token of staleTokens) {
      batch.delete(tokensRef.doc(token));
    }
    await batch.commit();
  }
}

exports.onDirectMessageCreated = onDocumentCreated(
    "directMessages/{conversationId}/messages/{messageId}",
    async (event) => {
      const message = event.data.data();
      const conversationId = event.params.conversationId;

      const parentSnap = await db().collection("directMessages").doc(conversationId).get();
      const participants = (parentSnap.data() || {}).participants || [];
      const recipientUid = participants.find((uid) => uid !== message.senderUid);
      if (!recipientUid) return;

      await sendToUid(recipientUid, {
        title: message.senderName || DEFAULT_SENDER_NAME,
        body: truncate(message.text),
        data: {
          type: "dm",
          conversationId,
          friendUid: message.senderUid,
          friendName: message.senderName || "",
        },
      });
    },
);

exports.onClanMessageCreated = onDocumentCreated(
    "clans/{code}/messages/{messageId}",
    async (event) => {
      const message = event.data.data();
      const code = event.params.code;

      const clanSnap = await db().collection("clans").doc(code).get();
      const clanName = (clanSnap.data() || {}).name || "Clan";

      const membersSnap = await db().collection("clans").doc(code).collection("members").get();
      const recipientUids = membersSnap.docs
          .map((doc) => doc.id)
          .filter((uid) => uid !== message.senderUid);

      await Promise.all(recipientUids.map(async (uid) => {
        // Mirrors ClanMessageRepository's own client-side block feature:
        // a recipient who's blocked this sender should not get a push
        // for their message either, the same as they don't see it in
        // the chat itself.
        const blockedDoc = await db()
            .collection("users").doc(uid)
            .collection("blockedClanUsers").doc(message.senderUid)
            .get();
        if (blockedDoc.exists) return;

        await sendToUid(uid, {
          title: clanName,
          body: `${message.senderName || DEFAULT_SENDER_NAME}: ${truncate(message.text)}`,
          data: {
            type: "clan",
            code,
            clanName,
          },
        });
      }));
    },
);
