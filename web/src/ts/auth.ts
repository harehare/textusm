import { type FirebaseOptions, initializeApp } from 'firebase/app';
import {
  type AuthProvider,
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

export type User = {
  id: string;
  displayName: string;
  email: string;
  photoURL: string;
  provider: string | undefined;
  accessToken: string | undefined;
};
const firebaseConfig: FirebaseOptions = {
  apiKey: process.env.FIREBASE_API_KEY ?? '',
  authDomain: process.env.FIREBASE_AUTH_DOMAIN ?? '',
  projectId: process.env.FIREBASE_PROJECT_ID ?? '',
  appId: process.env.FIREBASE_APP_ID ?? '',
};
const app = initializeApp(firebaseConfig);
const auth = getAuth();

if (process.env.MONITOR_ENABLE === '1') {
  getPerformance(app);
}

if (process.env.NODE_ENV !== 'production' && process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);
}

export const signIn = async (provider: AuthProvider): Promise<void> =>
  new Promise((resolve, reject) => {
    signInWithRedirect(auth, provider)
      .then((result) => {
        resolve(result);
      })
      .catch((error) => {
        reject(error);
      });
  });

export const signOut = async (): Promise<void> =>
  new Promise((resolve, reject) => {
    firebaseSignOut(auth)
      .then((result) => {
        resolve(result);
      })
      .catch((error) => {
        reject(error);
      });
  });

export const pollRefreshToken = (callback: (idToken: string) => void): void => {
  setInterval(async () => {
    const user = auth.currentUser;
    if (user) {
      const idToken = await user.getIdToken(true).catch(() => false);
      if (idToken && typeof idToken === 'string') {
        callback(idToken);
      }
    }
  }, 10 * 60 * 1000);
};

export const refreshToken = (): Promise<string> | undefined => auth.currentUser?.getIdToken(true);

export const authStateChanged = (
  onBeforeAuth: () => void,
  onAfterAuth: () => void,
  onAuthStateChanged: (idToken: string | undefined, user: User | undefined) => void
): void => {
  firebaseOnAuthStateChanged(auth, async (user) => {
    onBeforeAuth();
    if (user) {
      const providers = user.providerData.map((p) => (p ? p.providerId : ''));
      const provider = providers.length > 0 && providers[0] ? providers[0] : '';

      const idToken = await user.getIdToken().catch(() => {
        onAuthStateChanged(undefined, undefined);
        throw new Error('Failed getIdToken');
      });
      onAuthStateChanged(idToken, {
        id: user.uid,
        displayName: user.displayName ?? '',
        email: user.email ?? '',
        photoURL: user.photoURL ?? '',
        provider,
        accessToken: undefined,
      });
      onAfterAuth();
    } else {
      onAuthStateChanged(undefined, undefined);
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

export const signInGithubWithGist = async (): Promise<{
  accessToken: string | undefined;
}> =>
  new Promise((resolve, reject) => {
    firebaseSignInWithPopup(auth, providers.githubWithGist)
      .then((result) => {
        const user = result.user;
        if (!user) {
          reject(new Error('Failed sigIn'));
          return;
        }

        // @ts-expect-error: Unreachable code error
        if (!result?._tokenResponse?.oauthAccessToken) {
          throw new Error('Could not get oauthAccessToken for Github gist oauthAccessToken.');
        }

        resolve({
          // @ts-expect-error: Unreachable code error
          accessToken: result?._tokenResponse?.oauthAccessToken,
        });
      })
      .catch((error) => {
        reject(error);
      });
  });
