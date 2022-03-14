import { Settings, DownloadInfo, Diagram, DiagramItem } from './model';

type Provider = 'Google' | 'Github';

interface Send<T> {
    send: (params: T) => void;
}

interface Subscribe<T> {
    subscribe: (callback: T) => void;
    unsubscribe: (callback: T) => void;
}

type ElmApp = {
    ports: {
        saveSettings: Subscribe<(settings: Settings) => void>;
        signIn: Subscribe<(provider: Provider) => void>;
        signOut: Subscribe<() => Promise<void>>;
        refreshToken: Subscribe<() => Promise<void>>;
        selectTextById: Subscribe<(id: string) => void>;
        openFullscreen: Subscribe<() => void>;
        closeFullscreen: Subscribe<() => void>;
        focusEditor: Subscribe<() => void>;
        downloadSvg: Subscribe<(download: DownloadInfo) => void>;
        downloadPdf: Subscribe<(download: DownloadInfo) => void>;
        downloadPng: Subscribe<(download: DownloadInfo) => void>;
        downloadHtml: Subscribe<(download: DownloadInfo) => void>;
        copyToClipboardPng: Subscribe<(download: DownloadInfo) => void>;
        saveDiagram: Subscribe<(diagram: Diagram) => void>;
        removeDiagrams: Subscribe<(diagram: Diagram) => Promise<void>>;
        getDiagram: Subscribe<(diagramId: string) => Promise<void>>;
        getDiagrams: Subscribe<() => Promise<void>>;
        importDiagram: Subscribe<(diagrams: DiagramItem[]) => void>;
        copyText: Subscribe<(text: string) => void>;
        getGithubAccessToken: Subscribe<(cmd: string) => void>;
        openLocalFile: Subscribe<() => Promise<void>>;
        saveLocalFile: Subscribe<(diagram: Diagram) => Promise<void>>;
        closeLocalFile: Subscribe<() => void>;
        insertText: Subscribe<(text: string) => void>;

        gotGithubAccessToken: Send<{ cmd: string; accessToken: string | null }>;
        fullscreen: Send<boolean>;
        sendErrorNotification: Send<string>;
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
        updateIdToken: Send<string>;
        onAuthStateChanged: Send<{
            idToken: string;
            id: string;
            displayName: string;
            email: string;
            photoURL: string;
            loginProvider: {
                provider: string | null;
                accessToken: string | null;
            };
        } | null>;
        changeNetworkState: Send<boolean>;
        notifyNewVersionAvailable: Send<string>;
        openedLocalFile: Send<[string, string]>;
        savedLocalFile: Send<string>;
    };
};

export { Provider, ElmApp };
