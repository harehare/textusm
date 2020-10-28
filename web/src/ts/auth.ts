import firebase from "firebase/app";
import "firebase/auth";

const firebaseConfig = {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    appId: process.env.FIREBASE_APP_ID,
};
firebase.initializeApp(firebaseConfig);

const signIn = (provider: firebase.auth.AuthProvider): Promise<void> => {
    return new Promise((resolve, reject) => {
        firebase
            .auth()
            .signInWithRedirect(provider)
            .then((result) => {
                resolve(result);
            })
            .catch((err) => {
                reject(err);
            });
    });
};

const signOut = (): Promise<void> => {
    return new Promise((resolve, reject) => {
        firebase
            .auth()
            .signOut()
            .then((result) => {
                resolve(result);
            })
            .catch((err) => {
                reject(err);
            });
    });
};

const authStateChanged = (
    onBeforeAuth: () => void,
    onAfterAuth: () => void,
    onAuthStateChanged: (
        idToken: string | null,
        user: firebase.User | null
    ) => void
): void => {
    firebase.auth().onAuthStateChanged((user) => {
        onBeforeAuth();
        if (user) {
            user.getIdToken().then((idToken) => {
                onAuthStateChanged(idToken, user);
                onAfterAuth();
            });
        } else {
            onAuthStateChanged(null, null);
            onAfterAuth();
        }
    });
};

const providers = {
    google: new firebase.auth.GoogleAuthProvider(),
    github: new firebase.auth.GithubAuthProvider(),
};

export { providers, signIn, signOut, authStateChanged };
