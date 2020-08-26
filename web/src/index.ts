import "./styles.scss";
import { loadEditor } from "./ts/editor";
import { initDownload } from "./ts/download";
import { initShare } from "./ts/share";
import { initDB } from "./ts/db";
import { signOut, signIn, authStateChanged, providers } from "./ts/auth";
import { loadSettings, saveSettings } from "./ts/settings";
import { Settings } from "./ts/model";
import { ElmApp, EditorOption } from "./ts/elm";
// @ts-ignore
import { Elm } from "./elm/Main.elm";

const lang =
    (window.navigator.languages && window.navigator.languages[0]) ||
    window.navigator.language ||
    window.navigator.userLanguage ||
    window.navigator.browserLanguage;

const app: ElmApp = Elm.Main.init({
    flags: [[process.env.API_ROOT, lang], loadSettings()],
});

const openFullscreen = () => {
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
};
const closeFullscreen = () => {
    if (document.exitFullscreen) {
        document.exitFullscreen();
    } else if (document.mozCancelFullScreen) {
        document.mozCancelFullScreen();
    } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
    } else if (document.msExitFullscreen) {
        document.msExitFullscreen();
    }
};

app.ports.saveSettings.subscribe((settings: Settings) => {
    saveSettings(settings);
});

app.ports.loadEditor.subscribe(([text, option]: [string, EditorOption]) => {
    loadEditor(app, text, option);
});

app.ports.signIn.subscribe((provider: string) => {
    signIn(provider === "Google" ? providers.google : providers.github);
});

app.ports.signOut.subscribe(async () => {
    await signOut().catch(() => {
        app.ports.onErrorNotification.send("Failed sign out.");
    });
});

authStateChanged(
    () => {
        app.ports.progress.send(true);
    },
    () => {
        app.ports.progress.send(false);
    },
    async (idToken, profile) => {
        if (profile && idToken) {
            app.ports.onAuthStateChanged.send({
                idToken,
                id: profile.uid,
                displayName: profile.displayName ?? "",
                email: profile.email ?? "",
                photoURL: profile.photoURL ?? "",
            });
        }
    }
);

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
    openFullscreen();
});

app.ports.closeFullscreen.subscribe(() => {
    closeFullscreen();
});

const attachApp = (a: ElmApp, list: ((a: ElmApp) => void)[]) => {
    list.forEach((l) => l(a));
};

attachApp(app, [initDownload, initShare, initDB]);

if (
    "serviceWorker" in navigator &&
    !window.location.host.startsWith("localhost")
) {
    navigator.serviceWorker.register("/sw.js");
}

const loadSentry = async () => {
    if (process.env.SENTRY_ENABLE === "1") {
        const sentry = await import("@sentry/browser");
        sentry.init({
            dsn: process.env.SENTRY_DSN,
        });
    }
};

loadSentry();
