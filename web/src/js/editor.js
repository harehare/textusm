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

export const loadEditor = (app, text) => {
    setTimeout(() => {
        const editor = document.getElementById("editor");

        if (!editor || editor.innerHTML !== "") {
            return;
        }

        const monacoEditor = monaco.editor.create(editor, {
            value: text,
            language: location.pathname.startsWith("/md")
                ? "markdown"
                : "userStoryMap",
            theme: "usmTheme",
            lineNumbers: "on",
            minimap: {
                enabled: false
            }
        });

        monacoEditor._standaloneKeybindingService.addDynamicKeybinding(
            "-actions.find"
        );

        monacoEditor.addAction({
            id: "open",
            label: "open",
            keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_O],
            precondition: null,
            keybindingContext: null,
            contextMenuOrder: 1.5,
            run: () => {
                app.ports.shortcuts.send("open");
            }
        });

        monacoEditor.addAction({
            id: "save-to-local",
            label: "save",
            keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_S],
            precondition: null,
            keybindingContext: null,
            contextMenuOrder: 1.5,
            run: () => {
                app.ports.shortcuts.send("save");
            }
        });

        window.onresize = () => {
            monacoEditor.layout();
        };

        app.ports.loadText.subscribe(text => {
            monacoEditor.setValue(text);
        });

        app.ports.setEditorLanguage.subscribe(mode => {
            const model = monacoEditor.getModel();
            monaco.editor.setModelLanguage(model, mode);
        });

        app.ports.layoutEditor.subscribe(delay => {
            setTimeout(() => {
                monacoEditor.layout();
            }, delay);
        });

        app.ports.errorLine.subscribe(err => {
            if (err !== "") {
                const errLines = err.split("\n");
                const errLine = errLines.length > 1 ? errLines[1] : err;
                const res = monacoEditor.getModel().findNextMatch(
                    errLine,
                    {
                        lineNumber: 1,
                        column: 1
                    },
                    false,
                    false,
                    null,
                    false
                );

                if (res) {
                    monaco.editor.setModelMarkers(
                        monacoEditor.getModel(),
                        "usm",
                        [
                            {
                                severity: 8,
                                startColumn: res.range.startColumn,
                                startLineNumber: res.range.startLineNumber,
                                endColumn: res.range.endColumn,
                                endLineNumber: res.range.startLineNumber,
                                message: "unexpected indent."
                            }
                        ]
                    );
                }
            } else {
                monaco.editor.setModelMarkers(
                    monacoEditor.getModel(),
                    "usm",
                    []
                );
            }
        });

        app.ports.selectLine.subscribe(line => {
            monacoEditor.setPosition({
                column: 0,
                lineNumber: line
            });
        });

        let update = null;

        monacoEditor.onDidChangeModelContent(e => {
            if (e.changes.length > 0) {
                if (update) {
                    clearTimeout(update);
                    update = null;
                }
                update = setTimeout(() => {
                    app.ports.changeText.send(monacoEditor.getValue());
                }, 500);
            }
        });
    }, 100);
};
