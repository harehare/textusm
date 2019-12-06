import * as LZUTF8 from "lzutf8";

// @ts-ignore
export const initShare = app => {
    // @ts-ignore
    app.ports.encodeShareText.subscribe(({ diagramType, title, text }) => {
        app.ports.onEncodeShareText.send(
            `/${diagramType}/${title ? title : "untitled"}/${encodeURIComponent(
                LZUTF8.compress(text, {
                    outputEncoding: "Base64"
                })
            )}`
        );
    });
    app.ports.decodeShareText.subscribe((text: string) => {
        app.ports.onDecodeShareText.send(
            LZUTF8.decompress(decodeURIComponent(text), {
                inputEncoding: "Base64",
                outputEncoding: "String"
            })
        );
    });
};
