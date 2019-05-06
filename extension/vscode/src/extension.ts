import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";

export function activate(context: vscode.ExtensionContext) {
    vscode.workspace
        .getConfiguration()
        .update(
            "textusm.fontName",
            vscode.workspace.getConfiguration().get("editor.fontFamily")
        );
    context.subscriptions.push(
        vscode.commands.registerCommand("extension.showPreview", () => {
            FigurePanel.createOrShow(context);
        })
    );
    context.subscriptions.push(
        vscode.commands.registerCommand("extension.exportSvg", () => {
            if (FigurePanel.currentPanel) {
                FigurePanel.currentPanel.exportSvg();
            }
        })
    );
}

export function deactivate() {}

class FigurePanel {
    public static currentPanel: FigurePanel | undefined;
    public static readonly viewType = "textUSM";

    private readonly _panel: vscode.WebviewPanel;

    public static createOrShow(context: vscode.ExtensionContext) {
        const column = vscode.window.activeTextEditor
            ? vscode.window.activeTextEditor.viewColumn
            : vscode.ViewColumn.Two;
        const editor = vscode.window.activeTextEditor;
        const text = editor ? editor.document.getText() : "";
        const title = editor ? editor.document.fileName : "";
        const scriptSrc = vscode.Uri.file(
            path.join(context.extensionPath, "js", "elm.js")
        ).with({ scheme: "vscode-resource" });

        if (FigurePanel.currentPanel) {
            FigurePanel.currentPanel._update(scriptSrc, title, text);
            FigurePanel.currentPanel._panel.webview.postMessage({
                text
            });
            FigurePanel.currentPanel._panel.reveal(
                column ? column + 1 : vscode.ViewColumn.Two
            );
            FigurePanel.currentPanel._addTextChangedEvent(editor);
            return;
        }

        const panel = vscode.window.createWebviewPanel(
            FigurePanel.viewType,
            "TextUSM",
            column ? column + 1 : vscode.ViewColumn.Two,
            {
                enableScripts: true,
                localResourceRoots: [
                    vscode.Uri.file(path.join(context.extensionPath, "js"))
                ]
            }
        );

        FigurePanel.currentPanel = new FigurePanel(
            panel,
            scriptSrc,
            title,
            text
        );
        FigurePanel.currentPanel._addTextChangedEvent(editor);
    }

    private constructor(
        panel: vscode.WebviewPanel,
        scriptSrc: vscode.Uri,
        title: string,
        text: string
    ) {
        this._panel = panel;
        this._update(scriptSrc, title, text);
        this._panel.onDidDispose(() => this.dispose());
    }

    public dispose() {
        FigurePanel.currentPanel = undefined;
        this._panel.dispose();
    }

    public exportSvg() {
        this._panel.webview.onDidReceiveMessage(message => {
            if (message.command === "exportSvg") {
                console.log(message);
                const dir = vscode.workspace
                    .getConfiguration()
                    .get("textusm.exportDir");
                const filePath = `${dir ? dir.toString() : "."}/${
                    this._panel.title
                }.svg`;
                fs.writeFileSync(
                    filePath,
                    `<?xml version="1.0"?>
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024" style="background-color: #F5F5F6;">
                    ${message.text
                        .split("<div")
                        .join('<div xmlns="http://www.w3.org/1999/xhtml"')}
                    </svg>`
                );
                vscode.window.showInformationMessage(`Exported: ${filePath}`);
            }
        });
        this._panel.webview.postMessage({
            command: "exportSvg"
        });
    }

    private _update(scriptSrc: vscode.Uri, title: string, text: string) {
        this._panel.title = `${title}`;
        console.log(this.getWebviewContent(scriptSrc, text));
        this._panel.webview.html = this.getWebviewContent(scriptSrc, text);
    }

    private _addTextChangedEvent(editor: vscode.TextEditor | undefined) {
        vscode.workspace.onDidChangeTextDocument(e => {
            if (editor) {
                if (e.document.uri === editor.document.uri) {
                    this._panel.webview.postMessage({
                        command: "textChanged",
                        text: e.document.getText()
                    });
                }
            }
        });
    }

    private getWebviewContent(scriptSrc: vscode.Uri, text: string) {
        // TODO: settings
        const fontName = vscode.workspace
            .getConfiguration()
            .get("textusm.fontName");
        const backgroundColor = vscode.workspace
            .getConfiguration()
            .get("textusm.backgroundColor");

        const activityColor = vscode.workspace
            .getConfiguration()
            .get("textusm.activity.color");
        const activityBackground = vscode.workspace
            .getConfiguration()
            .get("textusm.activity.backgroundColor");

        const taskColor = vscode.workspace
            .getConfiguration()
            .get("textusm.task.color");
        const taskBackground = vscode.workspace
            .getConfiguration()
            .get("textusm.task.backgroundColor");

        const storyColor = vscode.workspace
            .getConfiguration()
            .get("textusm.story.color");
        const storyBackground = vscode.workspace
            .getConfiguration()
            .get("textusm.story.backgroundColor");

        return `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TextUSM</title>
    <script src="${scriptSrc.toString()}"/>
    <script>
        document.getElementById("svg").innerHTML = 'Load SVG...';
    </script>
</head>
<body>
    <div id="svg"></div>
    <script>
        const vscode = acquireVsCodeApi();
        const app = Elm.Extension.VSCode.init({
            node: document.getElementById("svg"),
            flags: {text: \`${text}\`, fontName: "${fontName}",
            backgroundColor: "${
                backgroundColor ? backgroundColor : "transparent"
            }",
            activityBackgroundColor: "${
                activityBackground ? activityBackground : "#266B9A"
            }",
            activityColor: "${activityColor ? activityColor : "#FFFFFF"}",
            taskColor: "${taskColor ? taskColor : "#FFFFFF"}",
            taskBackgroundColor: "${
                taskBackground ? taskBackground : "#3E9BCD"
            }",
            storyColor: "${storyColor ? storyColor : "#000000"}",
            storyBackgroundColor: "${
                storyBackground ? storyBackground : "#FFFFFF"
            }"
        }});
        window.addEventListener('message', event => {
            const message = event.data;

            if (message.command === 'textChanged') {
                app.ports.onTextChanged.send(message.text);
            } else if (message.command === 'exportSvg') {
                const usm = document.querySelector('#usm-area');
                const zoomControl = usm.querySelector('#zoom-control');

                usm.removeChild(zoomControl);

                vscode.postMessage({
                    command: 'exportSvg',
                    text: usm.innerHTML
                })
            }
        });
    </script>
</body>
</html>`;
    }
}
