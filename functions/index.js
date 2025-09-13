const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Yeni mesaj oluşturulduğunda push notification gönder
 */
exports.onNewMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  try {
    const messageData = event.data.data();
    const {chatId, messageId} = event.params;

    logger.info(`New message created in chat ${chatId}: ${messageId}`);

    // Chat bilgilerini al
    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) {
      logger.error(`Chat ${chatId} not found`);
      return;
    }

    const chatData = chatDoc.data();
    const participants = chatData.participants || [];

    // Mesaj göndereni hariç tut
    const recipients = participants.filter((participantId) => participantId !== messageData.senderId);

    if (recipients.length === 0) {
      logger.info("No recipients found for the message");
      return;
    }

    // Her alıcı için notification gönder
    const notifications = recipients.map(async (recipientId) => {
      return sendNotificationToUser(recipientId, {
        title: messageData.senderName || "Yeni Mesaj",
        body: messageData.text || "Bir mesaj aldınız",
        type: "new_message",
        data: {
          chatId: chatId,
          messageId: messageId,
          senderId: messageData.senderId,
          actionUrl: `/chat/${chatId}`,
        },
      });
    });

    await Promise.all(notifications);
    logger.info(`Notifications sent for new message in chat ${chatId}`);
  } catch (error) {
    logger.error("Error sending new message notification:", error);
  }
});

/**
 * Yeni etkinlik davetiyesi oluşturulduğunda push notification gönder
 */
exports.onEventInvitation = onDocumentCreated("events/{eventId}/invitations/{invitationId}", async (event) => {
  try {
    const invitationData = event.data.data();
    const {eventId, invitationId} = event.params;

    logger.info(`New event invitation created: ${invitationId} for event ${eventId}`);

    // Etkinlik bilgilerini al
    const eventDoc = await db.collection("events").doc(eventId).get();
    if (!eventDoc.exists) {
      logger.error(`Event ${eventId} not found`);
      return;
    }

    const eventData = eventDoc.data();

    await sendNotificationToUser(invitationData.inviteeId, {
      title: "Etkinlik Davetiyesi",
      body: `${eventData.title} etkinliğine davet edildiniz`,
      type: "event_invitation",
      data: {
        eventId: eventId,
        invitationId: invitationId,
        inviterId: invitationData.inviterId,
        actionUrl: `/event/${eventId}`,
      },
    });

    logger.info(`Event invitation notification sent to ${invitationData.inviteeId}`);
  } catch (error) {
    logger.error("Error sending event invitation notification:", error);
  }
});

/**
 * Yeni rozet kazanıldığında push notification gönder
 */
exports.onBadgeEarned = onDocumentCreated("users/{userId}/badges/{badgeId}", async (event) => {
  try {
    const badgeData = event.data.data();
    const {userId, badgeId} = event.params;

    logger.info(`New badge earned: ${badgeId} by user ${userId}`);

    // Badge bilgilerini al
    const badgeDoc = await db.collection("badges").doc(badgeId).get();
    if (!badgeDoc.exists) {
      logger.error(`Badge ${badgeId} not found`);
      return;
    }

    const badgeInfo = badgeDoc.data();

    await sendNotificationToUser(userId, {
      title: "🏆 Yeni Rozet Kazandınız!",
      body: `"${badgeInfo.name}" rozetini kazandınız`,
      type: "badge_earned",
      data: {
        badgeId: badgeId,
        badgeName: badgeInfo.name,
        actionUrl: "/profile",
      },
    });

    logger.info(`Badge earned notification sent to ${userId}`);
  } catch (error) {
    logger.error("Error sending badge earned notification:", error);
  }
});

/**
 * Arkadaşlık isteği oluşturulduğunda push notification gönder
 */
exports.onFriendRequest = onDocumentCreated("friendRequests/{requestId}", async (event) => {
  try {
    const requestData = event.data.data();
    const {requestId} = event.params;

    logger.info(`New friend request created: ${requestId}`);

    // İstek gönderen kullanıcının bilgilerini al
    const requesterDoc = await db.collection("users").doc(requestData.fromUserId).get();
    if (!requesterDoc.exists) {
      logger.error(`Requester ${requestData.fromUserId} not found`);
      return;
    }

    const requesterData = requesterDoc.data();

    await sendNotificationToUser(requestData.toUserId, {
      title: "Arkadaşlık İsteği",
      body: `${requesterData.displayName || "Birisi"} size arkadaşlık isteği gönderdi`,
      type: "friend_request",
      data: {
        requestId: requestId,
        requesterId: requestData.fromUserId,
        requesterName: requesterData.displayName,
        actionUrl: "/friend-requests",
      },
    });

    logger.info(`Friend request notification sent to ${requestData.toUserId}`);
  } catch (error) {
    logger.error("Error sending friend request notification:", error);
  }
});

/**
 * Etkinlik güncellendiğinde katılımcılara push notification gönder
 */
