import { UserStoryMap } from "./models/UserStoryMap";
import { MindMap, SiteMap, ImpactMap, MapNode } from "./models/MindMap";
import { ERDiagram } from "./models/ER";
import { Kanban } from "./models/Kanban";

export type BusinessModelCanvas = {
  name: "BusinessModelCanvas";
  keyPartners: CanvasItem;
  customerSegments: CanvasItem;
  valueProposition: CanvasItem;
  keyActivities: CanvasItem;
  channels: CanvasItem;
  revenueStreams: CanvasItem;
  costStructure: CanvasItem;
  keyResources: CanvasItem;
  customerRelationships: CanvasItem;
};

export type OpportunityCanvas = {
  name: "OpportunityCanvas";
  problems: CanvasItem;
  solutionIdeas: CanvasItem;
  usersAndCustomers: CanvasItem;
  solutionsToday: CanvasItem;
  businessChallenges: CanvasItem;
  howWillUsersUseSolution: CanvasItem;
  userMetrics: CanvasItem;
  adoptionStrategy: CanvasItem;
  businessBenefitsAndMetrics: CanvasItem;
  budget: CanvasItem;
};

export type FourLs = {
  name: "4Ls";
  liked: CanvasItem;
  learned: CanvasItem;
  lacked: CanvasItem;
  longedFor: CanvasItem;
};

export type StartStopContinue = {
  name: "StartStopContinue";
  start: CanvasItem;
  stop: CanvasItem;
  continue: CanvasItem;
};

export type Kpt = {
  name: "Kpt";
  keep: CanvasItem;
  problem: CanvasItem;
  try: CanvasItem;
};

export type UserPersona = {
  name: "UserPersona";
  url: UrlItem;
  whoAmI: CanvasItem;
  item1: CanvasItem;
  item2: CanvasItem;
  item3: CanvasItem;
  item4: CanvasItem;
  item5: CanvasItem;
  item6: CanvasItem;
  item7: CanvasItem;
};

export type EmpathyMap = {
  name: "EmpathyMap";
  imageUrl: string;
  says: CanvasItem;
  thinks: CanvasItem;
  does: CanvasItem;
  feels: CanvasItem;
};

type CanvasItem = {
  title: string;
  text: string[];
};

type UrlItem = {
  title: string;
  url: string;
};

export type GanttChart = {
  name: "GanttChart";
  from: string;
  to: string;
  chartitems: GanttChartItem[];
};

type GanttChartItem = {
  title: string;
  schedules: Schedule[];
};

type Schedule = {
  from: string;
  to: string;
  title: string;
};

export type Table = {
  name: "Table";
  header: string[];
  items: string[][];
};

export function toString(
  definition:
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
): string {
  return definition.name === "UserStoryMap"
    ? userStoryMap2Text(definition)
    : definition.name === "BusinessModelCanvas"
    ? businessModelCanvas2Text(definition)
    : definition.name === "OpportunityCanvas"
    ? opportunityCanvas2Text(definition)
    : definition.name === "4Ls"
    ? fourLsCanvas2Text(definition)
    : definition.name === "StartStopContinue"
    ? startStopContinueCanvas2Text(definition)
    : definition.name === "Kpt"
    ? kptCanvas2Text(definition)
    : definition.name === "UserPersona"
    ? userPersonaCanvas2Text(definition)
    : definition.name === "MindMap"
    ? node2Text(definition)
    : definition.name === "EmpathyMap"
    ? empathyMapCanvas2Text(definition)
    : definition.name === "Table"
    ? table2Text(definition)
    : definition.name === "GanttChart"
    ? ganttchart2Text(definition)
    : definition.name === "ER"
    ? erDiagram2Text(definition)
    : definition.name === "Kanban"
    ? kanban2Text(definition)
    : "";
}

export function toTypeString(
  definition:
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
): string {
  return definition.name;
}

function concat<T>(x: T[], y: T[]): T[] {
  return x.concat(y);
}

function flatMap<T, U>(f: (x: T) => U[], xs: T[]): U[] {
  return xs.map(f).reduce(concat, []);
}

function canvas2Text(item: CanvasItem) {
  return `${item.title}
${(item.text ? item.text : [])
  .map((line) => {
    return `    ${line}`;
  })
  .join("\n")}
`;
}

function businessModelCanvas2Text(
  businessModelCanvas: BusinessModelCanvas
): string {
  const items = [
    "keyPartners",
    "customerSegments",
    "valueProposition",
    "keyActivities",
    "channels",
    "revenueStreams",
    "costStructure",
    "keyResources",
    "customerRelationships",
  ];

  return items
    .map((item) => {
      return canvas2Text(businessModelCanvas[item]);
    })
    .join("");
}

