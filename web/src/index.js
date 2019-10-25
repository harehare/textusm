"use strict";

import "./styles.scss";
import { loadEditor } from "./js/editor.js";
import { initDowonlad } from "./js/download";
import { initShare } from "./js/share";
import { initDB } from "./js/db";
import { Auth } from "./js/auth";
import { loadSettings, saveSettings } from "./js/settings";
import { Elm } from "./elm/Main.elm";

const app = Elm.Main.init({
    flags: [process.env.API_ROOT, loadSettings()]
});
const auth = new Auth();
const openFullscreen = function() {
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
const closeFullscreen = function() {
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

app.ports.saveSettings.subscribe(settings => {
    saveSettings(settings);
});

app.ports.loadEditor.subscribe(text => {
    loadEditor(app, text);
});

app.ports.login.subscribe(() => {
    auth.login(auth.provideres.google, () => {});
});

app.ports.logout.subscribe(async () => {
    await auth.logout().catch(err => {
        app.ports.onErrorNotification.send("Failed sign out.");
    });
});

auth.authn(async (idToken, profile) => {
    app.ports.onAuthStateChanged.send(
        idToken ? { idToken, id: profile.uid, ...profile } : null
    );
});

app.ports.selectTextById.subscribe(id => {
    document.getElementById(id).select();
});

app.ports.openFullscreen.subscribe(() => {
    openFullscreen();
});

app.ports.closeFullscreen.subscribe(() => {
    closeFullscreen();
});

const attachApp = (app, list) => {
    list.forEach(l => l(app));
};

attachApp(app, [initDowonlad, initShare, initDB]);

if ("serviceWorker" in navigator && !location.host.startsWith("localhost")) {
    navigator.serviceWorker.register("/sw.js");
}

window.addEventListener("online", () => {
    app.ports.online.send(null);
});
window.addEventListener("offline", () => {
    app.ports.offline.send(null);
});
