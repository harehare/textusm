import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

export function activate(context: vscode.ExtensionContext) {
  vscode.workspace
    .getConfiguration()
    .update('textusm.fontName', vscode.workspace.getConfiguration().get('editor.fontFamily'));
  context.subscriptions.push(
    vscode.commands.registerCommand('extension.showPreview', () => {
      DiagramPanel.createOrShow(context);
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand('extension.exportSvg', () => {
      DiagramPanel.createOrShow(context);
      if (DiagramPanel.currentPanel) {
        DiagramPanel.currentPanel.exportSvg();
      }
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand('extension.exportPng', () => {
      DiagramPanel.createOrShow(context);
      if (DiagramPanel.currentPanel) {
        DiagramPanel.currentPanel.exportPng();
      }
    })
  );
}

export function deactivate() {}

class DiagramPanel {
  public static currentPanel: DiagramPanel | undefined;
  public static readonly viewType = 'textUSM';

  private readonly _panel: vscode.WebviewPanel;

  public static createOrShow(context: vscode.ExtensionContext) {
    const column = vscode.window.activeTextEditor ? vscode.window.activeTextEditor.viewColumn : vscode.ViewColumn.Two;
    const editor = vscode.window.activeTextEditor;
    const text = editor ? editor.document.getText() : '';
    const title = editor ? editor.document.fileName : '';
    const scriptSrc = vscode.Uri.file(path.join(context.extensionPath, 'js', 'elm.js')).with({
      scheme: 'vscode-resource'
    });

    if (DiagramPanel.currentPanel) {
      DiagramPanel.currentPanel._update(scriptSrc, title, text);
      DiagramPanel.currentPanel._panel.webview.postMessage({
        text
      });
      DiagramPanel.currentPanel._panel.reveal(column ? column + 1 : vscode.ViewColumn.Two);
      DiagramPanel.currentPanel._addTextChangedEvent(editor);
      return;
    }

    const panel = vscode.window.createWebviewPanel(
      DiagramPanel.viewType,
      'TextUSM',
      column ? column + 1 : vscode.ViewColumn.Two,
      {
        enableScripts: true,
        localResourceRoots: [vscode.Uri.file(path.join(context.extensionPath, 'js'))]
      }
    );

    const figurePanel = new DiagramPanel(panel, scriptSrc, title, text);

    DiagramPanel.currentPanel = figurePanel;
    DiagramPanel.currentPanel._addTextChangedEvent(editor);

    figurePanel._panel.webview.onDidReceiveMessage(message => {
      if (message.command === 'exportPng') {
        const dir = vscode.workspace.getConfiguration().get('textusm.exportDir');
        const filePath = `${dir ? dir.toString() : '.'}/${figurePanel._panel.title}.png`;
        const base64Data = message.text.replace(/^data:image\/png;base64,/, '');

        fs.writeFileSync(filePath, base64Data, 'base64');
        vscode.window.showInformationMessage(`Exported: ${filePath}`);
      } else if (message.command === 'exportSvg') {
        const backgroundColor = vscode.workspace.getConfiguration().get('textusm.backgroundColor');
        const dir = vscode.workspace.getConfiguration().get('textusm.exportDir');
        const filePath = `${dir ? dir.toString() : '.'}/${figurePanel._panel.title}.svg`;
        fs.writeFileSync(
          filePath,
          `<?xml version="1.0"?>
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${message.width} ${message.height}" width="${
            message.width
          }" height="${message.height}" style="background-color: ${backgroundColor};">
                    ${message.text.split('<div').join('<div xmlns="http://www.w3.org/1999/xhtml"')}
                    </svg>`
        );
        vscode.window.showInformationMessage(`Exported: ${filePath}`);
      }
    });
  }

  private constructor(panel: vscode.WebviewPanel, scriptSrc: vscode.Uri, title: string, text: string) {
    this._panel = panel;
    this._update(scriptSrc, title, text);
    this._panel.onDidDispose(() => this.dispose());
  }

  public dispose() {
    DiagramPanel.currentPanel = undefined;
    this._panel.dispose();
  }

  public exportPng() {
    const backgroundColor = vscode.workspace.getConfiguration().get('textusm.backgroundColor');
    this._panel.webview.postMessage({
      command: 'exportPng',
      backgroundColor
    });
  }

  public exportSvg() {
    this._panel.webview.postMessage({
      command: 'exportSvg'
    });
  }

  private _update(scriptSrc: vscode.Uri, title: string, text: string) {
    this._panel.title = `${title}`;
    this._panel.webview.html = this.getWebviewContent(scriptSrc, text);
  }

  private _addTextChangedEvent(editor: vscode.TextEditor | undefined) {
    let updated: null | NodeJS.Timeout = null;
    vscode.workspace.onDidChangeTextDocument(e => {
      if (editor) {
        if (e.document.uri === editor.document.uri) {
          if (updated) {
            clearTimeout(updated);
          }
          updated = setTimeout(() => {
            this._panel.webview.postMessage({
              command: 'textChanged',
              text: e.document.getText()
            });
          }, 1000);
        }
      }
    });
  }

  private getWebviewContent(scriptSrc: vscode.Uri, text: string) {
    // TODO: settings
    const fontName = vscode.workspace.getConfiguration().get('textusm.fontName');
    const backgroundColor = vscode.workspace.getConfiguration().get('textusm.backgroundColor');

    const activityColor = vscode.workspace.getConfiguration().get('textusm.activity.color');
    const activityBackground = vscode.workspace.getConfiguration().get('textusm.activity.backgroundColor');

    const taskColor = vscode.workspace.getConfiguration().get('textusm.task.color');
    const taskBackground = vscode.workspace.getConfiguration().get('textusm.task.backgroundColor');

    const storyColor = vscode.workspace.getConfiguration().get('textusm.story.color');
    const storyBackground = vscode.workspace.getConfiguration().get('textusm.story.backgroundColor');

    const diagramType = vscode.workspace.getConfiguration().get('textusm.diagramType');

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
            backgroundColor: "${backgroundColor ? backgroundColor : 'transparent'}",
            activityBackgroundColor: "${activityBackground ? activityBackground : '#266B9A'}",
            activityColor: "${activityColor ? activityColor : '#FFFFFF'}",
            taskColor: "${taskColor ? taskColor : '#FFFFFF'}",
            taskBackgroundColor: "${taskBackground ? taskBackground : '#3E9BCD'}",
            storyColor: "${storyColor ? storyColor : '#000000'}",
            storyBackgroundColor: "${storyBackground ? storyBackground : '#FFFFFF'}",
            diagramType: "${diagramType}"
        }});
        const createSvg = (svgHTML, backgroundColor, width, height) => {
            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
            svg.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
            svg.setAttribute('width', width);
            svg.setAttribute('height', height);
            svg.setAttribute('style', 'background-color: ' + backgroundColor)
            svg.innerHTML = svgHTML
            return svg
        }
        window.addEventListener('message', event => {
            const message = event.data;

            if (message.command === 'textChanged') {
                app.ports.onTextChanged.send(message.text);
            } else if (message.command === 'exportSvg') {
                const usm = document.querySelector('#usm-area').cloneNode(true);
                const usmSvg = usm.querySelector('#usm');
                const zoomControl = usm.querySelector('#zoom-control');

                try {
                    usm.removeChild(zoomControl);
                } catch {}

                vscode.postMessage({
                    command: 'exportSvg',
                    text: usm.innerHTML,
                    width: usmSvg.getAttribute('width'),
                    height: usmSvg.getAttribute('height')
                })
            } else if (message.command === 'exportPng') {
                const usm = document.querySelector('#usm-area').cloneNode(true);
                const usmSvg = usm.querySelector('#usm');
                const zoomControl = usm.querySelector('#zoom-control');

                try {
                    usm.removeChild(zoomControl);
                } catch {}

                const canvas = document.createElement('canvas')
                canvas.setAttribute('width', usmSvg.getAttribute('width'));
                canvas.setAttribute('height', usmSvg.getAttribute('height'));
                canvas.style.display = 'none'

                const context = canvas.getContext('2d')
                const img = new Image()
                img.addEventListener('load', () => {
                    context.drawImage(img, 0, 0)
                    const url = canvas.toDataURL('image/png')
                    setTimeout(() => {
                        canvas.remove()
                        vscode.postMessage({
                            command: 'exportPng',
                            text: url
                        })
                    }, 10)
                }, false)
                img.src = 'data:image/svg+xml;utf8,' + encodeURIComponent(new XMLSerializer().serializeToString(
                    createSvg(usmSvg.innerHTML,
                              message.backgroundColor,
                              usmSvg.getAttribute('width'),
                              usmSvg.getAttribute('height')))
                )
            }
        });
    </script>
</body>
</html>`;
  }
}
