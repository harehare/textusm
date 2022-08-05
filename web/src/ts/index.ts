import copy from 'clipboard-copy';
import { Workbox } from 'workbox-window';

// @ts-ignore
import { Elm } from '../elm/Main.elm';
import '../styles.css';
import {
    signOut,
    signIn,
    authStateChanged,
    providers,
    refreshToken,
    pollRefreshToken,
    signInGithubWithGist,
} from './auth';
import { initDB } from './db';
import { initDownload } from './download';
import { setElmApp } from './editor';
import { ElmApp, Provider } from './elm';
import { initFile, canUseNativeFileSystem } from './file';
import { Settings } from './model';
import { loadSettings, saveSettings } from './settings';

const lang =
    (window.navigator.languages && window.navigator.languages[0]) ||
    window.navigator.language ||
    window.navigator.userLanguage ||
    window.navigator.browserLanguage;
const isDarkMode =
    window.matchMedia &&
    window.matchMedia('(prefers-color-scheme: dark)').matches;
const app: ElmApp = Elm.Main.init({
    flags: {
        lang,
        settings: loadSettings(isDarkMode),
        isOnline: window.navigator.onLine ?? true,
        isDarkMode,
        canUseNativeFileSystem,
    },
});

setElmApp(app);
authStateChanged(
    () => {
        app.ports.progress.send(true);
    },
    () => {
        app.ports.progress.send(false);
    },
    async (idToken, user) => {
        if (user && idToken) {
            app.ports.onAuthStateChanged.send({
                idToken,
                id: user.id,
                displayName: user.displayName,
                email: user.email,
                photoURL: user.photoURL,
                loginProvider: {
                    provider: user.provider,
                    accessToken: user.accessToken,
                },
            });
        }
    }
);

app.ports.loadSettingsFromLocal.subscribe((diagramType: string) => {
    app.ports.loadSettingsFromLocalCompleted.send(
        loadSettings(isDarkMode, diagramType)
    );
});

app.ports.saveSettingsToLocal.subscribe((settings: Settings) => {
    saveSettings(settings);
});

app.ports.signIn.subscribe((provider: Provider) => {
    switch (provider) {
        case 'Google':
            signIn(providers.google);
            return;
        case 'Github':
            signIn(providers.github);
            return;
    }
});

app.ports.signOut.subscribe(async () => {
    await signOut().catch(() => {
        app.ports.sendErrorNotification.send('Failed sign out.');
    });
    app.ports.onAuthStateChanged.send(null);
});

app.ports.refreshToken.subscribe(async () => {
    const idToken = await refreshToken();
    if (idToken) {
        app.ports.updateIdToken.send(idToken);
    }
});

app.ports.selectTextById.subscribe(async (id: string) => {
    const element = document.getElementById(id);
    if (element) {
        const inputElement = element as HTMLInputElement;
        inputElement.select();
        if (navigator.clipboard) {
            await navigator.clipboard.writeText(inputElement.value);
        }
    }
});

app.ports.openFullscreen.subscribe(() => {
    const elem = document.documentElement;
    if (elem.requestFullscreen) {
        elem.requestFullscreen();
    } else if (elem.mozRequestFullScreen) {
        elem.mozRequestFullScreen();
    } else if (elem.webkitRequestFullscreen) {
        elem.webkitRequestFullscreen();
    } else if (elem.msRequestFullscreen) {
        elem.msRequestFullscreen();
    }
});

app.ports.closeFullscreen.subscribe(() => {
    if (document.exitFullscreen) {
        document.exitFullscreen();
    } else if (document.mozCancelFullScreen) {
        document.mozCancelFullScreen();
    } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
    } else if (document.msExitFullscreen) {
        document.msExitFullscreen();
    }
});

app.ports.copyText.subscribe((text: string) => {
    copy(text);
});

app.ports.getGithubAccessToken.subscribe(async (cmd) => {
    const result = await signInGithubWithGist().catch(() => {
        app.ports.sendErrorNotification.send('Failed sign in.');
        return { accessToken: null };
    });
    app.ports.gotGithubAccessToken.send({
        cmd,
        accessToken: result.accessToken,
    });
});

[initDownload, initDB, initFile].forEach((l) => l(app));

window.requestIdleCallback(() => {
    pollRefreshToken(app.ports.updateIdToken.send);

    document.addEventListener('fullscreenchange', () => {
        if (!document.fullscreenElement) {
            app.ports.fullscreen.send(false);
        }
    });

    window.addEventListener('offline', () => {
        app.ports.changeNetworkState.send(false);
    });

    window.addEventListener('online', () => {
        app.ports.changeNetworkState.send(true);
    });

    const loadSentry = async () => {
        if (
            process.env.SENTRY_ENABLE === '1' &&
            process.env.SENTRY_DSN &&
            process.env.SENTRY_RELEASE
        ) {
            const sentry = await import('@sentry/browser');
            sentry.init({
                dsn: process.env.SENTRY_DSN,
                release: process.env.SENTRY_RELEASE,
            });
        }
    };

    loadSentry();

    if ('serviceWorker' in navigator && process.env.NODE_ENV === 'production') {
        const wb = new Workbox('/sw.js');
        wb.register();
        wb.addEventListener('installed', (e) => {
            if (e.isUpdate) {
                app.ports.notifyNewVersionAvailable.send(
                    'New version is available!'
                );
            }
        });
    }
});
