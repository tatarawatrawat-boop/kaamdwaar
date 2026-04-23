const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendHireNotification = onDocumentCreated(
  "hire_requests/{requestId}",
  async (event) => {
    const data = event.data.data();

    const workerId = data.workerId;

    const userDoc = await admin.firestore()
      .collection("users")
      .doc(workerId)
      .get();

    if (!userDoc.exists) return;

    const token = userDoc.data().fcmToken;

    if (!token) return;

    await admin.messaging().send({
      token: token,
      notification: {
        title: "New Hire Request",
        body: "Someone wants to hire you"
      },
      data: {
        type: "hire_request"
      }
    });
  }
);