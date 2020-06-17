import { ElmApp } from "./elm";
import * as monaco from "monaco-editor";
import { sleep } from "./utils";

export interface EditorOption {
    fontSize: number;
    wordWrap: boolean;
    showLineNumber: boolean;
}

let monacoEditor: monaco.editor.IStandaloneCodeEditor | null = null;

const loadText = (text: string) => {
    if (monacoEditor) {
        monacoEditor.setValue(text);
    }
};

const focusEditor = () => {
    setTimeout(() => {
        if (monacoEditor) monacoEditor.focus();
    }, 100);
};

const setEditorLanguage = (languageId: string) => {
    if (!monacoEditor) {
        return;
    }

    const model = monacoEditor.getModel();

    if (model) {
        monaco.editor.setModelLanguage(model, languageId);
    }
};

const layout = (delay: number) => {
    setTimeout(() => {
        if (!monacoEditor) return;
        monacoEditor.layout();
    }, delay);
};

// @ts-ignore
export const loadEditor = async (
    app: ElmApp,
    text: string,
    { fontSize, wordWrap, showLineNumber }: EditorOption = {
        fontSize: 14,
        wordWrap: false,
        showLineNumber: true,
    }
) => {
    monaco.languages.register({
        id: "userStoryMap",
    });

    monaco.languages.setMonarchTokensProvider("userStoryMap", {
        tokenizer: {
            root: [
                [/#.+/, "comment"],
                [/^[^ ][^#:]+/, "activity"],
                [/^ {8}[^#:]+/, "story"],
                [/^ {4}[^#:]+/, "task"],
            ],
        },
    });

    monaco.editor.defineTheme("usmTheme", {
        base: "vs-dark",
        inherit: true,
        colors: {
            "editor.background": "#273037",
        },
        rules: [
            {
                token: "comment",
                foreground: "#008800",
            },
            {
                token: "activity",
                foreground: "#439ad9",
            },
            {
                token: "task",
                foreground: "#3a5aba",
            },
            {
                token: "story",
                foreground: "#c4c0b9",
            },
        ],
    });

    let editor = null;
    let tryCount = 0;

    while (!editor) {
        editor = document.getElementById("editor");
        tryCount++;
        if (tryCount > 10) {
            return;
        }
        await sleep(100);
    }

    if (monacoEditor) {
        monacoEditor.dispose();
    }
    monacoEditor = monaco.editor.create(editor, {
        value: text,
        language: location.pathname.startsWith("/md")
            ? "markdown"
            : "userStoryMap",
        theme: "usmTheme",
        lineNumbers: showLineNumber ? "on" : "off",
        wordWrap: wordWrap ? "on" : "off",
        minimap: {
            enabled: false,
        },
        fontSize,
        mouseWheelZoom: true,
        automaticLayout: true,
        scrollbar: {
            verticalScrollbarSize: 6,
            horizontalScrollbarSize: 6,
        },
    });

    // @ts-ignore
    monacoEditor._standaloneKeybindingService.addDynamicKeybinding(
        "-actions.find"
    );

    monacoEditor.addAction({
        id: "open",
        label: "open",
        keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_O],
        contextMenuOrder: 1,
        run: () => {
            app.ports.shortcuts.send("open");
        },
    });

    monacoEditor.addAction({
        id: "save-to-local",
        label: "save",
        keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_S],
        contextMenuOrder: 2,
        run: () => {
            app.ports.shortcuts.send("save");
        },
    });

    app.ports.loadText.unsubscribe(loadText);
    app.ports.loadText.subscribe(loadText);

    app.ports.focusEditor.unsubscribe(focusEditor);
    app.ports.focusEditor.subscribe(focusEditor);

    app.ports.setEditorLanguage.unsubscribe(setEditorLanguage);
    app.ports.setEditorLanguage.subscribe(setEditorLanguage);

    app.ports.layoutEditor.unsubscribe(layout);
    app.ports.layoutEditor.subscribe(layout);

    let update: number | null = null;

    monacoEditor.onDidChangeModelContent((e) => {
        if (e.changes.length > 0) {
            if (update) {
                window.clearTimeout(update);
                update = null;
            }
            update = window.setTimeout(() => {
                if (!monacoEditor) {
                    return;
                }
                app.ports.changeText.send(monacoEditor.getValue());
            }, 300);
        }
    });
};
