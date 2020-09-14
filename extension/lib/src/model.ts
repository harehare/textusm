import { UserStoryMap } from "./models/UserStoryMap";
import { MindMap, SiteMap, ImpactMap, MapNode } from "./models/MindMap";
import { ERDiagram } from "./models/ER";
import { Kanban } from "./models/Kanban";
import { BusinessModelCanvas } from "./models/BusinessModelCanvas";
import { OpportunityCanvas } from "./models/OpportunityCanvas";
import { FourLs } from "./models/FourLs";
import { StartStopContinue } from "./models/StartStopContinue";
import { Kpt } from "./models/Kpt";
import { UserPersona } from "./models/UserPersona";
import { EmpathyMap } from "./models/EmpathyMap";
import { GanttChart } from "./models/GanttChart";
import { Table } from "./models/Table";
import { SequenceDiagram } from "./models/SequenceDiagram";

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
      return UserStoryMap.toString(definition);
    case "BusinessModelCanvas":
      return BusinessModelCanvas.toString(definition);
    case "OpportunityCanvas":
      return OpportunityCanvas.toString(definition);
    case "4Ls":
      return FourLs.toString(definition);
    case "StartStopContinue":
      return StartStopContinue.toString(definition);
    case "Kpt":
      return Kpt.toString(definition);
    case "UserPersona":
      return UserPersona.toString(definition);
    case "MindMap":
      return node2Text(definition);
    case "EmpathyMap":
      return EmpathyMap.toString(definition);
    case "Table":
      return Table.toString(definition);
    case "GanttChart":
      return GanttChart.toString(definition);
    case "ER":
      return ERDiagram.toString(definition);
    case "Kanban":
      return Kanban.toString(definition);
    case "SequenceDiagram":
      return SequenceDiagram.toString(definition);
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
