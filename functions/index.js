const {setGlobalOptions} = require("firebase-functions/v2");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const crypto = require("crypto");

setGlobalOptions({maxInstances: 10, region: "us-central1"});

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const EPOINT_PUBLIC_KEY = defineSecret("EPOINT_PUBLIC_KEY");
const EPOINT_PRIVATE_KEY = defineSecret("EPOINT_PRIVATE_KEY");

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

function buildEpointSignature(privateKey, dataBase64) {
  const s = `${privateKey}${dataBase64}${privateKey}`;
  return crypto.createHash("sha1").update(s).digest("base64");
}

function toBase64Json(obj) {
  return Buffer.from(JSON.stringify(obj)).toString("base64");
}

exports.createUrgentPayment = onRequest({secrets: [EPOINT_PUBLIC_KEY, EPOINT_PRIVATE_KEY]}, async (req, res) => {
  try {
    const publicKey = EPOINT_PUBLIC_KEY.value() || "";
    const privateKey = EPOINT_PRIVATE_KEY.value() || "";
    if (!publicKey || !privateKey) {
      res.status(500).json({error: "Epoint keys missing"});
      return;
    }

    const incomingBody = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    const {jobId, employerId, days} = req.method === "GET" ? req.query : incomingBody;
    const d = Number(days);
    if (!jobId || !employerId || !d || ![1, 5, 10].includes(d)) {
      res.status(400).json({error: "invalid_params"});
      return;
    }

    const amount = d === 1 ? 1 : d === 5 ? 3 : 5;
    const orderId = `urgent_${jobId}_${Date.now()}`;
    const otherAttr = [{key: "jobId", value: jobId}, {key: "employerId", value: employerId}, {key: "days", value: String(d)}];

    const dataPayload = {
      public_key: publicKey,
      amount,
      currency: "AZN",
      language: "az",
      order_id: orderId,
      description: `Təcili elan ${d} gün`,
      success_redirect_url: "https://istapapp.netlify.app/support.html",
      error_redirect_url: "https://istapapp.netlify.app/support.html",
      other_attr: otherAttr,
    };
    const dataBase64 = toBase64Json(dataPayload);
    const signature = buildEpointSignature(privateKey, dataBase64);

    const body = new URLSearchParams({data: dataBase64, signature}).toString();
    const resp = await fetch("https://epoint.az/api/1/request", {
      method: "POST",
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body,
    });
    const json = await resp.json().catch(() => ({}));
    if (!json || !json.redirect_url) {
      res.status(502).json({error: "epoint_error", response: json});
      return;
    }
    // Important: return order_id to client so it can confirm status reliably.
    res.json({
      redirect_url: json.redirect_url,
      transaction: json.transaction,
      order_id: orderId,
      status: json.status || "success",
    });
  } catch (e) {
    res.status(500).json({error: String(e)});
  }
});

exports.urgentPaymentCallback = onRequest({secrets: [EPOINT_PUBLIC_KEY, EPOINT_PRIVATE_KEY]}, async (req, res) => {
  try {
    const publicKey = EPOINT_PUBLIC_KEY.value() || "";
    const privateKey = EPOINT_PRIVATE_KEY.value() || "";
    if (!publicKey || !privateKey) {
      res.status(500).send("Epoint keys missing");
      return;
    }
    const incomingBody = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    const dataBase64 = (incomingBody && incomingBody.data) || (req.query && req.query.data) || "";
    const signature = (incomingBody && incomingBody.signature) || (req.query && req.query.signature) || "";
    if (!dataBase64 || !signature) {
      res.status(400).send("invalid");
      return;
    }
    const expectedSig = buildEpointSignature(privateKey, dataBase64);
    if (expectedSig !== signature) {
      res.status(403).send("forbidden");
      return;
    }
    const decoded = JSON.parse(Buffer.from(dataBase64, "base64").toString("utf8"));
    const status = (decoded && decoded.status) || "";
    const otherAttr = (decoded && decoded.other_attr) || [];
    const kv = {};
    if (Array.isArray(otherAttr)) {
      otherAttr.forEach((x) => {
        if (x && x.key) kv[x.key] = x.value;
      });
    }
    const jobId = kv.jobId;
    const days = Number(kv.days || 0);
    if (status === "success" && jobId && [1, 5, 10].includes(days)) {
      const until = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();
      await db.collection("jobs").doc(jobId).update({
        isUrgent: true,
        urgentUntil: until,
        urgentTransaction: (decoded && decoded.transaction) || "",
      }).catch(() => {});
    }
    res.status(200).send("ok");
  } catch (e) {
    res.status(500).send("error");
  }
});

