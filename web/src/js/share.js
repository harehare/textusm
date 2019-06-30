import LZUTF8 from "lzutf8";

export const initShare = app => {
    app.ports.encodeShareText.subscribe(({ diagramType, title, text }) => {
        app.ports.onEncodeShareText.send(
            `${location.protocol}//${location.host}/share/${diagramType}/${
                title ? title : "untitled"
            }/${encodeURIComponent(
                LZUTF8.compress(text, {
                    outputEncoding: "Base64"
                })
            )}`
        );
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
