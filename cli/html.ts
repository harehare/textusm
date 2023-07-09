import { render } from "mustache";

interface Size {
  width: number;
  height: number;
}

interface ColorConfig {
  activity: Color;
  task: Color;
  story: Color;
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
  | "SequenceDiagram"
  | "UseCaseDiagram"
  | "KeyboardLayout"
  | "Freeform";

interface Settings {
  diagramType: DiagramType;
  font: string;
  size: Size;
  color: ColorConfig;
  backgroundColor: string;
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

const html = (
  text: string,
  javaScript: string,
  width: number,
  height: number,
  settings: Settings
) => {
  return render(
    `<html>
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
      "target", "{{ text }}",
      {
        diagramType: "{{ diagramType }}",
        size: { width: {{ width }}, height: {{ height }} },
        showZoomControl: false,
        scale: {{ scale }},
      },
      {{{ settings }}}
    );
  </script>
</html>
`,
    {
      javaScript,
      text: text.split("\n").join("\\n"),
      diagramType: settings.diagramType,
      width,
      height,
      scale: settings.scale,
      settings: JSON.stringify(settings),
    }
  );
};

export { html, DiagramType, Settings };
