import copy from 'clipboard-copy';
import { Workbox } from 'workbox-window';

// @ts-expect-error: Unreachable code error
import { Elm } from '../elm/Main.elm';
import '../styles.css';
import {
  signOut,
  signIn,
  authStateChanged,
  providers,
  refreshToken,
  pollRefreshToken,
  signInGithubWithGist,
} from './auth';
import { initDB } from './db';
import { initDownload } from './download';
import { setElmApp } from './editor';
import { loadEditor } from './editor/lang';
import type { ElmApp, Provider } from './elm';
import { initFile, canUseNativeFileSystem } from './file';
import type { Settings } from './model';
import { loadSettings, saveSettings } from './settings';
import { isDarkMode } from './utils';

declare global {
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
}

const lang = navigator.languages[0] ?? navigator.language ?? navigator.userLanguage ?? navigator.browserLanguage;

type Flags = {
  lang: string | string[];
  settings: Settings;
  isOnline: boolean;
  isDarkMode: boolean;
  canUseClipboardItem: boolean;
  canUseNativeFileSystem: boolean;
};

declare type ElmType = {
  Main: {
    init: (flags: { flags: Flags }) => ElmApp;
  };
};

const settings = loadSettings(isDarkMode);

loadEditor(settings);

const app: ElmApp = (Elm as ElmType).Main.init({
  flags: {
    lang,
    settings,
    isOnline: window.navigator.onLine ?? true,
    isDarkMode,
    canUseClipboardItem: Boolean(ClipboardItem),
    canUseNativeFileSystem,
  },
});

setElmApp(app);
authStateChanged(
  () => {
    app.ports.progress.send(true);
  },
  () => {
    app.ports.progress.send(false);
  },
  async (idToken, user) => {
    if (user && idToken) {
      app.ports.onAuthStateChanged.send({
        idToken,
        id: user.id,
        displayName: user.displayName,
        email: user.email,
        photoURL: user.photoURL,
        loginProvider: {
          provider: user.provider,
          accessToken: user.accessToken,
        },
      });
    }
  }
);

app.ports.loadSettingsFromLocal.subscribe((diagramType: string) => {
  app.ports.loadSettingsFromLocalCompleted.send(loadSettings(isDarkMode, diagramType));
});

app.ports.saveSettingsToLocal.subscribe((settings: Settings) => {
  saveSettings(settings);
});

app.ports.signIn.subscribe(async (provider: Provider) => {
  switch (provider) {
    case 'Google': {
      await signIn(providers.google).catch(() => {
        app.ports.sendErrorNotification.send('Failed sign in.');
      });
      return;
    }

    case 'Github': {
      await signIn(providers.github).catch(() => {
        app.ports.sendErrorNotification.send('Failed sign in.');
      });
      return;
    }

    default: {
      await signIn(providers.google).catch(() => {
        app.ports.sendErrorNotification.send('Failed sign in.');
      });
    }
  }
});

app.ports.signOut.subscribe(async () => {
  await signOut().catch(() => {
    app.ports.sendErrorNotification.send('Failed sign out.');
  });
  app.ports.onAuthStateChanged.send(undefined);
});

app.ports.refreshToken.subscribe(async () => {
  const idToken = await refreshToken()?.catch(() => undefined);
  if (idToken) {
    app.ports.updateIdToken.send(idToken);
  }
});

app.ports.selectTextById.subscribe(async (id: string) => {
  const element = document.querySelector(`#${id}`);
  if (element) {
    const inputElement = element as HTMLInputElement;
    inputElement.select();
    if (navigator.clipboard) {
      await navigator.clipboard.writeText(inputElement.value).catch(() => {
        app.ports.sendErrorNotification.send('Failed copy text to clipboard.');
      });
    }
  }
});

app.ports.openFullscreen.subscribe(async () => {
  const element = document.documentElement;
  if (element.requestFullscreen) {
    await element.requestFullscreen();
  } else if (element.mozRequestFullScreen) {
    await element.mozRequestFullScreen();
  } else if (element.webkitRequestFullscreen) {
    await element.webkitRequestFullscreen();
  } else if (element.msRequestFullscreen) {
    await element.msRequestFullscreen();
  }
});

app.ports.closeFullscreen.subscribe(async () => {
  if (document.exitFullscreen) {
    await document.exitFullscreen();
  } else if (document.mozCancelFullScreen) {
    await document.mozCancelFullScreen();
  } else if (document.webkitExitFullscreen) {
    await document.webkitExitFullscreen();
  } else if (document.msExitFullscreen) {
    await document.msExitFullscreen();
  }
});

app.ports.copyText.subscribe(async (text: string) => {
  await copy(text);
});

app.ports.getGithubAccessToken.subscribe(async (cmd) => {
  const result = await signInGithubWithGist().catch(() => {
    app.ports.sendErrorNotification.send('Failed sign in.');
    return { accessToken: undefined };
  });
  app.ports.gotGithubAccessToken.send({
    cmd,
    accessToken: result.accessToken,
  });
});

for (const l of [initDownload, initDB, initFile]) {
  l(app);
}

window.requestIdleCallback(async () => {
  pollRefreshToken(app.ports.updateIdToken.send);

  document.addEventListener('fullscreenchange', () => {
    if (!document.fullscreenElement) {
      app.ports.fullscreen.send(false);
    }
  });

  window.addEventListener('offline', () => {
    app.ports.changeNetworkState.send(false);
  });

  window.addEventListener('online', () => {
    app.ports.changeNetworkState.send(true);
  });

  const loadSentry = async () => {
    if (process.env.SENTRY_ENABLE === '1' && process.env.SENTRY_DSN && process.env.SENTRY_RELEASE) {
      const sentry = await import('@sentry/browser');
      sentry.init({
        dsn: process.env.SENTRY_DSN,
        release: process.env.SENTRY_RELEASE,
      });
    }
  };

  if ('serviceWorker' in navigator && process.env.NODE_ENV === 'production') {
    const wb = new Workbox('/sw.js');
    await wb.register().catch(() => {
      // ignore error
    });
    wb.addEventListener('installed', (event) => {
      if (event.isUpdate) {
        app.ports.notifyNewVersionAvailable.send('New version is available!');
      }
    });
  }

  await loadSentry();
});
