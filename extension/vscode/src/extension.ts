import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import { v4 as uuidv4 } from "uuid";

type DiagramType =
  | "usm"
  | "opc"
  | "bmc"
  | "4ls"
  | "ssc"
  | "kpt"
  | "persona"
  | "mmp"
  | "emm"
  | "smp"
  | "gct"
  | "imm"
  | "erd"
  | "kanban"
  | "table"
  | "sed"
  | "free"
  | "kbd"
  | "ucd";

const diagrams: ReadonlyArray<{ label: string; value: DiagramType }> = [
  { label: "User Story Map", value: "usm" },
  { label: "Table", value: "table" },
  { label: "Empathy Map", value: "emm" },
  { label: "Impact Map", value: "imm" },
  { label: "Mind Map", value: "mmp" },
  { label: "Site Map", value: "smp" },
  { label: "Business Model Canvas", value: "bmc" },
  { label: "Opportunity Canvas", value: "opc" },
  { label: "User Persona", value: "persona" },
  { label: "Gantt Chart", value: "gct" },
  { label: "ER Diagram", value: "erd" },
  { label: "Sequence Diagram", value: "sed" },
  { label: "Use Case Diagram", value: "ucd" },
  { label: "Kanban", value: "kanban" },
  { label: "KPT Retrospective", value: "kpt" },
  { label: "Start, Stop, Continue Retrospective", value: "ssc" },
  { label: "4Ls Retrospective", value: "4ls" },
  { label: "Freeform", value: "free" },
  { label: "Keyboard Layout", value: "kbd" },
];

const showQuickPick = (
  context: vscode.ExtensionContext,
  callback: () => void
) => {
  const options = diagrams;
  const quickPick = vscode.window.createQuickPick();
  quickPick.items = options.map((item) => ({ label: item.label }));
  quickPick.onDidChangeSelection((selection) => {
    if (selection.length > 0) {
      const label = selection[0].label;
      const values = options.filter((item) => item.label === label);
      const diagramType = values[0].value as DiagramType;

      if (values.length > 0) {
        DiagramPanel.createOrShow(context, diagramType);
        callback();
        quickPick.hide();
      }
    }
  });
  quickPick.onDidHide(() => quickPick.dispose());
  quickPick.show();
};

