import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

const showQuickPick = (context: vscode.ExtensionContext, callback: () => void) => {
  const options = [
    { label: 'User Story Map', value: 'UserStoryMap' },
    { label: 'Business Model Canvas', value: 'BusinessModelCanvas' },
    { label: 'Opportunity Canvas', value: 'OpportunityCanvas' },
    { label: '4Ls Retrospective', value: '4Ls' },
    { label: 'Start, Stop, Continue Retrospective', value: 'StartStopContinue' },
    { label: 'KPT Retrospective', value: 'Kpt' }
  ];
  const quickPick = vscode.window.createQuickPick();
  quickPick.items = options.map(item => ({ label: item.label }));
  quickPick.onDidChangeSelection(selection => {
    if (selection.length > 0) {
      const label = selection[0].label;
      const values = options.filter(item => item.label === label);

      if (values.length > 0) {
        DiagramPanel.createOrShow(context, values[0].value);
        vscode.workspace.getConfiguration().update('textusm.diagramType', values[0].value);
        callback();
      }
    }
  });
  quickPick.onDidHide(() => quickPick.dispose());
  quickPick.show();
};

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.commands.registerCommand('extension.showPreview', () => {
      showQuickPick(context, () => {});
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand('extension.exportSvg', () => {
      showQuickPick(context, () => {
        if (DiagramPanel.currentPanel) {
          DiagramPanel.currentPanel.exportSvg();
        }
      });
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand('extension.exportPng', () => {
      showQuickPick(context, () => {
        if (DiagramPanel.currentPanel) {
          DiagramPanel.currentPanel.exportPng();
        }
      });
    })
  );
}

export function deactivate() {}

class DiagramPanel {
  public static currentPanel: DiagramPanel | undefined;
  public static readonly viewType = 'textUSM';

  private readonly _panel: vscode.WebviewPanel;

  public static createOrShow(context: vscode.ExtensionContext, diagramType: string) {
    const column = vscode.window.activeTextEditor ? vscode.window.activeTextEditor.viewColumn : vscode.ViewColumn.Two;
    const editor = vscode.window.activeTextEditor;
    const text = editor ? editor.document.getText() : '';
    const title = 'TextUSM';
    const scriptSrc = vscode.Uri.file(path.join(context.extensionPath, 'js', 'elm.js')).with({
      scheme: 'vscode-resource'
    });

    const iconPath = vscode.Uri.file(path.join(context.extensionPath, 'images', 'icon.png'));

    if (DiagramPanel.currentPanel) {
      DiagramPanel.currentPanel._update(iconPath, scriptSrc, title, text, diagramType);
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

    const figurePanel = new DiagramPanel(panel, iconPath, scriptSrc, title, text, diagramType);

    DiagramPanel.currentPanel = figurePanel;
    DiagramPanel.currentPanel._addTextChangedEvent(editor);

    figurePanel._panel.webview.onDidReceiveMessage(message => {
      if (message.command === 'exportPng') {
        const dir: string | undefined = vscode.workspace.getConfiguration().get('textusm.exportDir');
        const editor = vscode.window.activeTextEditor;
        const title = editor ? path.basename(editor.document.fileName) : 'untitled';
        const filePath = `${
          dir ? (dir.endsWith('/') ? dir.toString() : `${dir.toString()}/`) : `${vscode.workspace.rootPath}/`
        }${title}.png`;
        const base64Data = message.text.replace(/^data:image\/png;base64,/, '');

        fs.writeFileSync(filePath, base64Data, 'base64');
        vscode.window.showInformationMessage(`Exported: ${filePath}`);
      } else if (message.command === 'exportSvg') {
        const backgroundColor = vscode.workspace.getConfiguration().get('textusm.backgroundColor');
        const editor = vscode.window.activeTextEditor;
        const title = editor ? path.basename(editor.document.fileName) : 'untitled';
        const dir: string | undefined = vscode.workspace.getConfiguration().get('textusm.exportDir');
        const filePath = `${
          dir ? (dir.endsWith('/') ? dir.toString() : `${dir.toString()}/`) : `${vscode.workspace.rootPath}/`
        }${title}.svg`;
        const width = (parseInt(message.width) / 3) * 5;
        const height = (parseInt(message.height) / 3) * 4;

        fs.writeFileSync(
          filePath,
          `<?xml version="1.0"?>
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" width="${
            message.width
          }" height="${message.height}" style="background-color: ${backgroundColor};">
                    ${message.text.split('<div').join('<div xmlns="http://www.w3.org/1999/xhtml"')}
                    </svg>`
        );
        vscode.window.showInformationMessage(`Exported: ${filePath}`);
      }
    });
  }

  private constructor(
    panel: vscode.WebviewPanel,
    iconPath: vscode.Uri,
    scriptSrc: vscode.Uri,
    title: string,
    text: string,
    diagramType: string
  ) {
    this._panel = panel;
    this._update(iconPath, scriptSrc, title, text, diagramType);
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

  private _update(iconPath: vscode.Uri, scriptSrc: vscode.Uri, title: string, text: string, diagramType: string) {
    this._panel.iconPath = iconPath;
    this._panel.title = `${title}`;
    this._panel.webview.html = this.getWebviewContent(scriptSrc, text, diagramType);
  }

  private _addTextChangedEvent(editor: vscode.TextEditor | undefined) {
    let updated: null | NodeJS.Timeout = null;
    vscode.workspace.onDidChangeTextDocument(e => {
      if (editor) {
        if (e && e.document && editor && editor.document && e.document.uri === editor.document.uri) {
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

  private getWebviewContent(scriptSrc: vscode.Uri, text: string, diagramType: string) {
    const fontName = vscode.workspace.getConfiguration().get('textusm.fontName');
    const backgroundColor = vscode.workspace.getConfiguration().get('textusm.backgroundColor');

    const activityColor = vscode.workspace.getConfiguration().get('textusm.activity.color');
    const activityBackground = vscode.workspace.getConfiguration().get('textusm.activity.backgroundColor');

    const taskColor = vscode.workspace.getConfiguration().get('textusm.task.color');
    const taskBackground = vscode.workspace.getConfiguration().get('textusm.task.backgroundColor');

    const storyColor = vscode.workspace.getConfiguration().get('textusm.story.color');
    const storyBackground = vscode.workspace.getConfiguration().get('textusm.story.backgroundColor');

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
            const svgWidth = parseInt((parseInt(width) / 3) * 5);
            const svgHeight = parseInt((parseInt(height) / 3) * 4);
            svg.setAttribute('viewBox', '0 0 ' + svgWidth.toString() + ' ' + svgHeight.toString());
            svg.setAttribute('width', width);
            svg.setAttribute('height', height);
            svg.setAttribute('style', 'background-color: ' + backgroundColor);
            svg.innerHTML = svgHTML;
            return svg;
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
                // TODO:
                vscode.postMessage({
                    command: 'exportSvg',
                    text: usmSvg.innerHTML,
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

                const canvas = document.createElement('canvas');
                canvas.setAttribute('width', usmSvg.getAttribute('width'));
                canvas.setAttribute('height', usmSvg.getAttribute('height'));
                canvas.style.display = 'none';

                const context = canvas.getContext('2d');
                const img = new Image();

                img.addEventListener('load', () => {
                    context.drawImage(img, 0, 0);
                    const url = canvas.toDataURL('image/png');
                    setTimeout(() => {
                        canvas.remove();
                        vscode.postMessage({
                            command: 'exportPng',
                            text: url
                        })
                    }, 10);
                }, false);
                img.src = 'data:image/svg+xml;utf8,' + encodeURIComponent(new XMLSerializer().serializeToString(
                    createSvg(usmSvg.innerHTML,
                              message.backgroundColor,
                              usmSvg.getAttribute('width'),
                              usmSvg.getAttribute('height')))
                );
            }
        });
    </script>
</body>
</html>`;
  }
}
