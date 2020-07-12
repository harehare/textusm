import { ElmApp } from "./elm";

export const initShare = (app: ElmApp): void => {
    app.ports.encodeShareText.subscribe(
        async (params: { [s: string]: string }) => {
            const LZUTF8 = await import("lzutf8");
            app.ports.onEncodeShareText.send(
                `/${params.diagramType}/${
                    params.title ? params.title : "untitled"
                }/${encodeURIComponent(
                    LZUTF8.compress(params.text, {
                        outputEncoding: "Base64",
                    })
                )}`
            );
        }
    );
    app.ports.decodeShareText.subscribe(async (text: string) => {
        const LZUTF8 = await import("lzutf8");
        app.ports.onDecodeShareText.send(
            LZUTF8.decompress(decodeURIComponent(text), {
                inputEncoding: "Base64",
                outputEncoding: "String",
            })
        );
    });
};