exports.checkPaymentStatus = onRequest({secrets: [EPOINT_PUBLIC_KEY, EPOINT_PRIVATE_KEY]}, async (req, res) => {
  try {
    const publicKey = EPOINT_PUBLIC_KEY.value() || "";
    const privateKey = EPOINT_PRIVATE_KEY.value() || "";
    if (!publicKey || !privateKey) {
      res.status(500).json({error: "Epoint keys missing"});
      return;
    }

    const incomingBody = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    const {orderId, transaction} = req.method === "GET" ? req.query : incomingBody;

    if (!orderId && !transaction) {
      res.status(400).json({error: "missing_params"});
      return;
    }

    const dataPayload = {
      public_key: publicKey,
    };
    if (orderId) dataPayload.order_id = orderId;
    if (transaction) dataPayload.transaction = transaction;

    const dataBase64 = toBase64Json(dataPayload);
    const signature = buildEpointSignature(privateKey, dataBase64);

    const body = new URLSearchParams({data: dataBase64, signature}).toString();
    const resp = await fetch("https://epoint.az/api/1/get-status", {
      method: "POST",
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body,
    });

    const json = await resp.json().catch(() => ({}));
    res.json(json);
  } catch (e) {
    res.status(500).json({error: String(e)});
  }
});

// Manually confirm urgent payment after WebView reports "successRedirect".
// If Epoint status is still "new", we poll get-status for a short window.
// IMPORTANT: We only return ok=true (and mark job as urgent) when Epoint status is truly success/confirmed.
exports.manualConfirm = onRequest({secrets: [EPOINT_PUBLIC_KEY, EPOINT_PRIVATE_KEY]}, async (req, res) => {
  try {
    const publicKey = EPOINT_PUBLIC_KEY.value() || "";
    const privateKey = EPOINT_PRIVATE_KEY.value() || "";
    if (!publicKey || !privateKey) {
      res.status(500).json({error: "Epoint keys missing"});
      return;
    }

    const incomingBody = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    const {transaction, orderId, order_id, jobId, days} = incomingBody || {};

    const d = Number(days);
    const normalizedOrderId = orderId || order_id || "";
    if (!jobId || !transaction || !d || ![1, 5, 10].includes(d)) {
      res.status(400).json({ok: false, status: "invalid_params"});
      return;
    }

    const maxAttempts = 10; // was 3; increase to avoid premature autoreverse
    const delayMs = 2000;

    const pollOnce = async () => {
      const dataPayload = { public_key: publicKey };
      // get-status supports either order_id or transaction; we only have transaction on mobile.
      if (normalizedOrderId) dataPayload.order_id = normalizedOrderId;
      dataPayload.transaction = transaction;

      const dataBase64 = toBase64Json(dataPayload);
      const signature = buildEpointSignature(privateKey, dataBase64);
      const body = new URLSearchParams({data: dataBase64, signature}).toString();

      const resp = await fetch("https://epoint.az/api/1/get-status", {
        method: "POST",
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body,
      });
      const json = await resp.json().catch(() => ({}));

      return json;
    };

    const normalizeStatus = (json) => {
      const s =
        (json && (json.status || json.payment_status || json.state)) ||
        "";
      return String(s).toLowerCase();
    };

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      const json = await pollOnce();
      const status = normalizeStatus(json);

      // Log for debugging/traceability
      console.log(`====== MANUAL CONFIRM ATTEMPT ${attempt}/${maxAttempts} ======`);
      console.log(`transaction=${transaction}, jobId=${jobId}, status=${status || "unknown"}`);
      console.log(`raw=${JSON.stringify(json)}`);

      // Epoint can return different status strings; treat common ones as success.
      const isSuccess = ["success", "confirmed", "paid", "completed", "approved"].includes(status);
      if (isSuccess) {
        const until = new Date(Date.now() + d * 24 * 60 * 60 * 1000).toISOString();
        await db.collection("jobs").doc(jobId).update({
          isUrgent: true,
          urgentUntil: until,
          urgentTransaction: transaction || "",
        }).catch(() => {});

        res.status(200).json({ok: true, status: status || "success"});
        return;
      }

      // If it's already failed/autoreversed we can stop early.
      const isFailed = ["failed", "autoreversed", "reversed", "reversed_failed"].includes(status);
      if (isFailed) {
        res.status(200).json({ok: false, status: status || "failed"});
        return;
      }

      if (attempt < maxAttempts) {
        await new Promise((r) => setTimeout(r, delayMs));
      }
    }

    // Still not confirmed after polling window.
    res.status(200).json({ok: false, status: "not_confirmed"});
  } catch (e) {
    console.log("====== MANUAL CONFIRM ERROR ======");
    console.log(e);
    res.status(500).json({ok: false, status: "error", error: String(e)});
  }
});
