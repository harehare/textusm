'use strict';

import './styles.scss';
import {
    loadEditor
} from './js/editor.js';
import {
    setUpDowonlad
} from './js/download';
import {
    setUpShare
} from './js/share';
import {
    loadSettings,
    setUpSettings,
    saveSettings
} from './js/settings';
import {
    Elm
} from './elm/Main.elm';

const app = Elm.Main.init({
    flags: loadSettings(app)
})

app.ports.saveSettings.subscribe(settings => {
    saveSettings(settings)
})

app.ports.loadEditor.subscribe(text => {
    loadEditor(app, text)
    setTimeout(() => {
        setUpSettings(app)
    }, 500)
})

setUpDowonlad(app)
setUpShare(app)

if ('serviceWorker' in navigator && !location.host.startsWith('localhost')) {
    navigator.serviceWorker.register('/sw.js')
}