import { escape } from "html-escaper";

interface Size {
  width: number;
  height: number;
}

interface ColorConfig {
  activity: Color;
  task: Color;
  story: Color;
  comment: Color;
  line: string;
  label: string;
  text: string;
}

interface Color {
  color: string;
  backgroundColor: string;
}

type DiagramType =
  | "UserStoryMap"
  | "BusinessModelCanvas"
  | "OpportunityCanvas"
  | "4Ls"
  | "StartStopContinue"
  | "Kpt"
  | "UserPersona"
  | "MindMap"
  | "Table"
  | "SiteMap"
  | "EmpathyMap"
  | "GanttChart"
  | "ImpactMap"
  | "ERDiagram"
  | "Kanban"
  | "SequenceDiagram";

interface Settings {
  diagramType: DiagramType;
  font: string;
  size: Size;
  color: ColorConfig;
  backgroundColor: string;
  showZoomControl: boolean;
  scale:
    | 0.1
    | 0.2
    | 0.3
    | 0.4
    | 0.5
    | 0.6
    | 0.7
    | 0.8
    | 0.9
    | 1.0
    | 1.1
    | 1.2
    | 1.3
    | 1.4
    | 1.5
    | 1.6
    | 1.7
    | 1.8
    | 1.9
    | 2.0;
}

const html = (text: string, javaScript: string, settings: Settings) => `<html>
  <head>
    <script>${javaScript}</script>
  </head>
  <body>
    <div id="main">
      <div id="target"></div>
    </div>
  </body>
  <script type="text/javascript">
      textusm.render(
        "target",
\`${escape(text)}\`,
        {
          diagramType: "${escape(settings.diagramType)}",
          size: { width: ${settings.size.width}, height: ${
  settings.size.height
},
          showZoomControl: ${settings.showZoomControl},
          scale: ${settings.scale},
        },
        config: ${JSON.stringify(settings)}
      }
      );
    </script>
</html>
`;

export { html, DiagramType, Settings };
