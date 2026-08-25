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
 * **`initializeApp()` runs eagerly at module top level; `getFirestore()`/
 * `getMessaging()` do not.** An earlier version made all three lazy,
 * guarded by `if (getApps().length === 0)` — that actually shipped and
 * broke every real invocation in production with "The default Firebase
 * app does not exist", confirmed via `firebase functions:log` against a
 * genuinely-triggered `onClanMessageCreated` call. `initializeApp()`
 * itself is cheap (no network I/O, just registers the app object) and is
 * exactly what Firebase's own function samples call unconditionally at
 * top level — it was never the slow part. The 10-second deploy-time
 * "User code failed to load" timeout this project hit earlier (see this
 * file's git history) was `getFirestore()`/`getMessaging()` themselves —
 * confirmed by keeping `initializeApp()` eager here while those two stay
 * deferred to be called fresh inside each handler.
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

function db() {
  return getFirestore();
}

function messaging() {
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
 * doomed-to-fail deliveries to it.
 *
 * `channelId`/`icon` default to the chat channel/bubble so the two
 * existing chat triggers below didn't need to change — `
 * onUserNotificationCreated` is the one caller that overrides both, to
 * the `app_notifications` channel and the app's own silhouette icon
 * (`ic_notification_app.png`), matching `FcmService`'s client-side
 * channel split exactly. */
async function sendToUid(uid, {
  title,
  body,
  data,
  channelId = "chat_messages",
  icon = "ic_notification",
}) {
  const tokens = await tokensFor(uid);
  if (tokens.length === 0) return;

  const response = await messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data,
    android: {
      priority: "high",
      notification: {channelId, icon},
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

/**
 * A leader's clan announcement, fanned out to every OTHER member as a
 * `users/{uid}/notifications` document — writing those documents is enough
 * on its own, since `onUserNotificationCreated` below already turns any
 * write to that collection into a real push; this function's only job is
 * the fan-out itself; it doesn't call `sendToUid` directly.
 *
 * Loops `clans/{code}/members` the same way `onClanMessageCreated` above
 * does, but has no per-recipient block check — `blockedClanUsers` exists so
 * a member can mute an abusive *peer*'s chat messages, not so they can opt
 * out of the clan leader's own official announcements, which is a
 * different trust relationship.
 */
exports.onClanAnnouncementCreated = onDocumentCreated(
    "clans/{code}/announcements/{announcementId}",
    async (event) => {
      const announcement = event.data.data();
      if (!announcement) return;
      const code = event.params.code;

      const clanSnap = await db().collection("clans").doc(code).get();
      const clanName = (clanSnap.data() || {}).name || "Clan";

      const membersSnap = await db().collection("clans").doc(code).collection("members").get();
      const recipientUids = membersSnap.docs
          .map((doc) => doc.id)
          .filter((uid) => uid !== announcement.authorUid);
      if (recipientUids.length === 0) return;

      const batch = db().batch();
      for (const uid of recipientUids) {
        const ref = db().collection("users").doc(uid).collection("notifications").doc();
        batch.set(ref, {
          category: "clanAnnouncement",
          title: clanName,
          body: `${announcement.authorName || DEFAULT_SENDER_NAME}: ${truncate(announcement.text)}`,
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    },
);

/**
 * The generic, non-chat delivery path — see `AppNotification`'s own doc
 * comment (Flutter side, `lib/data/models/app_notification.dart`) for why
 * this is a separate collection from the chat pipeline above. Any future
 * feature (streak reminder, achievement unlock, admin announcement, ...)
 * needs only to write a document to `users/{uid}/notifications` — from
 * this project's client via `NotificationRepository.create`, or from a
 * future server-side trigger of its own using the Admin SDK — and this
 * single function handles turning it into both a real push and an
 * in-app feed entry (the write itself already *is* the feed entry;
 * `NotificationScreen`/`myNotificationsProvider` read this same
 * collection directly).
 *
 * Deliberately `onDocumentCreated`, not `onDocumentWritten` — a later
 * `read: true` update (from `NotificationRepository.markRead`) must never
 * re-fire a push for something the learner has already seen.
 */
exports.onUserNotificationCreated = onDocumentCreated(
    "users/{uid}/notifications/{notificationId}",
    async (event) => {
      const notif = event.data.data();
      if (!notif) return;
      const uid = event.params.uid;

      await sendToUid(uid, {
        title: notif.title || "Teisou",
        body: truncate(notif.body),
        data: {
          type: "app",
          category: notif.category || "system",
          notificationId: event.params.notificationId,
        },
        channelId: "app_notifications",
        icon: "ic_notification_app",
      });
    },
);

// Card Game Mode's answer-scoring trigger — see battle_scoring.js for
// the implementation. Kept in its own file (unlike every trigger above)
// because it also bundles two real data files and a ported
// RomajiConverter, which would otherwise bloat this one considerably.
exports.onBattleAnswerCreated = require("./battle_scoring").onBattleAnswerCreated;

// Card Game Mode's bot opponent — see battle_bot.js. Fires whenever a
// battleMatches doc changes and it's the BOT sentinel's turn to answer;
// writes a bot answer, which onBattleAnswerCreated above then scores
// through the exact same pipeline as a human answer.
exports.onBattleMatchWritten = require("./battle_bot").onBattleMatchWritten;

// Card Game Mode's public matchmaking queue — see
// battle_matchmaking.js. Fires whenever a player joins
// matchmakingQueue/{tier}/{uid}; pairs them with another waiting
// player in the same tier if one exists, atomically, via a Realtime
// Database transaction.
exports.onMatchmakingQueueJoined =
  require("./battle_matchmaking").onMatchmakingQueueJoined;

// Card Game Mode's star ladder — see battle_stars.js. Fires whenever a
// battleMatches doc gains a `result`, and is the only writer anywhere of
// `users/{uid}.cardGameRank` (firestore.rules rejects client writes to
// it, so the ladder cannot be climbed by editing the document).
exports.onBattleMatchConcluded =
  require("./battle_stars").onBattleMatchConcluded;

// Turning a store purchase into an entitlement — the only writer of
// `subscription`, `entitlements` and (for a coin-pack purchase) `coins`,
// since firestore.rules refuses every client write to all three. See
// functions/iap.js.
exports.verifyPurchase = require("./iap").verifyPurchase;

// Keeps `subscription.tier` honest after the sale — a cancellation or a
// failed renewal that `verifyPurchase` (checked once, at purchase time)
// would never otherwise see. Needs Play Console's Real-time Developer
// Notifications pointed at this function's Pub/Sub topic before it
// receives anything real. See functions/subscription_notifications.js.
exports.onPlayRtdn =
  require("./subscription_notifications").onPlayRtdn;

// The other way to earn coins besides buying them: 1st-3rd on Skor
// Global, recalculated and paid out every Monday. See
// functions/award_top_coins.js.
exports.awardTopGlobalCoins =
  require("./award_top_coins").awardTopGlobalCoins;

// Spending coins on an avatar/frame/cover — the only writer of `coins`
// besides verifyPurchase and awardTopGlobalCoins, and the only writer of
// xp.unlockedAvatarIds/unlockedFrameIds/unlockedCoverIds that actually
// charges for it (a level-up reward writes the same fields straight from
// the client, since that path was never worth protecting — see
// functions/spend_coins.js's own doc comment for why a coin purchase is
// different). No firestore.rules change was needed for this: it runs
// with Admin SDK privileges, same as every other function here.
exports.spendCoins = require("./spend_coins").spendCoins;

// The rank-skip exam: two callables, one to draw the cards and one to
// grade them. Grading is server-side by necessity — see rank_skip.js.
exports.startRankSkipExam = require("./rank_skip").startRankSkipExam;
exports.submitRankSkipExam = require("./rank_skip").submitRankSkipExam;

// Global Points (Top Global leaderboard) — one trigger per exam-history
// collection, same registration shape as the four onDocumentCreated
// triggers above. `firestore.rules` refuses every client write to
// `leaderboard/{uid}.globalPoints`, so these four are its only writers.
// See global_points.js for the formula, repeat-key, and idempotency
// logic — this file only wires each collection's path to it.
const {globalPointsTriggerFor} = require("./global_points");
exports.onKanaExamHistoryCreated = globalPointsTriggerFor("kana");
exports.onDokkaiExamHistoryCreated = globalPointsTriggerFor("dokkai");
exports.onChoukaiExamHistoryCreated = globalPointsTriggerFor("choukai");
exports.onKanjiComboExamHistoryCreated = globalPointsTriggerFor("kanjiCombo");
