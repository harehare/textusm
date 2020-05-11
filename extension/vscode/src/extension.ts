import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";

const diagrams = [
  { label: "User Story Map", value: "usm" },
  { label: "Customer Journey Map", value: "cjm" },
  { label: "Empathy Map", value: "emm" },
  { label: "Impact Map", value: "imm" },
  { label: "Mind Map", value: "mmp" },
  { label: "Site Map", value: "smp" },
  { label: "Business Model Canvas", value: "bmc" },
  { label: "Opportunity Canvas", value: "opc" },
  { label: "User Persona", value: "persona" },
  { label: "Gantt Chart", value: "gct" },
  { label: "ER Diagram", value: "erd" },
  { label: "Kanban", value: "kanban" },
  { label: "KPT Retrospective", value: "kpt" },
  { label: "Start, Stop, Continue Retrospective", value: "ssc" },
  { label: "4Ls Retrospective", value: "4ls" },
];

const showQuickPick = (
  context: vscode.ExtensionContext,
  callback: () => void
) => {
  const options = diagrams;
  const quickPick = vscode.window.createQuickPick();
  quickPick.items = options.map((item) => ({ label: item.label }));
  // @ts-ignore
  quickPick.onDidChangeSelection((selection) => {
    if (selection.length > 0) {
      const label = selection[0].label;
      const values = options.filter((item) => item.label === label);

      if (values.length > 0) {
        DiagramPanel.createOrShow(context, values[0].value);
        callback();
        quickPick.hide();
      }
    }
  });
  quickPick.onDidHide(() => quickPick.dispose());
  quickPick.show();
};

const setText = (editor: vscode.TextEditor, text: string) => {
  editor.edit((builder) => {
    const document = editor.document;
    const lastLine = document.lineAt(document.lineCount - 1);

    const start = new vscode.Position(0, 0);
    const end = new vscode.Position(
      document.lineCount - 1,
      lastLine.text.length
    );

    builder.replace(new vscode.Range(start, end), text);
  });
};

