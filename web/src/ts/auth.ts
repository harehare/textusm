import firebase from 'firebase/app';
import 'firebase/auth';

const firebaseConfig = {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    appId: process.env.FIREBASE_APP_ID,
};
firebase.initializeApp(firebaseConfig);

export const signIn = (provider: firebase.auth.AuthProvider): Promise<void> => {
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

export const signOut = (): Promise<void> => {
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

export const pollRefreshToken = (callback: (idToken: string) => void): void => {
    setInterval(async () => {
        const user = firebase.auth().currentUser;
        if (user) {
            const idToken = await user.getIdToken(true);
            if (idToken) {
                callback(idToken);
            }
        }
    }, 10 * 60 * 1000);
};

export const refreshToken = (): Promise<string> | undefined => {
    return firebase.auth().currentUser?.getIdToken(true);
};

export const authStateChanged = (
    onBeforeAuth: () => void,
    onAfterAuth: () => void,
    onAuthStateChanged: (
        idToken: string | null,
        user: firebase.User | null,
        provider: { provider: string | null; accessToken: string | null }
    ) => void
): void => {
    firebase.auth().onAuthStateChanged(async (user) => {
        onBeforeAuth();
        const result = await firebase.auth().getRedirectResult();
        if (user) {
            const providers = user.providerData.map((p) =>
                p ? p.providerId : ''
            );
            user.getIdToken().then((idToken) => {
                onAuthStateChanged(idToken, user, {
                    provider:
                        providers.length > 0 && providers[0]
                            ? providers[0]
                            : '',
                    // @ts-expect-error
                    accessToken: result.credential?.accessToken,
                });
                onAfterAuth();
            });
        } else {
            onAuthStateChanged(null, null, {
                provider: null,
                accessToken: null,
            });
            onAfterAuth();
        }
    });
};

export const providers = {
    google: new firebase.auth.GoogleAuthProvider(),
    github: new firebase.auth.GithubAuthProvider(),
    githubWithGist: (() => {
        const p = new firebase.auth.GithubAuthProvider();
        p.addScope('gist');
        return p;
    })(),
};
