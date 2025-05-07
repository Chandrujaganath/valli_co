// functions/index.js

// Import v2 HTTPS callable function
const { onCall } = require("firebase-functions/v2/https");
// Import the v2 Firestore trigger helper
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

const functions = require("firebase-functions"); // (for error types, etc.)
const admin = require("firebase-admin");
admin.initializeApp();

// ===================================================================
// 1. Callable Function: createUser
// ===================================================================

exports.createUser = onCall(
  {
    enforceAppCheck: true, // Reject requests with missing or invalid App Check tokens.
    // You can specify region, timeoutSeconds, memory, etc.
  },
  async (request) => {
    console.log("createUser called");
    console.log("request.auth:", request.auth);
    console.log("request.app:", request.app);

    // Ensure the user is authenticated and is an admin
    if (!request.auth) {
      console.error("Unauthenticated access attempt.");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated."
      );
    }

    // Verify App Check token
    if (!request.app) {
      console.error("App Check failed.");
      throw new functions.https.HttpsError(
        "failed-precondition",
        "App Check token is missing or invalid."
      );
    }

    const uid = request.auth.uid;
    console.log("Authenticated user ID:", uid);

    // Fetch the user's document to verify role
    try {
      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      if (!userDoc.exists) {
        console.error("User document does not exist for UID:", uid);
        throw new functions.https.HttpsError(
          "permission-denied",
          "User document not found."
        );
      }
      const userData = userDoc.data();
      console.log("User role:", userData.role);
      if (userData.role !== "Admin") {
        console.error("Permission denied for user:", uid);
        throw new functions.https.HttpsError(
          "permission-denied",
          "User must be an admin to create new users."
        );
      }
    } catch (error) {
      console.error("Error fetching user document:", error);
      throw new functions.https.HttpsError("internal", "Error fetching user document.");
    }

    const { email, password, ...additionalData } = request.data;
    console.log("Creating user with email:", email);

    // Validate required fields
    if (!email || !password) {
      console.error("Email or password not provided.");
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email and password are required."
      );
    }

    try {
      // Create the user in Firebase Auth
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: additionalData.name || "",
        disabled: !additionalData.isActive,
      });
      console.log("User created with UID:", userRecord.uid);

      // Add additional user data to Firestore
      await admin.firestore().collection("users").doc(userRecord.uid).set({
        userId: userRecord.uid,
        email: email,
        name: additionalData.name || "",
        role: additionalData.role || "User",
        isActive: additionalData.isActive ?? true,
        mobileNumber: additionalData.mobileNumber || "",
        branchId: additionalData.branchId || "",
        address: additionalData.address || "",
        dob: additionalData.dob
          ? admin.firestore.Timestamp.fromDate(new Date(additionalData.dob))
          : null,
        joiningDate: additionalData.joiningDate
          ? admin.firestore.Timestamp.fromDate(new Date(additionalData.joiningDate))
          : null,
        profilePhotoUrl: additionalData.profilePhotoUrl || "",
      });
      console.log("User data saved to Firestore.");
      return { success: true };
    } catch (error) {
      console.error("Error creating user:", error);
      throw new functions.https.HttpsError("internal", "Error creating user.");
    }
  }
);

// ===================================================================
// 2. Firestore-triggered Functions to Send Notifications
// ===================================================================

// Helper: Each function listens for a new document creation and sends a notification
// to a topic matching the collection name. Make sure your app subscribes to that topic.

// 2.1 Announcements
exports.sendAnnouncementNotification = onDocumentCreated(
  {
    document: "announcements/{announcementId}",
  },
  async (event) => {
    const announcementData = event.data;
    console.log("New announcement:", announcementData);

    const payload = {
      notification: {
        title: "New Announcement",
        body: announcementData.title || "There's a new announcement.",
      },
      data: {
        announcementId: event.params.announcementId,
      },
    };

    try {
      await admin.messaging().sendToTopic("announcements", payload);
      console.log("Announcement notification sent to topic 'announcements'");
    } catch (error) {
      console.error("Error sending announcement notification:", error);
    }
  }
);

