const { initializeApp, cert } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");

initializeApp({
  credential: cert(
    JSON.parse(
      Buffer.from(
        process.env.DATABASE_GOOGLE_APPLICATION_CREDENTIALS_JSON,
        "base64"
      ).toString()
    )
  ),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
});
const bucket = getStorage().bucket();

(async () => {
  ["all.txt", "ja.txt"].forEach(async (file) => {
    await bucket
      .upload(`../assets/fontlist/${file}`, { destination: `fontlist/${file}` })
      .catch((err) => console.log(err));
  });
})();
