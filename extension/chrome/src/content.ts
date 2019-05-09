import { Elm } from "./js/elm";

document.querySelectorAll('[lang="textusm"]').forEach(e => {
    const code = e.querySelector("code");
    if (code) {
        const text = code.textContent;
        if (text) {
            Elm.Extension.Chrome.init({
                node: e,
                flags: { text }
            });
        }
    }
});
