interface Navigator {
    language: string;
    userLanguage: string;
    browserLanguage: string;
    languages: string[];
}

interface HTMLElement {
    mozRequestFullScreen: () => Promise<void>;
    webkitRequestFullscreen: () => Promise<void>;
    msRequestFullscreen: () => Promise<void>;
}

interface Document {
    mozCancelFullScreen: () => Promise<void>;
    webkitExitFullscreen: () => Promise<void>;
    msExitFullscreen: () => Promise<void>;
}
