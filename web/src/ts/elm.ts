import { Settings, DownloadInfo, Diagram, DiagramItem } from "./model";

export interface EditorOption {
    fontSize: number;
    wordWrap: boolean;
    showLineNumber: boolean;
}

export interface Send<T> {
    send: (params: T) => void;
}

export interface Subscribe<T> {
    subscribe: (callback: T) => void;
    unsubscribe: (callback: T) => void;
}

export type ElmApp = {
    ports: {
        saveSettings: Subscribe<(settings: Settings) => void>;
        loadEditor: Subscribe<([text, option]: [string, EditorOption]) => void>;
        signIn: Subscribe<(provider: string) => void>;
        signOut: Subscribe<() => Promise<void>>;
        selectTextById: Subscribe<(id: string) => void>;
        openFullscreen: Subscribe<() => void>;
        closeFullscreen: Subscribe<() => void>;
        focusEditor: Subscribe<() => void>;
        loadText: Subscribe<(text: string) => void>;
        setEditorLanguage: Subscribe<(languageId: string) => void>;
        layoutEditor: Subscribe<(delay: number) => void>;
        downloadSvg: Subscribe<(download: DownloadInfo) => void>;
        downloadPdf: Subscribe<(download: DownloadInfo) => void>;
        downloadPng: Subscribe<(download: DownloadInfo) => void>;
        downloadHtml: Subscribe<(download: DownloadInfo) => void>;
        saveDiagram: Subscribe<(diagram: Diagram) => void>;
        removeDiagrams: Subscribe<(diagram: Diagram) => Promise<void>>;
        getDiagram: Subscribe<(diagramId: string) => Promise<void>>;
        getDiagrams: Subscribe<() => Promise<void>>;
        encodeShareText: Subscribe<(obj: { [s: string]: string }) => void>;
        decodeShareText: Subscribe<(text: string) => void>;
        importDiagram: Subscribe<(diagrams: DiagramItem[]) => void>;

        onErrorNotification: Send<string>;
        progress: Send<boolean>;
        changeText: Send<string>;
        shortcuts: Send<string>;
        startDownload: Send<{
            content: string;
            extension: string;
            mimeType: string;
        }>;
        downloadCompleted: Send<number[]>;
        saveToRemote: Send<DiagramItem>;
        saveToLocalCompleted: Send<DiagramItem>;
        removeRemoteDiagram: Send<Diagram>;
        reload: Send<string>;
        gotLocalDiagramJson: Send<DiagramItem>;
        gotLocalDiagramsJson: Send<DiagramItem[]>;
        onEncodeShareText: Send<string>;
        onDecodeShareText: Send<string>;
        onAuthStateChanged: Send<{
            idToken: string;
            id: string;
            displayName: string;
            email: string;
            photoURL: string;
        }>;
    };
};
