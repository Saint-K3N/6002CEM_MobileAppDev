const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ✅ HTTP version of delete user function
exports.deleteUserHttp = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }

  console.log("=== DELETE USER HTTP FUNCTION ===");
  console.log("Headers:", req.headers);
  console.log("Authorization header:", req.headers.authorization);

  try {
    // Get the authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      console.log("No valid authorization header found");
      return res.status(401).json({
        error: "Unauthorized",
        message: "No valid authorization token provided",
      });
    }

    const idToken = authHeader.split("Bearer ")[1];
    console.log("ID Token received, length:", idToken.length);

    // Verify the ID token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    console.log("Token verified for user:", decodedToken.email);
    console.log("User UID:", decodedToken.uid);

    const {uid} = req.body;
    if (!uid) {
      return res.status(400).json({
        error: "Bad Request",
        message: "User ID is required",
      });
    }

    console.log(`Starting deletion process for user: ${uid}`);

    // 1. Delete from Firebase Auth
    await admin.auth().deleteUser(uid);
    console.log(`✅ Deleted user from Auth: ${uid}`);

    // 2. Delete from Firestore users collection
    await admin.firestore().collection("users").doc(uid).delete();
    console.log(`✅ Deleted user document: ${uid}`);

    // 3. Delete all meal plans for this user
    const mealPlansQuery = await admin.firestore()
        .collection("meal_plans")
        .where("userId", "==", uid)
        .get();

    const batch = admin.firestore().batch();
    mealPlansQuery.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    if (mealPlansQuery.docs.length > 0) {
      await batch.commit();
      const deleteMsg = `✅ Deleted ${mealPlansQuery.docs.length} meal plans`;
      console.log(`${deleteMsg} for user: ${uid}`);
    }

    const result = {
      success: true,
      message: `User ${uid} completely deleted from Auth and Firestore`,
      deletedMealPlans: mealPlansQuery.docs.length,
      deletedBy: decodedToken.email,
    };

    console.log("Delete operation completed successfully:", result);
    return res.status(200).json(result);
  } catch (error) {
    console.error("❌ Error in deleteUserHttp:", error);
    return res.status(500).json({
      error: "Internal Server Error",
      message: error.message,
    });
  }
});

// ✅ HTTP version of test auth function
exports.testAuthHttp = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }

  console.log("=== TEST AUTH HTTP FUNCTION ===");
  console.log("Headers:", req.headers);
  console.log("Authorization header:", req.headers.authorization);

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        error: "Unauthorized",
        message: "No valid authorization token provided",
      });
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    console.log("Token verified for user:", decodedToken.email);

    return res.status(200).json({
      success: true,
      message: `Hello ${decodedToken.email}! HTTP Auth test works.`,
      uid: decodedToken.uid,
      email: decodedToken.email,
    });
  } catch (error) {
    console.error("❌ Error in testAuthHttp:", error);
    return res.status(500).json({
      error: "Internal Server Error",
      message: error.message,
    });
  }
});

// Keep your existing callable functions as backup
exports.pingTest = functions.https.onCall(async (data, context) => {
  return {
    success: true,
    message: "Ping test works! No auth required.",
    timestamp: new Date().toISOString(),
    authExists: !!context.auth,
  };
});

// Health check function
exports.ping = functions.https.onRequest((req, res) => {
  res.send("🔥 Firebase Functions are working!");
});

