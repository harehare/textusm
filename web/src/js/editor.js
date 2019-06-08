import * as monaco from "monaco-editor";

monaco.languages.register({
    id: "userStoryMapping"
});

monaco.languages.setMonarchTokensProvider("userStoryMapping", {
    tokenizer: {
        root: [
            [/:.+/, "note"],
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
        },
        {
            token: "note",
            foreground: "#F1B090"
        }
    ]
});

export const loadEditor = (app, text) => {
    setTimeout(() => {
        const editor = document.getElementById("editor");

        if (!editor || editor.innerHTML !== "") {
            return;
        }

        const monacoEditor = monaco.editor.create(
            document.getElementById("editor"),
            {
                value: text,
                language: "userStoryMapping",
                theme: "usmTheme",
                lineNumbers: "on",
                minimap: {
                    enabled: false
                }
            }
        );

        window.onresize = () => {
            monacoEditor.layout();
        };

        app.ports.loadText.subscribe(([text, indent]) => {
            if (indent) {
                const { column, lineNumber } = monacoEditor.getPosition();
                monacoEditor.setPosition({
                    column: column + 4,
                    lineNumber
                });
            }

            monacoEditor.setValue(text);
            monacoEditor.focus();
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
            const res = monacoEditor.getModel().findNextMatch(
                line,
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
                monacoEditor.focus();
                monacoEditor.setPosition({
                    column: res.range.startColumn,
                    lineNumber: res.range.startLineNumber
                });
            }
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
