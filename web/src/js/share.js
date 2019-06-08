import LZUTF8 from "lzutf8";

export const setUpShare = app => {
    app.ports.encodeShareText.subscribe(({ diagramType, title, text }) => {
        execCopy(
            `${location.protocol}//${location.host}/share/${diagramType}/${
                title ? title : "untitled"
            }/${encodeURIComponent(
                LZUTF8.compress(text, {
                    outputEncoding: "Base64"
                })
            )}`
        );
        app.ports.onNotification.send("Copy URL to Clipboard");
    });
    app.ports.decodeShareText.subscribe(text => {
        app.ports.onDecodeShareText.send(
            LZUTF8.decompress(decodeURIComponent(text), {
                inputEncoding: "Base64",
                outputEncoding: "String"
            })
        );
    });
};

function execCopy(copy) {
    const temp = document.createElement("textarea");

    temp.value = copy;
    temp.selectionStart = 0;
    temp.selectionEnd = temp.value.length;
    temp.style.display = "none%";

    document.body.appendChild(temp);
    temp.focus();
    const result = document.execCommand("copy");
    temp.blur();
    document.body.removeChild(temp);
    return result;
}
