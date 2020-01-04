import { Elm } from "./js/elm";
import {
  UserStoryMap,
  BusinessModelCanvas,
  OpportunityCanvas,
  FourLs,
  StartStopContinue,
  Kpt,
  toString,
  toTypeString,
  MindMap,
  EmpathyMap,
  CustomerJourneyMap,
  SiteMap,
  GanttChart
} from "./model";

interface Config {
  font?: string;
  size?: Size;
  color?: ColorConfig;
  backgroundColor?: string;
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
  font: "Roboto",
  size: {
    width: 140,
    height: 65
  },
  color: {
    activity: {
      color: "#FFFFFF",
      backgroundColor: "#266B9A"
    },
    task: {
      color: "#FFFFFF",
      backgroundColor: "#3E9BCD"
    },
    story: {
      color: "#000000",
      backgroundColor: "#FFFFFF"
    },
    comment: {
      color: "#000000",
      backgroundColor: "#F1B090"
    },
    line: "#434343",
    label: "#8C9FAE",
    text: "#111111"
  },
  backgroundColor: "#F5F5F6"
};

function render(
  idOrElm: string | HTMLElement,
  definition:
    | string
    | UserStoryMap
    | BusinessModelCanvas
    | OpportunityCanvas
    | FourLs
    | StartStopContinue
    | Kpt
    | MindMap
    | EmpathyMap
    | CustomerJourneyMap
    | SiteMap
    | GanttChart,
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
      | "CustomerJourneyMap"
      | "SiteMap"
      | "EmpathyMap"
      | "GanttChart";
    size?: Size;
    showZoomControl?: boolean;
    showMiniMap?: boolean;
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

  options = options ? options : {};
  config = config ? config : {};
  config.color = Object.assign(defaultConfig.color, config.color);
  config.size = Object.assign(defaultConfig.size, config.size);

  const text =
    typeof definition === "string" ? definition : toString(definition);

  Elm.Extension.Lib.init({
    node: elm,
    flags: {
      text,
      diagramType: options.diagramType
        ? options.diagramType
        : typeof definition === "string"
        ? "UserStoryMap"
        : toTypeString(definition),
      width: options.size ? options.size.width : 1024,
      height: options.size ? options.size.height : 1024,
      settings: Object.assign(defaultConfig, config),
      showZoomControl:
        options.showZoomControl !== undefined ? options.showZoomControl : true,
      showMiniMap:
        options.showMiniMap !== undefined ? options.showMiniMap : false,
      scale:
        options.scale && 2.0 - options.scale > 0 ? 2.0 - options.scale : 1.0
    }
  });
}

export { render };
