const { setGlobalOptions } = require("firebase-functions");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
setGlobalOptions({ maxInstances: 10 });

const db = getFirestore();

// ── helper: جيب FCM token نتاع مستخدم ──
async function getUserToken(userId) {
  const doc = await db.collection("users").doc(userId).get();
  if (!doc.exists) return null;
  return doc.data()?.fcmToken ?? null;
}

// ── helper: ابعث إشعار ──
async function sendNotification(token, title, body) {
  if (!token) return;
  try {
    await getMessaging().send({
      token,
      notification: { title, body },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
          defaultSound: true,
        },
      },
    });
  } catch (e) {
    console.error("FCM error:", e);
  }
}

// ══════════════════════════════════════════════
// 1. إشعار جديد في Firestore → ابعثه FCM
// ══════════════════════════════════════════════
exports.onNewNotification = onDocumentCreated(
  "notifications/{notifId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { userId, title, message } = data;
    if (!userId) return;

    const token = await getUserToken(userId);
    await sendNotification(token, title ?? "AMS-DZ", message ?? "");
  }
);

// ══════════════════════════════════════════════
// 2. KYC — تغيير الحالة → إشعار للمنظم
// ══════════════════════════════════════════════
exports.onKycStatusChanged = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after  = event.data?.after?.data();
    if (!before || !after) return;

    // تغيير في kycStatus فقط
    if (before.kycStatus === after.kycStatus) return;
    if (after.role !== "organizer") return;

    const token = after.fcmToken;
    if (!token) return;

    if (after.kycStatus === "approved") {
      await sendNotification(
        token,
        "✅ تم قبول حسابك",
        "مبروك! يمكنك الآن إنشاء مزادات"
      );
    } else if (after.kycStatus === "rejected") {
      await sendNotification(
        token,
        "❌ تم رفض طلبك",
        `السبب: ${after.kycRejectionReason ?? "لم يُذكر سبب"}`
      );
    }
  }
);

// ══════════════════════════════════════════════
// 3. مزاد جديد → إشعار للأدمين
// ══════════════════════════════════════════════
exports.onAuctionSubmitted = onDocumentCreated(
  "auctions/{auctionId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.status !== "submitted") return;

    // جيب أول أدمين
    const adminsSnap = await db
      .collection("users")
      .where("role", "==", "admin")
      .limit(1)
      .get();

    if (adminsSnap.empty) return;
    const adminToken = adminsSnap.docs[0].data()?.fcmToken;
    if (!adminToken) return;

    await sendNotification(
      adminToken,
      "🆕 مزاد جديد للمراجعة",
      `"${data.title}" يحتاج موافقة`
    );
  }
);

// ══════════════════════════════════════════════
// 4. تغيير حالة المزاد → إشعار للمنظم
// ══════════════════════════════════════════════
exports.onAuctionStatusChanged = onDocumentUpdated(
  "auctions/{auctionId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after  = event.data?.after?.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    const organizerId = after.organizerId;
    if (!organizerId) return;

    const token = await getUserToken(organizerId);
    if (!token) return;

    switch (after.status) {
      case "approved":
        await sendNotification(
          token,
          "✅ تم قبول مزادك",
          `"${after.title}" تم قبوله وسيُنشر قريباً`
        );
        break;
      case "rejected":
        await sendNotification(
          token,
          "❌ تم رفض مزادك",
          `"${after.title}" — السبب: ${after.rejectionReason ?? "لم يُذكر"}`
        );
        break;
      case "active":
        await sendNotification(
          token,
          "🔥 مزادك نشط الآن",
          `"${after.title}" بدأ المزاد!`
        );
        break;
      case "ended":
        await sendNotification(
          token,
          "🏁 انتهى مزادك",
          `"${after.title}" انتهى بسعر ${after.currentPrice ?? 0} DZD`
        );
        break;
    }
  }
);

// ══════════════════════════════════════════════
// 5. مزايدة جديدة → إشعار للمنظم + المزايد السابق
// ══════════════════════════════════════════════
exports.onNewBid = onDocumentCreated(
  "bids/{bidId}",
  async (event) => {
    const bid = event.data?.data();
    if (!bid) return;

    const { auctionId, bidderId, amount } = bid;

    // جيب بيانات المزاد
    const auctionDoc = await db.collection("auctions").doc(auctionId).get();
    if (!auctionDoc.exists) return;
    const auction = auctionDoc.data();

    // إشعار للمنظم
    const sellerToken = await getUserToken(auction.organizerId);
    if (sellerToken && auction.organizerId !== bidderId) {
      await sendNotification(
        sellerToken,
        "📈 عرض جديد على مزادك",
        `${amount} DZD على "${auction.title}"`
      );
    }

    // جيب المزايد السابق
    const prevBidsSnap = await db
      .collection("bids")
      .where("auctionId", "==", auctionId)
      .where("bidderId", "!=", bidderId)
      .orderBy("bidderId")
      .orderBy("amount", "desc")
      .limit(1)
      .get();

    if (!prevBidsSnap.empty) {
      const prevBidderId = prevBidsSnap.docs[0].data().bidderId;
      const prevToken    = await getUserToken(prevBidderId);
      if (prevToken) {
        await sendNotification(
          prevToken,
          "💸 تم تجاوز عرضك",
          `شخص آخر قدّم ${amount} DZD في "${auction.title}"`
        );
      }
    }
  }
);

// ══════════════════════════════════════════════
// 6. طلب شحن رصيد → إشعار للأدمين
// ══════════════════════════════════════════════
exports.onDepositRequest = onDocumentCreated(
  "wallet_transactions/{txId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.status !== "pending") return;

    const adminsSnap = await db
      .collection("users")
      .where("role", "==", "admin")
      .limit(1)
      .get();

    if (adminsSnap.empty) return;
    const adminToken = adminsSnap.docs[0].data()?.fcmToken;
    if (!adminToken) return;

    const method = data.method === "ccp" ? "CCP" : "CIB";
    await sendNotification(
      adminToken,
      "💰 طلب شحن رصيد جديد",
      `${data.amount} DZD عبر ${method} — بانتظار الموافقة`
    );
  }
);

// ══════════════════════════════════════════════
// 7. موافقة على الشحن → إشعار للمستخدم
// ══════════════════════════════════════════════
exports.onDepositApproved = onDocumentUpdated(
  "wallet_transactions/{txId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after  = event.data?.after?.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "approved") return;

    const token = await getUserToken(after.userId);
    if (!token) return;

    await sendNotification(
      token,
      "✅ تم تأكيد شحن رصيدك",
      `تم إضافة ${after.amount} DZD لرصيدك`
    );
  }
);