function opportunityCanvas2Text(opportunityCanvas: OpportunityCanvas): string {
  const items = [
    "problems",
    "solutionIdeas",
    "usersAndCustomers",
    "solutionsToday",
    "businessChallenges",
    "howWillUsersUseSolution",
    "userMetrics",
    "adoptionStrategy",
    "businessBenefitsAndMetrics",
    "budget",
  ];

  return items
    .map((item) => {
      return canvas2Text(opportunityCanvas[item]);
    })
    .join("");
}

function fourLsCanvas2Text(fourls: FourLs): string {
  const items = ["liked", "learned", "lacked", "longedFor"];

  return items
    .map((item) => {
      return canvas2Text(fourls[item]);
    })
    .join("");
}

function startStopContinueCanvas2Text(
  startStopContinue: StartStopContinue
): string {
  const items = ["start", "stop", "continue"];

  return items
    .map((item) => {
      return canvas2Text(startStopContinue[item]);
    })
    .join("");
}

function kptCanvas2Text(kpt: Kpt): string {
  const items = ["keep", "problem", "try"];

  return items
    .map((item) => {
      return canvas2Text(kpt[item]);
    })
    .join("");
}

function userPersonaCanvas2Text(userPersona: UserPersona): string {
  const items = [
    "whoAmI",
    "item1",
    "item2",
    "item3",
    "item4",
    "item5",
    "item6",
    "item7",
  ];

  return `${userPersona.url.title}\n    ${userPersona.url.url}\n${items
    .map((item) => {
      return canvas2Text(userPersona[item]);
    })
    .join("")}`;
}

function empathyMapCanvas2Text(empathyMap: EmpathyMap): string {
  const items = ["says", "thinks", "does", "feels"];

  return `${empathyMap.imageUrl}\n${items
    .map((item) => {
      return canvas2Text(empathyMap[item]);
    })
    .join("")}`;
}

function table2Text(table: Table): string {
  const rows = table.items
    .map((item) =>
      item.length > 0
        ? `${item[0]}\n${item
            .slice(1)
            .map((v) => `    ${v}`)
            .join("\n")}`
        : ""
    )
    .join("\n");

  return table.header.length > 0
    ? `${table.header[0]}\n${table.header
        .map((v) => `    ${v}`)
        .splice(1)
        .join("\n")}\n${rows}`
    : "";
}

function ganttchart2Text(ganttChart: GanttChart): string {
  return `${ganttChart.from},${ganttChart.to}\n${ganttChart.chartitems
    .map((item) => {
      return `    ${item.title}\n${item.schedules
        .map((schedule) => {
          return `        ${schedule.title}\n            ${schedule.from},${schedule.to}`;
        })
        .join("\n")}`;
    })
    .join("\n")}`;
}

function userStoryMap2Text(userStoryMap: UserStoryMap): string {
  const labels =
    userStoryMap.labels && userStoryMap.labels.length > 0
      ? `#labels: ${userStoryMap.labels.join(",")}\n`
      : "";
  return `${labels}${flatMap((activity) => {
    return [activity.name].concat(
      flatMap((task) => {
        return ["    " + task.name].concat(
          flatMap((story) => {
            return ["    ".repeat(story.release + 1) + story.name];
          }, task.stories)
        );
      }, activity.tasks)
    );
  }, userStoryMap.activities).join("\n")}`;
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

function erDiagram2Text(er: ERDiagram): string {
  const relations = ["relations"].concat(
    er.relations.map((e) => {
      return `    ${e.table1} ${e.relation} ${e.table2}`;
    })
  );

  const tables = ["tables"].concat(
    er.tables.map((table) => {
      const columns = table.columns.map((column) => {
        const columnText = `${column.name}`;
        const columnLength =
          column.type.columnLength > 0 ? `(${column.type.columnLength})` : "";
        const columnAttribute = `${column.attribute.name}${
          column.attribute.value ? ` ${column.attribute.value}` : ""
        }`;
        return `        ${columnText} ${column.type.name}${columnLength} ${columnAttribute}`;
      });
      return `    ${table.name}\n${columns.join("\n")}`;
    })
  );

  return `${relations.join("\n")}\n${tables.join("\n")}`;
}

function kanban2Text(kanban: Kanban): string {
  return kanban.lists
    .map((list) => {
      return (
        `${list.name}\n` +
        list.cards.map((card) => `    ${card.text}`).join("\n")
      );
    })
    .join("\n");
}
