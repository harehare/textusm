import { initializeApp } from 'firebase/app';
import {
    AuthProvider,
    signOut as firebaseSignOut,
    signInWithRedirect,
    signInWithPopup as firebaseSignInWithPopup,
    GoogleAuthProvider,
    GithubAuthProvider,
    getAuth,
    onAuthStateChanged as firebaseOnAuthStateChanged,
    connectAuthEmulator,
} from 'firebase/auth';
import { getPerformance } from 'firebase/performance';

export interface User {
    id: string;
    displayName: string;
    email: string;
    photoURL: string;
    provider: string | null;
    accessToken: string | null;
}
const firebaseConfig = {
    apiKey: process.env.FIREBASE_API_KEY,
    authDomain: process.env.FIREBASE_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    appId: process.env.FIREBASE_APP_ID,
};
const app = initializeApp(firebaseConfig);
const auth = getAuth();

if (process.env.MONITOR_ENABLE === '1') {
    getPerformance(app);
}

if (
    process.env.NODE_ENV !== 'production' &&
    process.env.FIREBASE_AUTH_EMULATOR_URL
) {
    connectAuthEmulator(auth, process.env.FIREBASE_AUTH_EMULATOR_URL);
}

export const signIn = (provider: AuthProvider): Promise<void> => {
    return new Promise((resolve, reject) => {
        signInWithRedirect(auth, provider)
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
        firebaseSignOut(auth)
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
        const user = auth.currentUser;
        if (user) {
            const idToken = await user.getIdToken(true).catch(() => {
                return false;
            });
            if (idToken && typeof idToken === 'string') {
                callback(idToken);
            }
        }
    }, 10 * 60 * 1000);
};

export const refreshToken = (): Promise<string> | undefined => {
    return auth.currentUser?.getIdToken(true);
};

export const authStateChanged = (
    onBeforeAuth: () => void,
    onAfterAuth: () => void,
    onAuthStateChanged: (idToken: string | null, user: User | null) => void
): void => {
    firebaseOnAuthStateChanged(auth, async (user) => {
        onBeforeAuth();
        if (user) {
            const providers = user.providerData.map((p) =>
                p ? p.providerId : ''
            );
            const provider =
                providers.length > 0 && providers[0] ? providers[0] : '';

            user.getIdToken().then((idToken) => {
                onAuthStateChanged(idToken, {
                    id: user.uid,
                    displayName: user.displayName ?? '',
                    email: user.email ?? '',
                    photoURL: user.photoURL ?? '',
                    provider,
                    accessToken: null,
                });
                onAfterAuth();
            });
        } else {
            onAuthStateChanged(null, null);
            onAfterAuth();
        }
    });
};

export const providers = {
    google: new GoogleAuthProvider(),
    github: new GithubAuthProvider(),
    githubWithGist: (() => {
        const p = new GithubAuthProvider();
        p.addScope('gist');
        return p;
    })(),
};

export const signInGithubWithGist = (): Promise<{
    accessToken: string | null;
}> => {
    return new Promise((resolve, reject) => {
        firebaseSignInWithPopup(auth, providers.githubWithGist)
            .then((result) => {
                const user = result.user;
                if (!user) {
                    reject(new Error('Failed sigIn'));
                    return;
                }

                // @ts-expect-error
                if (!result?._tokenResponse?.oauthAccessToken) {
                    throw new Error(
                        'Could not get oauthAccessToken for Github gist oauthAccessToken.'
                    );
                }

                resolve({
                    // @ts-expect-error
                    accessToken: result?._tokenResponse?.oauthAccessToken,
                });
            })
            .catch((err) => {
                reject(err);
            });
    });
};
