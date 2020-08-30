import {
  UserStoryMap,
  toString as userStoryMapToString,
} from "./models/UserStoryMap";
import { MindMap, SiteMap, ImpactMap, MapNode } from "./models/MindMap";
import { ERDiagram, toString as erToString } from "./models/ER";
import { Kanban, toString as kanbanToString } from "./models/Kanban";
import {
  BusinessModelCanvas,
  toString as businessModelCanvasToString,
} from "./models/BusinessModelCanvas";
import {
  OpportunityCanvas,
  toString as opportunityCanvasToString,
} from "./models/OpportunityCanvas";
import { FourLs, toString as fourLsToString } from "./models/FourLs";
import {
  StartStopContinue,
  toString as startStopContinueToString,
} from "./models/StartStopContinue";
import { Kpt, toString as kptToString } from "./models/Kpt";
import {
  UserPersona,
  toString as userPersonaToString,
} from "./models/UserPersona";
import {
  EmpathyMap,
  toString as empathyMapToString,
} from "./models/EmpathyMap";
import { GanttChart, toString as ganttToString } from "./models/GanttChart";
import { Table, toString as tableToString } from "./models/Table";
import {
  SequenceDiagram,
  toString as sequenceDiagramToString,
} from "./models/SequenceDiagram";

type Diagram =
  | UserStoryMap
  | BusinessModelCanvas
  | OpportunityCanvas
  | FourLs
  | StartStopContinue
  | Kpt
  | UserPersona
  | MindMap
  | EmpathyMap
  | Table
  | SiteMap
  | GanttChart
  | ImpactMap
  | ERDiagram
  | Kanban
  | SequenceDiagram;

function toString(definition: Diagram): string {
  switch (definition.name) {
    case "UserStoryMap":
      return userStoryMapToString(definition);
    case "BusinessModelCanvas":
      return businessModelCanvasToString(definition);
    case "OpportunityCanvas":
      return opportunityCanvasToString(definition);
    case "4Ls":
      return fourLsToString(definition);
    case "StartStopContinue":
      return startStopContinueToString(definition);
    case "Kpt":
      return kptToString(definition);
    case "UserPersona":
      return userPersonaToString(definition);
    case "MindMap":
      return node2Text(definition);
    case "EmpathyMap":
      return empathyMapToString(definition);
    case "Table":
      return tableToString(definition);
    case "GanttChart":
      return ganttToString(definition);
    case "ER":
      return erToString(definition);
    case "Kanban":
      return kanbanToString(definition);
    case "SequenceDiagram":
      return sequenceDiagramToString(definition);
    default:
      const _exhaustiveCheck: never = definition;
      return _exhaustiveCheck;
  }
}

function toTypeString(definition: Diagram): string {
  return definition.name;
}

function concat<T>(x: T[], y: T[]): T[] {
  return x.concat(y);
}

function flatMap<T, U>(f: (x: T) => U[], xs: T[]): U[] {
  return xs.map(f).reduce(concat, []);
}

function node2Text(map: MindMap | SiteMap | ImpactMap): string {
  const _node2Text = (node: MapNode[], indent: number): string[] => {
    return flatMap((n) => {
      if (n.children.length === 0) {
        return [`${"    ".repeat(indent)}${n.text}`];
      }

      return [`${"    ".repeat(indent)}${n.text}`].concat(
        _node2Text(n.children, indent + 1)
      );
    }, node);
  };

  return [map.node.text].concat(_node2Text(map.node.children, 1)).join("\n");
}

export { Diagram, toString, toTypeString };