exports.onEventUpdate = onDocumentUpdated("events/{eventId}", async (event) => {
  try {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const {eventId} = event.params;

    // Önemli alanların değişip değişmediğini kontrol et
    const importantFields = ["title", "description", "datetime", "location"];
    const hasImportantUpdate = importantFields.some(
        (field) => beforeData[field] !== afterData[field],
    );

    if (!hasImportantUpdate) {
      logger.info(`No important updates for event ${eventId}`);
      return;
    }

    logger.info(`Event ${eventId} has important updates`);

    // Etkinlik katılımcılarını al
    const participantsSnapshot = await db
        .collection("events")
        .doc(eventId)
        .collection("participants")
        .where("status", "==", "accepted")
        .get();

    if (participantsSnapshot.empty) {
      logger.info(`No participants found for event ${eventId}`);
      return;
    }

    // Her katılımcıya notification gönder
    const notifications = participantsSnapshot.docs.map(async (participantDoc) => {
      const participantData = participantDoc.data();
      return sendNotificationToUser(participantData.userId, {
        title: "Etkinlik Güncelleme",
        body: `"${afterData.title}" etkinliğinde güncelleme yapıldı`,
        type: "event_update",
        data: {
          eventId: eventId,
          updateType: "event_details",
          actionUrl: `/event/${eventId}`,
        },
      });
    });

    await Promise.all(notifications);
    logger.info(`Event update notifications sent for event ${eventId}`);
  } catch (error) {
    logger.error("Error sending event update notification:", error);
  }
});

/**
 * Sistem duyurusu gönderme endpoint'i
 */
exports.sendSystemAnnouncement = onRequest(async (req, res) => {
  try {
    // Sadece POST isteklerini kabul et
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    const {title, body, targetUsers, data} = req.body;

    if (!title || !body) {
      res.status(400).json({error: "Title and body are required"});
      return;
    }

    // Hedef kullanıcıları belirle
    let recipients = [];
    if (targetUsers && Array.isArray(targetUsers)) {
      recipients = targetUsers;
    } else {
      // Tüm kullanıcılara gönder
      const usersSnapshot = await db.collection("users").get();
      recipients = usersSnapshot.docs.map((doc) => doc.id);
    }

    logger.info(`Sending system announcement to ${recipients.length} users`);

    // Her kullanıcıya notification gönder
    const notifications = recipients.map(async (userId) => {
      return sendNotificationToUser(userId, {
        title: title,
        body: body,
        type: "system_announcement",
        data: data || {},
      });
    });

    await Promise.all(notifications);

    res.status(200).json({
      success: true,
      message: `System announcement sent to ${recipients.length} users`,
    });
  } catch (error) {
    logger.error("Error sending system announcement:", error);
    res.status(500).json({error: "Internal server error"});
  }
});

/**
 * Kullanıcıya push notification gönder
 * @param {string} userId - Hedef kullanıcı ID
 * @param {object} notificationData - Notification içeriği
 * @return {Promise} Notification gönderme sonucu
 */
async function sendNotificationToUser(userId, notificationData) {
  try {
    // Kullanıcının FCM token'ını al
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      logger.error(`User ${userId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      logger.warn(`No FCM token found for user ${userId}`);
      return;
    }

    // Kullanıcının bildirim ayarlarını kontrol et
    const notificationSettings = userData.notificationSettings || {};
    if (!notificationSettings.enabled) {
      logger.info(`Notifications disabled for user ${userId}`);
      return;
    }

    // Belirli bildirim türünü kontrol et
    const typeEnabled = notificationSettings[notificationData.type];
    if (typeEnabled === false) {
      logger.info(`Notification type ${notificationData.type} disabled for user ${userId}`);
      return;
    }

    // FCM mesajını oluştur
    const message = {
      token: fcmToken,
      notification: {
        title: notificationData.title,
        body: notificationData.body,
      },
      data: {
        type: notificationData.type,
        ...notificationData.data,
      },
      android: {
        notification: {
          channelId: "linkup_high_importance",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notificationData.title,
              body: notificationData.body,
            },
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    // Notification gönder
    const response = await messaging.send(message);
    logger.info(`Notification sent successfully to ${userId}: ${response}`);

    // Firestore'a notification kaydını ekle
    await db
        .collection("users")
        .doc(userId)
        .collection("notifications")
        .add({
          id: response,
          title: notificationData.title,
          body: notificationData.body,
          type: notificationData.type,
          data: notificationData.data,
          timestamp: new Date(),
          isRead: false,
          imageUrl: notificationData.imageUrl || null,
          actionUrl: notificationData.actionUrl || null,
        });

    return response;
  } catch (error) {
    logger.error(`Error sending notification to user ${userId}:`, error);

    // Invalid token hatası durumunda token'ı temizle
    if (error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered") {
      await db.collection("users").doc(userId).update({
        fcmToken: null,
      });
      logger.info(`Removed invalid FCM token for user ${userId}`);
    }

    throw error;
  }
}

/**
 * Test notification endpoint'i
 */
exports.sendTestNotification = onRequest(async (req, res) => {
  try {
    const {userId} = req.body;

    if (!userId) {
      res.status(400).json({error: "User ID is required"});
      return;
    }

    await sendNotificationToUser(userId, {
      title: "Test Bildirimi",
      body: "Bu bir test bildirimidir. Sistem düzgün çalışıyor!",
      type: "system_announcement",
      data: {
        test: true,
      },
    });

    res.status(200).json({
      success: true,
      message: "Test notification sent successfully",
    });
  } catch (error) {
    logger.error("Error sending test notification:", error);
    res.status(500).json({error: "Internal server error"});
  }
});