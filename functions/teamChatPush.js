const functions = require("firebase-functions");
const admin = require("firebase-admin");

const MAX_BODY = 180;
const USER_FETCH_CHUNK = 20;

/**
 * offices/{officeId}/team_channels/{channelId}/messages/{messageId} oluşturulunca
 * alıcılara FCM gönderir (genel kanal: aktif üyeler, direkt: diğer katılımcı).
 */
async function collectRecipientUserIds(officeId, channelData, senderId) {
  const type = channelData.type;
  if (type === "direct") {
    const participants = channelData.participantIds || [];
    return participants.filter((uid) => uid && uid !== senderId);
  }

  const snap = await admin
    .firestore()
    .collection("office_memberships")
    .where("officeId", "==", officeId)
    .where("status", "==", "active")
    .get();

  const ids = [];
  for (const doc of snap.docs) {
    const uid = doc.data().userId;
    if (uid && uid !== senderId) ids.push(uid);
  }
  return ids;
}

async function fetchFcmTokens(userIds) {
  const tokens = new Set();
  for (let i = 0; i < userIds.length; i += USER_FETCH_CHUNK) {
    const chunk = userIds.slice(i, i + USER_FETCH_CHUNK);
    const refs = chunk.map((uid) => admin.firestore().collection("users").doc(uid));
    const snaps = await admin.firestore().getAll(...refs);
    for (const snap of snaps) {
      if (!snap.exists) continue;
      const token = snap.data().fcmToken;
      if (token && typeof token === "string" && token.length > 8) {
        tokens.add(token);
      }
    }
  }
  return [...tokens];
}

async function senderDisplayName(senderId) {
  const snap = await admin.firestore().collection("users").doc(senderId).get();
  if (!snap.exists) return "Ekip üyesi";
  const d = snap.data() || {};
  const name = (d.name || "").trim();
  if (name) return name;
  const email = (d.email || "").trim();
  if (email) return email;
  return "Ekip üyesi";
}

exports.onTeamChatMessageCreated = functions
  .region("europe-west1")
  .firestore.document("offices/{officeId}/team_channels/{channelId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const { officeId, channelId } = context.params;
    const msg = snap.data();
    if (!msg || !msg.senderId) return null;

    const senderId = msg.senderId;
    const text = String(msg.text || "").trim();
    if (!text) return null;

    const channelRef = admin
      .firestore()
      .collection("offices")
      .doc(officeId)
      .collection("team_channels")
      .doc(channelId);
    const channelSnap = await channelRef.get();
    if (!channelSnap.exists) return null;
    const channelData = channelSnap.data() || {};

    const recipientIds = await collectRecipientUserIds(
      officeId,
      channelData,
      senderId,
    );
    if (recipientIds.length === 0) return null;

    const tokens = await fetchFcmTokens(recipientIds);
    if (tokens.length === 0) {
      functions.logger.info("teamChatPush: no FCM tokens", { officeId, channelId });
      return null;
    }

    const senderName = await senderDisplayName(senderId);
    const isDirect = channelData.type === "direct";
    const channelTitle =
      (channelData.title || "").trim() ||
      (isDirect ? "Birebir sohbet" : "Genel sohbet");

    const notificationTitle = isDirect
      ? senderName
      : `${senderName} · ${channelTitle}`;
    const notificationBody =
      text.length > MAX_BODY ? `${text.slice(0, MAX_BODY - 1)}…` : text;

    const dataPayload = {
      type: "team_chat",
      officeId: String(officeId),
      channelId: String(channelId),
      title: isDirect ? senderName : channelTitle,
      subtitle: isDirect ? "Birebir" : "Ofis",
    };

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: dataPayload,
        android: { priority: "high" },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });
      functions.logger.info("teamChatPush sent", {
        officeId,
        channelId,
        success: response.successCount,
        failure: response.failureCount,
      });
    } catch (e) {
      functions.logger.error("teamChatPush failed", e);
    }

    return null;
  });
