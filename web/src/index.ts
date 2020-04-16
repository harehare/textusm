"use strict";

import "./styles.scss";
import { loadEditor, EditorOption } from "./ts/editor";
import { initDowonlad } from "./ts/download";
import { initShare } from "./ts/share";
import { initDB } from "./ts/db";
import { Auth } from "./ts/auth";
import { loadSettings, saveSettings } from "./ts/settings";
import { Settings } from "./ts/model";
import { ElmApp } from "./ts/elm";
// @ts-ignore
import { Elm } from "./elm/Main.elm";

const app: ElmApp = Elm.Main.init({
    flags: [process.env.API_ROOT, JSON.stringify(loadSettings())],
});
const auth = new Auth();
const openFullscreen = () => {
    const elem = document.documentElement;
    if (elem.requestFullscreen) {
        elem.requestFullscreen();
        // @ts-ignore
    } else if (elem.mozRequestFullScreen) {
        // @ts-ignore
        elem.mozRequestFullScreen();
        // @ts-ignore
    } else if (elem.webkitRequestFullscreen) {
        // @ts-ignore
        elem.webkitRequestFullscreen();
        // @ts-ignore
    } else if (elem.msRequestFullscreen) {
        // @ts-ignore
        elem.msRequestFullscreen();
    }
};
const closeFullscreen = () => {
    if (document.exitFullscreen) {
        document.exitFullscreen();
        // @ts-ignore
    } else if (document.mozCancelFullScreen) {
        // @ts-ignore
        document.mozCancelFullScreen();
        // @ts-ignore
    } else if (document.webkitExitFullscreen) {
        // @ts-ignore
        document.webkitExitFullscreen();
        // @ts-ignore
    } else if (document.msExitFullscreen) {
        // @ts-ignore
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
    auth.signIn(
        provider === "Google" ? auth.provideres.google : auth.provideres.github
    );
});

app.ports.signOut.subscribe(async () => {
    await auth.signOut().catch((err) => {
        app.ports.onErrorNotification.send("Failed sign out.");
    });
});

auth.authn(
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
                displayName: profile.displayName || "",
                email: profile.email || "",
                photoURL: profile.photoURL || "",
            });
        }
    }
);

app.ports.selectTextById.subscribe((id: string) => {
    const element = document.getElementById(id);
    if (element) {
        (element as HTMLInputElement).select();
    }
});

app.ports.openFullscreen.subscribe(() => {
    openFullscreen();
});

app.ports.closeFullscreen.subscribe(() => {
    closeFullscreen();
});

// @ts-ignore
const attachApp = (app, list) => {
    // @ts-ignore
    list.forEach((l) => l(app));
};

attachApp(app, [initDowonlad, initShare, initDB]);

if ("serviceWorker" in navigator && !location.host.startsWith("localhost")) {
    navigator.serviceWorker.register("/sw.js");
}
