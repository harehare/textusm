interface ElmApp {
  ports: {
    [key: string]: {
      send: (value: unknown) => void;
      subscribe: (callback: (value: unknown) => void) => void;
    };
  };
}

interface ElmModule {
  Extension: {
    Lib: {
      init: (options: { node: HTMLElement; flags: unknown }) => ElmApp;
    };
  };
}

export declare const Elm: ElmModule;
