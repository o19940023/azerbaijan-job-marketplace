const {setGlobalOptions} = require("firebase-functions/v2");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

setGlobalOptions({maxInstances: 10, region: "us-central1"});

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

async function sendPushToUser(userId, title, body, data = {}) {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) return;

  const token = userDoc.data().fcmToken;
  if (!token) return;

  const payloadData = {};
  Object.entries(data).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      payloadData[key] = String(value);
    }
  });

  await messaging.send({
    token,
    notification: {title, body},
    data: payloadData,
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      headers: {"apns-priority": "10"},
      payload: {
        aps: {
          sound: "default",
          contentAvailable: true,
        },
      },
    },
  });
}

exports.onNewChatMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const message = event.data && event.data.data();
  if (!message) return;

  const chatId = event.params.chatId;
  const senderId = message.senderId;
  const text = message.text || "Yeni mesaj";

  const chatDoc = await db.collection("chats").doc(chatId).get();
  if (!chatDoc.exists) return;

  const chat = chatDoc.data();
  const participants = Array.isArray(chat.participantIds) ? chat.participantIds : [];
  const recipientId = participants.find((id) => id !== senderId);
  if (!recipientId) return;

  const senderName = senderId === chat.employerId ? (chat.employerName || "İşTap") : (chat.jobSeekerName || "İşTap");
  await sendPushToUser(recipientId, senderName, text, {
    action: "chat",
    chatId,
    senderId,
    senderName,
  });
});

exports.onApplicationCreated = onDocumentCreated("applications/{applicationId}", async (event) => {
  const app = event.data && event.data.data();
  if (!app || !app.employerId) return;

  let applicantName = "Bir namizəd";
  if (app.applicantId) {
    const applicantDoc = await db.collection("users").doc(app.applicantId).get();
    if (applicantDoc.exists) {
      const userData = applicantDoc.data();
      applicantName = userData.fullName || userData.name || userData.email || applicantName;
    }
  }

  let jobTitle = "iş elanınıza";
  if (app.jobId) {
    const jobDoc = await db.collection("jobs").doc(app.jobId).get();
    if (jobDoc.exists) {
      jobTitle = jobDoc.data().title || jobTitle;
    }
  }

  await sendPushToUser(app.employerId, "Yeni Müraciət!", `${applicantName} "${jobTitle}" elanınıza müraciət etdi.`, {
    action: "application",
    applicationId: event.params.applicationId,
    jobId: app.jobId,
    applicantId: app.applicantId,
  });
});

// ---- STATUS DƏYİŞİKLİYİ: İş axtarana bildiriş ----

exports.onApplicationStatusChanged = onDocumentUpdated("applications/{applicationId}", async (event) => {
  const before = event.data && event.data.before.data();
  const after = event.data && event.data.after.data();
  if (!before || !after) return;

  if (before.status === after.status) return;
  if (after.status !== "accepted" && after.status !== "rejected") return;
  if (!after.applicantId) return;
  if (after.statusNotificationSent) return;

  let jobTitle = "müraciətiniz";
  if (after.jobId) {
    const jobDoc = await db.collection("jobs").doc(after.jobId).get();
    if (jobDoc.exists) {
      jobTitle = jobDoc.data().title || jobTitle;
    }
  }

  const title = after.status === "accepted" ? "Təbriklər! 🎉" : "Müraciət Nəticəsi";
  const body = after.status === "accepted"
    ? `"${jobTitle}" üçün müraciətiniz qəbul olundu!`
    : `"${jobTitle}" üçün müraciətiniz rədd edildi.`;

  await sendPushToUser(after.applicantId, title, body, {
    action: "application_status",
    applicationId: event.params.applicationId,
    jobId: after.jobId,
    status: after.status,
  });

  await event.data.after.ref.update({statusNotificationSent: true});
});
