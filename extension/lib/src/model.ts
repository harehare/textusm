export interface UserStoryMap {
  labels?: string[];
  activities: Activity[];
}

interface Activity {
  name: string;
  tasks: Task[];
}

interface Task {
  name: string;
  stories: Story[];
}

interface Story {
  name: string;
  release: number;
}

export interface MindMap {
  node: Node;
}

interface Node {
  text: string;
  children: Node[];
}

export type SiteMap = MindMap;

export type ImpactMap = MindMap;

interface Node {
  text: string;
  children: Node[];
}

export interface BusinessModelCanvas {
  keyPartners: CanvasItem;
  customerSegments: CanvasItem;
  valueProposition: CanvasItem;
  keyActivities: CanvasItem;
  channels: CanvasItem;
  revenueStreams: CanvasItem;
  costStructure: CanvasItem;
  keyResources: CanvasItem;
  customerRelationships: CanvasItem;
}

export interface OpportunityCanvas {
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
}

export interface FourLs {
  liked: CanvasItem;
  learned: CanvasItem;
  lacked: CanvasItem;
  longedFor: CanvasItem;
}

export interface StartStopContinue {
  start: CanvasItem;
  stop: CanvasItem;
  continue: CanvasItem;
}

export interface Kpt {
  keep: CanvasItem;
  problem: CanvasItem;
  try: CanvasItem;
}

export interface UserPersona {
  url: UrlItem;
  whoAmI: CanvasItem;
  item1: CanvasItem;
  item2: CanvasItem;
  item3: CanvasItem;
  item4: CanvasItem;
  item5: CanvasItem;
  item6: CanvasItem;
  item7: CanvasItem;
}

export interface EmpathyMap {
  imageUrl: string;
  says: CanvasItem;
  thinks: CanvasItem;
  does: CanvasItem;
  feels: CanvasItem;
}

interface CanvasItem {
  title: string;
  text: string[];
}

interface UrlItem {
  title: string;
  url: string;
}

export interface GanttChart {
  from: string;
  to: string;
  title: string;
  chartitems: GanttChartItem[];
}

interface GanttChartItem {
  title: string;
  schedules: Schedule[];
}

interface Schedule {
  from: string;
  to: string;
  title: string;
}

export interface CustomerJourneyMap {
  items: CustomerJourneyItem[];
}

interface CustomerJourneyItem {
  title: string;
  items: CanvasItem[];
}

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
    | CustomerJourneyMap
    | SiteMap
    | GanttChart
    | ImpactMap
): string {
  return "activities" in definition
    ? userStoryMap2Text(definition)
    : "keyPartners" in definition
    ? businessModelCanvas2Text(definition)
    : "problems" in definition
    ? opportunityCanvas2Text(definition)
    : "liked" in definition
    ? fourLsCanvas2Text(definition)
    : "start" in definition
    ? startStopContinueCanvas2Text(definition)
    : "keep" in definition
    ? kptCanvas2Text(definition)
    : "whoAmI" in definition
    ? userPersonaCanvas2Text(definition)
    : "node" in definition
    ? node2Text(definition)
    : "says" in definition
    ? empathyMapCanvas2Text(definition)
    : "items" in definition
    ? customerJourneyMap2Text(definition)
    : "from" in definition
    ? ganttchart2Text(definition)
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
    | CustomerJourneyMap
    | SiteMap
    | GanttChart
    | ImpactMap
): string {
  return "activities" in definition
    ? "UserStoryMap"
    : "keyPartners" in definition
    ? "BusinessModelCanvas"
    : "problems" in definition
    ? "OpportunityCanvas"
    : "liked" in definition
    ? "4Ls"
    : "start" in definition
    ? "StartStopContinue"
    : "keep" in definition
    ? "Kpt"
    : "whoAmI" in definition
    ? "UserPersona"
    : "node" in definition
    ? "MindMap"
    : "says" in definition
    ? "EmpathyMap"
    : "items" in definition
    ? "CustomerJourneyMap"
    : "from" in definition
    ? "GanttChart"
    : "UserStoryMap";
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
  .map(line => {
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
    "customerRelationships"
  ];

  return items
    .map(item => {
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
    "budget"
  ];

  return items
    .map(item => {
      return canvas2Text(opportunityCanvas[item]);
    })
    .join("");
}

function fourLsCanvas2Text(fourls: FourLs): string {
  const items = ["liked", "learned", "lacked", "longedFor"];

  return items
    .map(item => {
      return canvas2Text(fourls[item]);
    })
    .join("");
}

function startStopContinueCanvas2Text(
  startStopContinue: StartStopContinue
): string {
  const items = ["start", "stop", "continue"];

  return items
    .map(item => {
      return canvas2Text(startStopContinue[item]);
    })
    .join("");
}

function kptCanvas2Text(kpt: Kpt): string {
  const items = ["keep", "problem", "try"];

  return items
    .map(item => {
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
    "item7"
  ];

  return `${userPersona.url.title}\n    ${userPersona.url.url}\n${items
    .map(item => {
      return canvas2Text(userPersona[item]);
    })
    .join("")}`;
}

function empathyMapCanvas2Text(empathyMap: EmpathyMap): string {
  const items = ["says", "thinks", "does", "feels"];

  return `${empathyMap.imageUrl}\n${items
    .map(item => {
      return canvas2Text(empathyMap[item]);
    })
    .join("")}`;
}

function customerJourneyMap2Text(
  customerJourneyMap: CustomerJourneyMap
): string {
  return customerJourneyMap.items
    .map(
      item =>
        `${item.title}\n${item.items
          .map(
            child =>
              `    ${child.title}${
                child.text.length > 0 ? "\n" : ""
              }${child.text.map(c => `        ${c}`).join("\n")}`
          )
          .join("\n")}`
    )
    .join("\n");
}

function ganttchart2Text(ganttChart: GanttChart): string {
  return `${ganttChart.from},${ganttChart.to}: ${
    ganttChart.title
  }\n${ganttChart.chartitems
    .map(item => {
      return `    ${item.title}\n${item.schedules
        .map(schedule => {
          return `        ${schedule.from},${schedule.to}: ${schedule.title}`;
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
  return `${labels}${flatMap(activity => {
    return [activity.name].concat(
      flatMap(task => {
        return ["    " + task.name].concat(
          flatMap(story => {
            return ["    ".repeat(story.release + 1) + story.name];
          }, task.stories)
        );
      }, activity.tasks)
    );
  }, userStoryMap.activities).join("\n")}`;
}

function node2Text(map: MindMap | SiteMap | ImpactMap): string {
  const _node2Text = (node: Node[], indent: number): string[] => {
    return flatMap(n => {
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
