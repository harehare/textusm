import * as firebase from "firebase/app";
import "firebase/auth";

export class Auth {
    gitHubAuthProvider = new firebase.auth.GithubAuthProvider();
    provideres = {
        google: new firebase.auth.GoogleAuthProvider(),
        github: this.gitHubAuthProvider
    };

    constructor() {
        const firebaseConfig = {
            apiKey: process.env.FIREBASE_API_KEY,
            authDomain: process.env.FIREBASE_AUTH_DOMAIN,
            projectId: process.env.FIREBASE_PROJECT_ID,
            storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
            appId: process.env.FIREBASE_APP_ID
        };
        firebase.initializeApp(firebaseConfig);
        this.gitHubAuthProvider.addScope("repo");
    }

    getUser() {
        return firebase.auth().currentUser || null;
    }

    login(provider) {
        return new Promise((resolve, reject) => {
            firebase
                .auth()
                .signInWithRedirect(provider)
                .then(result => {
                    resolve(result);
                })
                .catch(err => {
                    reject(err);
                });
        });
    }

    authn(onAuthStateChanged) {
        firebase.auth().onAuthStateChanged(user => {
            if (user) {
                user.getIdToken(true).then(idToken => {
                    onAuthStateChanged(idToken, user);
                });
            } else {
                onAuthStateChanged(null, null);
            }
        });
    }

    getAccessToken() {
        return new Promise((resolve, reject) => {
            firebase
                .auth()
                .getRedirectResult()
                .then(result => {
                    resolve(result.credential.accessToken);
                })
                .catch(err => {
                    reject(err);
                });
        });
    }

    logout() {
        return new Promise((resolve, reject) => {
            firebase
                .auth()
                .signOut()
                .then(result => {
                    resolve(result);
                })
                .catch(err => {
                    reject(err);
                });
        });
    }
}