// 2.2 Attendance Records
exports.sendAttendanceNotification = onDocumentCreated(
  {
    document: "attendanceRecords/{recordId}",
  },
  async (event) => {
    const attendanceData = event.data;
    console.log("New attendance record:", attendanceData);

    const payload = {
      notification: {
        title: "Attendance Recorded",
        body: `Attendance recorded for ${attendanceData.userName || "a user"}.`,
      },
      data: {
        recordId: event.params.recordId,
      },
    };

    try {
      await admin.messaging().sendToTopic("attendanceRecords", payload);
      console.log("Attendance notification sent to topic 'attendanceRecords'");
    } catch (error) {
      console.error("Error sending attendance notification:", error);
    }
  }
);

// 2.3 Chats
exports.sendChatNotification = onDocumentCreated(
  {
    document: "chats/{chatId}",
  },
  async (event) => {
    const chatData = event.data;
    console.log("New chat message:", chatData);

    const payload = {
      notification: {
        title: "New Chat Message",
        body: chatData.message || "You have a new chat message.",
      },
      data: {
        chatId: event.params.chatId,
      },
    };

    try {
      await admin.messaging().sendToTopic("chats", payload);
      console.log("Chat notification sent to topic 'chats'");
    } catch (error) {
      console.error("Error sending chat notification:", error);
    }
  }
);

// 2.4 Enquiries
exports.sendEnquiryNotification = onDocumentCreated(
  {
    document: "enquiries/{enquiryId}",
  },
  async (event) => {
    const enquiryData = event.data;
    console.log("New enquiry:", enquiryData);

    const payload = {
      notification: {
        title: "New Enquiry",
        body: enquiryData.subject || "You have a new enquiry.",
      },
      data: {
        enquiryId: event.params.enquiryId,
      },
    };

    try {
      await admin.messaging().sendToTopic("enquiries", payload);
      console.log("Enquiry notification sent to topic 'enquiries'");
    } catch (error) {
      console.error("Error sending enquiry notification:", error);
    }
  }
);

// 2.5 Leave Requests
exports.sendLeaveRequestNotification = onDocumentCreated(
  {
    document: "leaveRequests/{requestId}",
  },
  async (event) => {
    const leaveData = event.data;
    console.log("New leave request:", leaveData);

    const payload = {
      notification: {
        title: "New Leave Request",
        body: `${leaveData.userName || "A user"} has applied for leave.`,
      },
      data: {
        requestId: event.params.requestId,
      },
    };

    try {
      await admin.messaging().sendToTopic("leaveRequests", payload);
      console.log("Leave request notification sent to topic 'leaveRequests'");
    } catch (error) {
      console.error("Error sending leave request notification:", error);
    }
  }
);

// 2.6 Products
exports.sendProductNotification = onDocumentCreated(
  {
    document: "products/{productId}",
  },
  async (event) => {
    const productData = event.data;
    console.log("New product added:", productData);

    const payload = {
      notification: {
        title: "New Product",
        body: productData.name || "A new product has been added.",
      },
      data: {
        productId: event.params.productId,
      },
    };

    try {
      await admin.messaging().sendToTopic("products", payload);
      console.log("Product notification sent to topic 'products'");
    } catch (error) {
      console.error("Error sending product notification:", error);
    }
  }
);

// 2.7 Salary Advances
exports.sendSalaryAdvanceNotification = onDocumentCreated(
  {
    document: "salaryAdvances/{advanceId}",
  },
  async (event) => {
    const advanceData = event.data;
    console.log("New salary advance request:", advanceData);

    const payload = {
      notification: {
        title: "Salary Advance Request",
        body: `${advanceData.userName || "A user"} has requested a salary advance.`,
      },
      data: {
        advanceId: event.params.advanceId,
      },
    };

    try {
      await admin.messaging().sendToTopic("salaryAdvances", payload);
      console.log("Salary advance notification sent to topic 'salaryAdvances'");
    } catch (error) {
      console.error("Error sending salary advance notification:", error);
    }
  }
);

// 2.8 Tasks
exports.sendTaskNotification = onDocumentCreated(
  {
    document: "tasks/{taskId}",
  },
  async (event) => {
    const taskData = event.data;
    console.log("New task created:", taskData);

    const payload = {
      notification: {
        title: "New Task",
        body: taskData.title || "You have a new task assigned.",
      },
      data: {
        taskId: event.params.taskId,
      },
    };

    try {
      await admin.messaging().sendToTopic("tasks", payload);
      console.log("Task notification sent to topic 'tasks'");
    } catch (error) {
      console.error("Error sending task notification:", error);
    }
  }
);