export function activate(context: vscode.ExtensionContext) {
  const newTextOpen = async (text: string, diagramType: string) => {
    const doc = await vscode.workspace.openTextDocument({
      language: "txt",
      content: text,
    });
    const editor = await vscode.window.showTextDocument(doc, -1, true);
    setText(editor, text);
    DiagramPanel.createOrShow(context, diagramType);
  };

  context.subscriptions.push(
    vscode.commands.registerCommand("extension.showPreview", () => {
      showQuickPick(context, () => {});
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("extension.exportSvg", () => {
      showQuickPick(context, () => {
        if (DiagramPanel.currentPanel) {
          DiagramPanel.currentPanel.exportSvg();
        }
      });
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("extension.exportPng", () => {
      showQuickPick(context, () => {
        if (DiagramPanel.currentPanel) {
          DiagramPanel.currentPanel.exportPng();
        }
      });
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("extension.newDiagram", () => {
      const options = diagrams;
      const quickPick = vscode.window.createQuickPick();
      quickPick.items = options.map((item) => ({ label: item.label }));
      quickPick.onDidChangeSelection((selection) => {
        if (selection.length > 0) {
          const label = selection[0].label;
          const values = options.filter((item) => item.label === label);
          const editor = vscode.window.activeTextEditor;

          if (editor && values.length > 0) {
            switch (values[0].value) {
              case "usm":
                newTextOpen(
                  "# labels: USER ACTIVITIES, USER TASKS, USER STORY\nUSER ACTIVITY\n    USER TASK\n        USER STORY",
                  values[0].value
                );
                break;
              case "bmc":
                newTextOpen(
                  "👥 Key Partners\n📊 Customer Segments\n🎁 Value Proposition\n✅ Key Activities\n🚚 Channels\n💰 Revenue Streams\n🏷️ Cost Structure\n💪 Key Resources\n💙 Customer Relationships",
                  values[0].value
                );
                break;
              case "opc":
                newTextOpen(
                  "Problems\nSolution Ideas\nUsers and Customers\nSolutions Today\nBusiness Challenges\nHow will Users use Solution?\nUser Metrics\nAdoption Strategy\nBusiness Benefits and Metrics\nBudget",
                  values[0].value
                );
                break;
              case "4ls":
                newTextOpen(
                  "Liked\nLearned\nLacked\nLonged for",
                  values[0].value
                );
                break;
              case "ssc":
                newTextOpen("Start\nStop\nContinue", values[0].value);
                break;
              case "kpt":
                newTextOpen("K\nP\nT", values[0].value);
                break;
              case "persona":
                newTextOpen(
                  "Name\n    https://app.textusm.com/images/logo.svg\nWho am i...\nThree reasons to use your product\nThree reasons to buy your product\nMy interests\nMy personality\nMy Skills\nMy dreams\nMy relationship with technology",
                  values[0].value
                );
                break;
              case "mmp":
                newTextOpen("", values[0].value);
                break;
              case "emm":
                newTextOpen(
                  "https://app.textusm.com/images/logo.svg\nSAYS\nTHINKS\nDOES\nFEELS",
                  values[0].value
                );
                break;
              case "cjm":
                newTextOpen(
                  "Header\n    Task\n    Questions\n    Touchpoints\n    Emotions\n    Influences\n    Weaknesses\nDiscover\n    Task\n    Questions\n    Touchpoints\n    Emotions\n    Influences\n    Weaknesses\nResearch\n    Task\n    Questions\n    Touchpoints\n    Emotions\n    Influences\n    Weaknesses\nPurchase\n    Task\n    Questions\n    Touchpoints\n    Emotions\n    Influences\n    Weaknesses\nDelivery\n    Task\n    Questions\n    Touchpoints\n    Emotions\n    Influences\n    Weaknesses\nPost-Sales\n    Task\n    Questions\n    Touchpoints\n    Emotions\n    Influences\n    Weaknesses\n",
                  values[0].value
                );
                break;
              case "smp":
                newTextOpen("", values[0].value);
                break;
              case "gct":
                newTextOpen(
                  "2019-12-26,2020-01-31\n    title1\n        subtitle1\n            2019-12-26, 2019-12-31\n    title2\n        subtitle2\n            2019-12-31, 2020-01-04\n",
                  values[0].value
                );
              case "imm":
                newTextOpen("", values[0].value);
                break;
              case "erd":
                newTextOpen(
                  "relations\n    # one to one\n    Table1 - Table2\n    # one to many\n    Table1 < Table3\ntables\n    Table1\n        id int pk auto_increment\n        name varchar(255) unique\n        rate float null\n        value double not null\n        values enum(value1,value2) not null\n    Table2\n        id int pk auto_increment\n        name double unique\n    Table3\n        id int pk auto_increment\n        name varchar(255) index\n",
                  values[0].value
                );
                break;
              case "kanban":
                newTextOpen("TODO\nDOING\nDONE", values[0].value);
                break;
            }
          }
          quickPick.hide();
        }
      });
      quickPick.onDidHide(() => quickPick.dispose());
      quickPick.show();
    })
  );
}

export function deactivate() {}

class DiagramPanel {
  public static currentPanel: DiagramPanel | undefined;
  public static readonly viewType = "textUSM";

  private readonly _panel: vscode.WebviewPanel;

  public static createOrShow(
    context: vscode.ExtensionContext,
    diagramType: string
  ) {
    const column = vscode.window.activeTextEditor
      ? vscode.window.activeTextEditor.viewColumn
      : vscode.ViewColumn.Two;
    const editor = vscode.window.activeTextEditor;
    const text = editor ? editor.document.getText() : "";
    const title = "TextUSM";
    const scriptSrc = vscode.Uri.file(
      path.join(context.extensionPath, "js", "elm.js")
    ).with({
      scheme: "vscode-resource",
    });

    const iconPath = vscode.Uri.file(
      path.join(context.extensionPath, "images", "icon.png")
    );

    if (DiagramPanel.currentPanel) {
      DiagramPanel.currentPanel._update(
        iconPath,
        scriptSrc,
        title,
        text,
        diagramType
      );
      DiagramPanel.currentPanel._panel.webview.postMessage({
        text,
      });
      DiagramPanel.currentPanel._panel.reveal(
        column ? column + 1 : vscode.ViewColumn.Two
      );
      DiagramPanel.currentPanel._addTextChangedEvent(editor);
      return;
    }

    const panel = vscode.window.createWebviewPanel(
      DiagramPanel.viewType,
      "TextUSM",
      column ? column + 1 : vscode.ViewColumn.Two,
      {
        enableScripts: true,
        localResourceRoots: [
          vscode.Uri.file(path.join(context.extensionPath, "js")),
        ],
      }
    );

    const figurePanel = new DiagramPanel(
      panel,
      iconPath,
      scriptSrc,
      title,
      text,
      diagramType
    );

    DiagramPanel.currentPanel = figurePanel;
    DiagramPanel.currentPanel._addTextChangedEvent(editor);

    figurePanel._panel.webview.onDidReceiveMessage((message) => {
      if (message.command === "setText") {
        if (editor) {
          setText(editor, message.text);
        }
      } else if (message.command === "exportPng") {
        const dir: string | undefined = vscode.workspace
          .getConfiguration()
          .get("textusm.exportDir");
        const editor = vscode.window.activeTextEditor;
        const title = editor
          ? path.basename(editor.document.fileName)
          : "untitled";
        const filePath = `${
          dir
            ? dir.endsWith("/")
              ? dir.toString()
              : `${dir.toString()}/`
            : `${vscode.workspace.rootPath}/`
        }${title}.png`;
        const base64Data = message.text.replace(/^data:image\/png;base64,/, "");

        fs.writeFileSync(filePath, base64Data, "base64");
        vscode.window.showInformationMessage(`Exported: ${filePath}`, {
          modal: false,
        });
      } else if (message.command === "exportSvg") {
        const backgroundColor = vscode.workspace
          .getConfiguration()
          .get("textusm.backgroundColor");
        const editor = vscode.window.activeTextEditor;
        const title = editor
          ? path.basename(editor.document.fileName)
          : "untitled";
        const dir: string | undefined = vscode.workspace
          .getConfiguration()
          .get("textusm.exportDir");
        const filePath = `${
          dir
            ? dir.endsWith("/")
              ? dir.toString()
              : `${dir.toString()}/`
            : `${vscode.workspace.rootPath}/`
        }${title}.svg`;

        fs.writeFileSync(
          filePath,
          `<?xml version="1.0"?>
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${
                      message.width
                    } ${message.height}" width="${message.width}" height="${
            message.height
          }" style="background-color: ${backgroundColor};">
                    ${message.text
                      .split("<div")
                      .join('<div xmlns="http://www.w3.org/1999/xhtml"')
                      .split("<img")
                      .join('<img xmlns="http://www.w3.org/1999/xhtml"')}
                    </svg>`
        );
        vscode.window.showInformationMessage(`Exported: ${filePath}`, {
          modal: false,
        });
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
    const backgroundColor = vscode.workspace
      .getConfiguration()
      .get("textusm.backgroundColor");
    this._panel.webview.postMessage({
      command: "exportPng",
      backgroundColor,
    });
  }

  public exportSvg() {
    this._panel.webview.postMessage({
      command: "exportSvg",
    });
  }

  private _update(
    iconPath: vscode.Uri,
    scriptSrc: vscode.Uri,
    title: string,
    text: string,
    diagramType: string
  ) {
    this._panel.iconPath = iconPath;
    this._panel.title = `${title}`;
    this._panel.webview.html = this.getWebviewContent(
      scriptSrc,
      text,
      diagramType
    );
  }

  private _addTextChangedEvent(editor: vscode.TextEditor | undefined) {
    let updated: null | NodeJS.Timeout = null;
    vscode.workspace.onDidChangeTextDocument((e) => {
      if (editor) {
        if (
          e &&
          e.document &&
          editor &&
          editor.document &&
          e.document.uri === editor.document.uri
        ) {
          if (updated) {
            clearTimeout(updated);
          }
          updated = setTimeout(() => {
            this._panel.webview.postMessage({
              command: "textChanged",
              text: e.document.getText(),
            });
          }, 1000);
        }
      }
    });
  }

  private getWebviewContent(
    scriptSrc: vscode.Uri,
    text: string,
    diagramType: string
  ) {
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

    const labelColor = vscode.workspace
      .getConfiguration()
      .get("textusm.label.color");
    const textColor = vscode.workspace
      .getConfiguration()
      .get("textusm.text.color");
    const lineColor = vscode.workspace
      .getConfiguration()
      .get("textusm.line.color");

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
            }",
            textColor: "${textColor ? textColor : "#111111"}",
            labelColor: "${labelColor ? labelColor : "#8C9FAE"}",
            lineColor: "${lineColor ? lineColor : "#434343"}",
            diagramType: "${diagramType}"
        }});

        app.ports.setText.subscribe(text => {
          vscode.postMessage({
            command: 'setText',
            text: text,
          });
        });

        const createSvg = (svgHTML, backgroundColor, width, height) => {
            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
            const svgWidth = width * 1.3;
            const svgHeight = height * 1.3;
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

                app.ports.onGetCanvasSize.subscribe(([width, height]) => {
                  vscode.postMessage({
                      command: 'exportSvg',
                      text: usmSvg.innerHTML,
                      width: width,
                      height: height
                  });
                });
                app.ports.getCanvasSize.send("${diagramType}");
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
                app.ports.onGetCanvasSize.subscribe(([width, height]) => {
                  img.src = 'data:image/svg+xml;utf8,' + encodeURIComponent(new XMLSerializer().serializeToString(
                    createSvg(usmSvg.innerHTML,
                              message.backgroundColor,
                              width,
                              height))
                  );
                });
                app.ports.getCanvasSize.send("${diagramType}");
            }
        });
        window.dispatchEvent(new Event('resize'));
    </script>
</body>
</html>`;
  }
}
