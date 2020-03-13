import * as monaco from "monaco-editor";

monaco.languages.register({
    id: "userStoryMap"
});

monaco.languages.setMonarchTokensProvider("userStoryMap", {
    tokenizer: {
        root: [
            [/#.+/, "comment"],
            [/^[^ ][^#:]+/, "activity"],
            [/^ {8}[^#:]+/, "story"],
            [/^ {4}[^#:]+/, "task"]
        ]
    }
});

monaco.editor.defineTheme("usmTheme", {
    base: "vs-dark",
    inherit: true,
    colors: {
        "editor.background": "#273037"
    },
    rules: [
        {
            token: "comment",
            foreground: "#008800"
        },
        {
            token: "activity",
            foreground: "#439ad9"
        },
        {
            token: "task",
            foreground: "#3a5aba"
        },
        {
            token: "story",
            foreground: "#c4c0b9"
        }
    ]
});

let monacoEditor: monaco.editor.IStandaloneCodeEditor | null = null;

export interface EditorOption {
    fontSize: number;
    wordWrap: boolean;
    showLineNumber: boolean;
}

// @ts-ignore
export const loadEditor = (
    // @ts-ignore
    app,
    text: string,
    { fontSize, wordWrap, showLineNumber }: EditorOption = {
        fontSize: 14,
        wordWrap: false,
        showLineNumber: true
    }
) => {
    setTimeout(() => {
        const editor = document.getElementById("editor");

        if (!editor) {
            return;
        }

        const value = monacoEditor ? monacoEditor.getValue() : text;

        if (monacoEditor) {
            monacoEditor.dispose();
        }

        monacoEditor = monaco.editor.create(editor, {
            value,
            language: location.pathname.startsWith("/md")
                ? "markdown"
                : "userStoryMap",
            theme: "usmTheme",
            lineNumbers: showLineNumber ? "on" : "off",
            wordWrap: wordWrap ? "on" : "off",
            minimap: {
                enabled: false
            },
            fontSize,
            mouseWheelZoom: true
        });

        // @ts-ignore
        monacoEditor._standaloneKeybindingService.addDynamicKeybinding(
            "-actions.find"
        );

        monacoEditor.addAction({
            id: "open",
            label: "open",
            keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_O],
            contextMenuOrder: 1.5,
            run: () => {
                app.ports.shortcuts.send("open");
            }
        });

        monacoEditor.addAction({
            id: "save-to-local",
            label: "save",
            keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_S],
            contextMenuOrder: 1.5,
            run: () => {
                app.ports.shortcuts.send("save");
            }
        });

        window.onresize = () => {
            if (monacoEditor) {
                monacoEditor.layout();
            }
        };

        app.ports.loadText.subscribe((text: string) => {
            if (monacoEditor) {
                monacoEditor.setValue(text);
            }
        });

        app.ports.setEditorLanguage.subscribe((languageId: string) => {
            if (!monacoEditor) {
                return;
            }

            const model = monacoEditor.getModel();

            if (model) {
                monaco.editor.setModelLanguage(model, languageId);
            }
        });

        app.ports.layoutEditor.subscribe((delay: number) => {
            setTimeout(() => {
                if (!monacoEditor) return;
                monacoEditor.layout();
            }, delay);
        });

        let update: number | null = null;

        monacoEditor.onDidChangeModelContent(e => {
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
                }, 500);
            }
        });
    }, 100);
};
