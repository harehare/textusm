import { Elm } from "./js/elm";

interface Config {
  font?: string;
  size?: Size;
  color?: ColorConfig;
  backgroundColor?: string;
  zoomControl?: boolean;
  scale?: number;
  toolbar?: boolean;
  showGrid?: boolean;
}

interface ColorConfig {
  activity?: Color;
  task?: Color;
  story?: Color;
  comment?: Color;
  line?: string;
  label?: string;
  text?: string;
}

interface Size {
  width: number;
  height: number;
}

interface Color {
  color: string;
  backgroundColor: string;
}

const defaultConfig: Config = {
  font: "Nunito Sans",
  size: {
    width: 140,
    height: 65,
  },
  color: {
    activity: {
      color: "#FFFFFF",
      backgroundColor: "#3B82F6",
    },
    task: {
      color: "#FFFFFF",
      backgroundColor: "#6366F1",
    },
    story: {
      color: "#1E293B",
      backgroundColor: "#F1F5F9",
    },
    line: "#CBD5E1",
    label: "#64748B",
    text: "#1E293B",
  },
  backgroundColor: "#F8FAFC",
  zoomControl: false,
  scale: 1.0,
  toolbar: false,
  showGrid: false,
};

function render(
  idOrElm: string | HTMLElement,
  definition: string,
  options?: {
    diagramType?:
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
      | "SequenceDiagram"
      | "Freeform"
      | "KeyboardLayout";
    size?: Size;
    showZoomControl?: boolean;
    scale?:
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
  },
  config?: Config
) {
  const elm =
    typeof idOrElm === "string" ? document.getElementById(idOrElm) : idOrElm;

  if (!elm) {
    throw new Error(
      typeof idOrElm === "string"
        ? `Element "${idOrElm}" is not found.`
        : `Element is not found.`
    );
  }

  options = options ?? {};
  config = config ?? {};
  config.color = { ...defaultConfig.color, ...config.color };
  config.size = {
    width: config.size?.width ?? defaultConfig.size!.width,
    height: config.size?.height ?? defaultConfig.size!.height,
  };

  Elm.Extension.Lib.init({
    node: elm,
    flags: {
      text: definition,
      diagramType: options.diagramType ?? "UserStoryMap",
      width: options.size?.width ?? 1024,
      height: options.size?.height ?? 1024,
      settings: { ...defaultConfig, ...config },
      showZoomControl: options.showZoomControl ?? false,
      scale: options.scale ?? 1.0,
    },
  });
}

export { render };