const setText = (editor: vscode.TextEditor, text: string) => {
  return editor.edit((builder) => {
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

const setPreviewActiveContext = (value: boolean) => {
  vscode.commands.executeCommand("setContext", "textUsmPreviewFocus", value);
};

const ENABLED_LANG_DIAGRAM_TYPE: { [v in DiagramType]: DiagramType } = {
  usm: "usm",
  mmp: "usm",
  imm: "usm",
  smp: "usm",
  bmc: "usm",
  sed: "usm",
  free: "usm",
  ucd: "usm",
  erd: "usm",
  gct: "usm",
  opc: "usm",
  "4ls": "usm",
  ssc: "usm",
  kpt: "usm",
  persona: "usm",
  emm: "usm",
  kanban: "usm",
  table: "usm",
  kbd: "usm",
};

export function activate(context: vscode.ExtensionContext) {
  const newTextOpen = async (text: string, diagramType: DiagramType) => {
    const doc = await vscode.workspace.openTextDocument({
      language: ENABLED_LANG_DIAGRAM_TYPE[diagramType],
      content: text,
    });
    const editor = await vscode.window.showTextDocument(doc, -1);
    await setText(editor, text);
    setTimeout(() => DiagramPanel.createOrShow(context, diagramType), 300);
  };

  context.subscriptions.push(
    vscode.commands.registerCommand("textusm.showPreview", () => {
      showQuickPick(context, () => {});
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("textusm.exportSvg", () => {
      DiagramPanel.activePanel?.exportSvg();
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("textusm.exportPng", () => {
      DiagramPanel.activePanel?.exportPng();
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("textusm.zoomIn", () => {
      DiagramPanel.activePanel?.zoomIn();
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("textusm.zoomOut", () => {
      DiagramPanel.activePanel?.zoomOut();
    })
  );
  context.subscriptions.push(
    vscode.commands.registerCommand("textusm.newDiagram", () => {
      const options = diagrams;
      const quickPick = vscode.window.createQuickPick();
      quickPick.items = options.map((item) => ({ label: item.label }));
      quickPick.onDidChangeSelection((selection) => {
        if (selection.length > 0) {
          const label = selection[0].label;
          const values = options.filter((item) => item.label === label);
          const editor = vscode.window.activeTextEditor;

          if (editor && values.length > 0) {
            const diagramType = values[0].value as DiagramType;
            switch (diagramType) {
              case "usm":
                newTextOpen(
                  "# user_activities: USER ACTIVITIES\n# user_tasks: USER TASKS\n# user_stories: USER STORIES\n# release1: RELEASE 1\n# release2: RELEASE 2\n# release3: RELEASE 3\nUSER ACTIVITY\n    USER TASK\n        USER STORY",
                  diagramType
                );
                break;
              case "bmc":
                newTextOpen(
                  "👥 Key Partners\n📊 Customer Segments\n🎁 Value Proposition\n✅ Key Activities\n🚚 Channels\n💰 Revenue Streams\n🏷️ Cost Structure\n💪 Key Resources\n💙 Customer Relationships",
                  diagramType
                );
                break;
              case "opc":
                newTextOpen(
                  "Problems\nSolution Ideas\nUsers and Customers\nSolutions Today\nBusiness Challenges\nHow will Users use Solution?\nUser Metrics\nAdoption Strategy\nBusiness Benefits and Metrics\nBudget",
                  diagramType
                );
                break;
              case "4ls":
                newTextOpen("Liked\nLearned\nLacked\nLonged for", diagramType);
                break;
              case "ssc":
                newTextOpen("Start\nStop\nContinue", diagramType);
                break;
              case "kpt":
                newTextOpen("K\nP\nT", diagramType);
                break;
              case "persona":
                newTextOpen(
                  "Name\n    https://app.textusm.com/images/logo.svg\nWho am i...\nThree reasons to use your product\nThree reasons to buy your product\nMy interests\nMy personality\nMy Skills\nMy dreams\nMy relationship with technology",
                  diagramType
                );
                break;
              case "emm":
                newTextOpen(
                  "https://app.textusm.com/images/logo.svg\nSAYS\nTHINKS\nDOES\nFEELS",
                  diagramType
                );
                break;
              case "table":
                newTextOpen(
                  "Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6\n    Column7\nRow1\n    Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6\nRow2\n    Column1\n    Column2\n    Column3\n    Column4\n    Column5\n    Column6",
                  diagramType
                );
                break;
              case "gct":
                newTextOpen(
                  "2019-12-26 2020-01-31\n    title1\n        subtitle1\n            2019-12-26 2019-12-31\n    title2\n        subtitle2\n            2019-12-31 2020-01-04\n",
                  diagramType
                );
              case "imm":
                newTextOpen("", diagramType);
                break;
              case "erd":
                newTextOpen(
                  "relations\n    # one to one\n    Table1 - Table2\n    # one to many\n    Table1 < Table3\ntables\n    Table1\n        id int pk auto_increment\n        name varchar(255) unique\n        rate float null\n        value double not null\n        values enum(value1,value2) not null\n    Table2\n        id int pk auto_increment\n        name double unique\n    Table3\n        id int pk auto_increment\n        name varchar(255) index\n",
                  diagramType
                );
                break;
              case "kanban":
                newTextOpen("TODO\nDOING\nDONE", diagramType);
                break;
              case "sed":
                newTextOpen(
                  "participant\n    object1\n    object2\n    object3\nobject1 -> object2\n    Sync Message\nobject1 ->> object2\n    Async Message\nobject2 --> object1\n    Reply Message\no-> object1\n    Found Message\nobject1 ->o\n    Stop Message\nloop\n    loop message\n        object1 -> object2\n            Sync Message\n        object1 ->> object2\n            Async Message\nPar\n    par message1\n        object2 -> object3\n            Sync Message\n    par message2\n        object1 -> object2\n            Sync Message\n",
                  diagramType
                );
                break;
              case "ucd":
                newTextOpen(
                  "[Customer]\n    Sign In\n    Buy Products\n(Buy Products)\n    >Browse Products\n    >Checkout\n(Checkout)\n    <Add New Credit Card\n[Staff]\n    Processs Order\n",
                  diagramType
                );
                break;

              case "kbd":
                newTextOpen(
                  "r4\n    Esc\n    1u\n    F1\n    F2\n    F3\n    F4\n    0.5u\n    F5\n    F6\n    F7\n    F8\n    0.5u\n    F9\n    F10\n    F11\n    F12\n    0.5u\n    Home\n    End\n    PgUp\n    PgDn\n0.25u\nr4\n    ~,{backquote}\n    !,1\n    @,2\n    {sharp},3\n    $,4\n    %,5\n    ^,6\n    &,7\n    *,8\n    (,9\n    ),0\n    _,-\n    =,+\n    Backspace,,2u\n    0.5u\n    Num,Lock\n    /\n    *\n    -\nr4\n    Tab,,1.5u\n    Q\n    W\n    E\n    R\n    T\n    Y\n    U\n    I\n    O\n    P\n    {,[\n    },]\n    |,\\,1.5u\n    0.5u\n    7,Home\n    8,↑\n    9,PgUp\n    +,,,2u\nr3\n    Caps Lock,,1.75u\n    A\n    S\n    D\n    F\n    G\n    H\n    J\n    K\n    L\n    :,;\n    \",'\n    Enter,,2.25u\n    0.5u\n    4, ←\n    5\n    6,→\nr2\n    Shift,,2.25u\n    Z\n    X\n    C\n    V\n    B\n    N\n    M\n    <,{comma}\n    >,.\n    ?,/\n    Shift,,1.75u\n    0.25u\n    ↑,,,,0.25u\n    0.25u\n    1,End\n    2,↓\n    3,PgDn\n    Enter,,,2u\nr1\n    Ctrl,,1.5u\n    Alt,,1.5u\n    ,,7u\n    Alt,,1.5u\n    Ctl,,1.5u\n    0.25u\n    ←,,,,0.25u\n    ↓,,,,0.25u\n    →,,,,0.25u\n    0.25u\n    0,Ins\n    .,Del",
                  diagramType
                );
                break;

              default:
                newTextOpen("", diagramType);
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
  public static activePanel: DiagramPanel | null;
  public static readonly viewType = "textUSM";

  private readonly _panel: vscode.WebviewPanel;

  public static createOrShow(
    context: vscode.ExtensionContext,
    diagramType: DiagramType
  ) {
    const column = vscode.window.activeTextEditor
      ? vscode.window.activeTextEditor.viewColumn
      : vscode.ViewColumn.Two;
    const editor = vscode.window.activeTextEditor;
    const text = editor ? editor.document.getText() : "";
    const title = editor ? path.basename(editor.document.fileName) : "untitled";
    const iconPath = vscode.Uri.file(
      path.join(context.extensionPath, "images", "icon.png")
    );

    if (editor) {
      editor.options.tabSize = 4;
      editor.options.insertSpaces = true;
      editor;
    }

    // @ts-expect-error
    const onReceiveMessage = async (message) => {
      if (message.command === "setText") {
        if (editor) {
          await setText(editor, message.text);
        }
      } else if (message.command === "exportPng") {
        const dir: string =
          vscode.workspace.getConfiguration().get("textusm.exportDir") ??
          (vscode.workspace.workspaceFolders &&
          vscode.workspace.workspaceFolders.length > 0
            ? vscode.workspace.workspaceFolders[0].uri.path
            : ".");
        const title = DiagramPanel.activePanel?._panel.title;
        const filePath = path.join(
          dir ??
            `${
              vscode.workspace.workspaceFolders
                ? vscode.workspace.workspaceFolders[0]
                : ""
            }/`,
          `${title}.png`
        );
        const base64Data = message.text.replace(/^data:image\/png;base64,/, "");

        try {
          fs.writeFileSync(filePath, base64Data, "base64");
          vscode.window.showInformationMessage(`Exported: ${filePath}`, {
            modal: false,
          });
        } catch {
          vscode.window.showErrorMessage(`Export failed: ${filePath}`, {
            modal: false,
          });
        }
      } else if (message.command === "exportSvg") {
        const backgroundColor = vscode.workspace
          .getConfiguration()
          .get("textusm.backgroundColor");
        const title = DiagramPanel.activePanel?._panel.title;
        const dir: string =
          vscode.workspace.getConfiguration().get("textusm.exportDir") ??
          (vscode.workspace.workspaceFolders &&
          vscode.workspace.workspaceFolders.length > 0
            ? vscode.workspace.workspaceFolders[0].uri.path
            : ".");
        const filePath = path.join(
          dir ??
            `${
              vscode.workspace.workspaceFolders
                ? vscode.workspace.workspaceFolders[0]
                : ""
            }/`,
          `${title}.svg`
        );

        const svgo = await import("svgo");
        const optimizedSvg = svgo.optimize(
          `<?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${message.width} ${
            message.height
          }" width="${message.width}" height="${
            message.height
          }" style="background-color: ${backgroundColor};">
        ${message.text
          .split("<div")
          .join('<div xmlns="http://www.w3.org/1999/xhtml"')
          .split("<img")
          .join('<img xmlns="1http://www.w3.org/1999/xhtml"')}
        </svg>`,
          {
            plugins: [
              {
                name: "preset-default",
                params: {
                  overrides: {
                    convertShapeToPath: {
                      convertArcs: true,
                    },
                    convertPathData: false,
                  },
                },
              },
            ],
          }
        );

        try {
          fs.writeFileSync(filePath, optimizedSvg.data);
          vscode.window.showInformationMessage(`Exported: ${filePath}`, {
            modal: false,
          });
        } catch {
          vscode.window.showErrorMessage(`Export failed: ${filePath}`, {
            modal: false,
          });
        }
      }
    };

    if (DiagramPanel.activePanel) {
      const scriptSrc = DiagramPanel.activePanel._panel.webview.asWebviewUri(
        vscode.Uri.file(path.join(context.extensionPath, "js", "elm.js"))
      );
      DiagramPanel.activePanel._update(
        iconPath,
        scriptSrc,
        title,
        text,
        diagramType
      );
      DiagramPanel.activePanel._panel.webview.postMessage({
        text,
      });
      DiagramPanel.activePanel._panel.reveal(
        column ? column + 1 : vscode.ViewColumn.Two
      );
      DiagramPanel.addTextChangedEvent(editor);
      DiagramPanel.activePanel._panel.webview.onDidReceiveMessage(
        onReceiveMessage
      );
      setPreviewActiveContext(true);
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

    const scriptSrc = panel.webview.asWebviewUri(
      vscode.Uri.file(path.join(context.extensionPath, "js", "elm.js"))
    );
    const figurePanel = new DiagramPanel(
      panel,
      iconPath,
      scriptSrc,
      title,
      text,
      diagramType
    );

    DiagramPanel.activePanel = figurePanel;
    DiagramPanel.addTextChangedEvent(editor);

    figurePanel._panel.webview.onDidReceiveMessage(onReceiveMessage);
    setPreviewActiveContext(true);
  }

  private static addTextChangedEvent(editor: vscode.TextEditor | undefined) {
    let updated: null | NodeJS.Timeout = null;
    vscode.workspace.onDidChangeTextDocument((e) => {
      if (e?.document?.uri === editor?.document?.uri) {
        if (updated) {
          clearTimeout(updated);
        }
        updated = setTimeout(() => {
          DiagramPanel.activePanel?._panel.webview.postMessage({
            command: "textChanged",
            text: e.document.getText(),
          });
        }, 300);
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
    this._panel.onDidDispose(() => {
      this._panel.dispose();
      setPreviewActiveContext(false);
      DiagramPanel.activePanel = null;
    });
    this._panel.onDidChangeViewState(({ webviewPanel }) => {
      setPreviewActiveContext(webviewPanel.active);
    });
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

  public zoomIn() {
    this._panel.webview.postMessage({
      command: "zoomIn",
    });
  }

  public zoomOut() {
    this._panel.webview.postMessage({
      command: "zoomOut",
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

    const cardWidth = vscode.workspace
      .getConfiguration()
      .get("textusm.card.width");
    const cardHeight = vscode.workspace
      .getConfiguration()
      .get("textusm.card.height");
    const toolbar = vscode.workspace.getConfiguration().get("textusm.toolbar");
    const showGrid = vscode.workspace
      .getConfiguration()
      .get("textusm.showGrid");

    const nonce = uuidv4();

    return `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TextUSM</title>
    				<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data: ${
              this._panel.webview.cspSource
            }; style-src 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; script-src 'nonce-${nonce}';">
    <script nonce="${nonce}" src="${scriptSrc}"/>
    <script nonce="${nonce}">
        document.getElementById("svg").innerHTML = 'Load SVG...';
    </script>
</head>
<body>
    <div id="svg"></div>
    <script nonce="${nonce}">
        const vscode = acquireVsCodeApi();
        const app = Elm.Extension.VSCode.init({
            node: document.getElementById("svg"),
            flags: {
              text: \`${text}\`,
              fontName: "${fontName}",
              backgroundColor: "${
                backgroundColor && backgroundColor !== "transparent"
                  ? backgroundColor
                  : "#F4F4F5"
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
              diagramType: "${diagramType}",
              cardWidth: ${cardWidth},
              cardHeight: ${cardHeight},
              toolbar: ${toolbar},
              showGrid: ${showGrid},
          }
        });

        app.ports.setText.subscribe(text => {
          vscode.postMessage({
            command: 'setText',
            text,
          });
        });

        const createSvg = (svgHTML, backgroundColor, width, height) => {
            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
            svg.setAttribute('viewBox', '0 0 ' + width.toString() + ' ' + height.toString());
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
            } else if (message.command === 'zoomIn') {
                app.ports.zoom.send(true);
            } else if (message.command === 'zoomOut') {
                app.ports.zoom.send(false);
            } else if (message.command === 'exportSvg') {
                const usmSvg = document.querySelector('#usm');
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
                const usmSvg = document.querySelector('#usm');
                const canvas = document.createElement('canvas');
                canvas.style.display = 'none';

                app.ports.onGetCanvasSize.subscribe(([width, height]) => {
                  canvas.setAttribute('width', width);
                  canvas.setAttribute('height', height);
                  const context = canvas.getContext('2d');
                  const img = new Image();
                  img.addEventListener('load', () => {
                    context.drawImage(img, 0, 0, width, height);
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
