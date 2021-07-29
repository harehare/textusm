import firebase from 'firebase/app';
import 'firebase/auth';

export interface User {
    id: string;
    displayName: string;
    email: string;
    photoURL: string;
}
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
        new GithubAccessToken().clear();
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
        user: User | null,
        provider: { provider: string | null; accessToken: string | null }
    ) => void
): void => {
    firebase.auth().onAuthStateChanged(async (user) => {
        onBeforeAuth();
        if (user) {
            const result = await firebase.auth().getRedirectResult();
            console.log(result);
            const providers = user.providerData.map((p) =>
                p ? p.providerId : ''
            );
            const provider =
                providers.length > 0 && providers[0] ? providers[0] : '';
            // @ts-expect-error
            const accessToken = result?.credential?.accessToken;
            const g = new GithubAccessToken();
            if (isGithubProvider(provider)) {
                if (accessToken) {
                    g.refresh(accessToken);
                }
            } else {
                g.clear();
            }

            user.getIdToken().then((idToken) => {
                onAuthStateChanged(
                    idToken,
                    {
                        id: user.uid,
                        displayName: user.displayName ?? '',
                        email: user.email ?? '',
                        photoURL: user.photoURL ?? '',
                    },
                    {
                        provider:
                            providers.length > 0 && providers[0]
                                ? providers[0]
                                : '',
                        accessToken: g.get(),
                    }
                );
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
    github: (() => {
        const p = new firebase.auth.GithubAuthProvider();
        p.addScope('gist');
        return p;
    })(),
};

const isGithubProvider = (provider: string) => {
    return provider === 'github.com';
};

class GithubAccessToken {
    LOCAL_STORAGE_KEY = 'gha_gist';
    private accessToken = '';

    refresh(accessToken: string) {
        this.accessToken = accessToken;
        localStorage.setItem(this.LOCAL_STORAGE_KEY, this.accessToken);
    }

    clear() {
        localStorage.removeItem(this.LOCAL_STORAGE_KEY);
    }

    get() {
        return this.accessToken;
    }
}
