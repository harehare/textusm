import { Settings, DownloadInfo, Diagram, DiagramItem } from "./model";
import { EditorOption } from "./editor";

export interface Js2ElmPort<T> {
    send: (params: T) => void;
}

export interface Elm2JsPort<T> {
    subscribe: (callback: T) => void;
    unsubscribe: (callback: T) => void;
}

export type ElmApp = {
    ports: {
        saveSettings: Elm2JsPort<(settings: Settings) => void>;
        loadEditor: Elm2JsPort<
            ([text, option]: [string, EditorOption]) => void
        >;
        signIn: Elm2JsPort<(provider: string) => void>;
        signOut: Elm2JsPort<() => Promise<void>>;
        selectTextById: Elm2JsPort<(id: string) => void>;
        openFullscreen: Elm2JsPort<() => void>;
        closeFullscreen: Elm2JsPort<() => void>;
        focusEditor: Elm2JsPort<() => void>;
        loadText: Elm2JsPort<(text: string) => void>;
        setEditorLanguage: Elm2JsPort<(languageId: string) => void>;
        layoutEditor: Elm2JsPort<(delay: number) => void>;
        downloadSvg: Elm2JsPort<(download: DownloadInfo) => void>;
        downloadPdf: Elm2JsPort<(download: DownloadInfo) => void>;
        downloadPng: Elm2JsPort<(download: DownloadInfo) => void>;
        downloadHtml: Elm2JsPort<(download: DownloadInfo) => void>;
        saveDiagram: Elm2JsPort<(diagram: Diagram) => void>;
        removeDiagrams: Elm2JsPort<(diagram: Diagram) => Promise<void>>;
        getDiagram: Elm2JsPort<(diagramId: string) => Promise<void>>;
        getDiagrams: Elm2JsPort<() => Promise<void>>;
        encodeShareText: Elm2JsPort<(obj: { [s: string]: string }) => void>;
        decodeShareText: Elm2JsPort<(text: string) => void>;

        onErrorNotification: Js2ElmPort<string>;
        progress: Js2ElmPort<boolean>;
        changeText: Js2ElmPort<string>;
        shortcuts: Js2ElmPort<string>;
        startDownload: Js2ElmPort<{
            content: string;
            extension: string;
            mimeType: string;
        }>;
        downloadCompleted: Js2ElmPort<number[]>;
        saveToRemote: Js2ElmPort<DiagramItem>;
        saveToLocalCompleted: Js2ElmPort<DiagramItem>;
        removeRemoteDiagram: Js2ElmPort<Diagram>;
        reload: Js2ElmPort<string>;
        gotLocalDiagramJson: Js2ElmPort<DiagramItem>;
        gotLocalDiagramsJson: Js2ElmPort<DiagramItem[]>;
        onEncodeShareText: Js2ElmPort<string>;
        onDecodeShareText: Js2ElmPort<string>;
        onAuthStateChanged: Js2ElmPort<{
            idToken: string;
            id: string;
            displayName: string;
            email: string;
            photoURL: string;
        }>;
    };
};
