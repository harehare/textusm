const fs = require("fs");
const zlib = require("zlib");

const { initializeApp, cert } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");

if (process.env.DATABASE_GOOGLE_APPLICATION_CREDENTIALS_JSON) {
  initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID,
    credential: process.env.DATABASE_GOOGLE_APPLICATION_CREDENTIALS_JSON ? cert(
      JSON.parse(
        Buffer.from(
          process.env.DATABASE_GOOGLE_APPLICATION_CREDENTIALS_JSON,
          "base64"
        ).toString()
      )
    ) : undefined,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  });
} else {
  initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  });
}

(async () => {
  fs.readdir("./assets/fontlist/", (err, files) => {
    files.forEach(async (file) => {
      const uploadFile = `./assets/fontlist/${file}`;
      fs.writeFileSync(
        `${uploadFile}.gz`,
        zlib.gzipSync(fs.readFileSync(`${uploadFile}`, "utf-8"))
      );

      await getStorage()
        .bucket()
        .upload(`${uploadFile}.gz`, {
          destination: `fontlist/${file}.gz`,
        })
        .catch((err) => console.log(err));

      fs.unlinkSync(`${uploadFile}.gz`);
      console.log(`upload ${file}`);
    });
  });
})();
