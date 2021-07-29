import '../styles.scss';
import { setElmApp } from './editor';
import { initDownload } from './download';
import { initDB } from './db';
import {
    signOut,
    signIn,
    authStateChanged,
    providers,
    refreshToken,
    pollRefreshToken,
} from './auth';
import { loadSettings, saveSettings } from './settings';
import { Settings } from './model';
import { ElmApp, Provider } from './elm';
// @ts-ignore
import { Elm } from '../elm/Main.elm';
import copy from 'clipboard-copy';

const lang =
    (window.navigator.languages && window.navigator.languages[0]) ||
    window.navigator.language ||
    window.navigator.userLanguage ||
    window.navigator.browserLanguage;

const app: ElmApp = Elm.Main.init({
    flags: {
        apiRoot: process.env.API_ROOT,
        lang,
        settings: loadSettings(),
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
    async (idToken, user, provider) => {
        if (user && idToken) {
            app.ports.onAuthStateChanged.send({
                idToken,
                id: user.id,
                displayName: user.displayName,
                email: user.email,
                photoURL: user.photoURL,
                loginProvider: {
                    provider: provider.provider,
                    accessToken: provider.accessToken,
                },
            });
        }
    }
);

app.ports.saveSettings.subscribe((settings: Settings) => {
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

const attachApp = (a: ElmApp, list: ((a: ElmApp) => void)[]) => {
    list.forEach((l) => l(a));
};

attachApp(app, [initDownload, initDB]);

document.addEventListener('fullscreenchange', () => {
    if (!document.fullscreenElement) {
        app.ports.onCloseFullscreen.send({});
    }
});

window.requestIdleCallback(() => {
    pollRefreshToken(app.ports.updateIdToken.send);

    const loadSentry = async () => {
        if (process.env.SENTRY_ENABLE === '1') {
            const sentry = await import('@sentry/browser');
            sentry.init({
                dsn: process.env.SENTRY_DSN,
            });
        }
    };

    loadSentry();

    if (
        'serviceWorker' in navigator &&
        !window.location.host.startsWith('localhost')
    ) {
        navigator.serviceWorker.register('/sw.js');
    }
});
