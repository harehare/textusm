"use strict";

import "./styles.scss";
import { loadEditor } from "./js/editor.js";
import { setUpDowonlad } from "./js/download";
import { setUpShare } from "./js/share";
import { setUpDB } from "./js/db";
import { loadSettings, saveSettings } from "./js/settings";
import { Elm } from "./elm/Main.elm";

const app = Elm.Main.init({
    flags: [process.env.API_ROOT, loadSettings()]
});

app.ports.saveSettings.subscribe(settings => {
    saveSettings(settings);
});

app.ports.loadEditor.subscribe(text => {
    loadEditor(app, text);
});

setUpDowonlad(app);
setUpShare(app);
setUpDB(app);

if ("serviceWorker" in navigator && !location.host.startsWith("localhost")) {
    navigator.serviceWorker.register("/sw.js");
}
