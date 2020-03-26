import * as LZUTF8 from "lzutf8";
import { ElmApp } from "./elm";

export const initShare = (app: ElmApp) => {
    app.ports.encodeShareText.subscribe((params: { [s: string]: string }) => {
        app.ports.onEncodeShareText.send(
            `/${params.diagramType}/${
                params.title ? params.title : "untitled"
            }/${encodeURIComponent(
                LZUTF8.compress(params.text, {
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
