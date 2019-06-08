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

interface CanvasItem {
  title: string;
  text: string[];
}

export function toString(definition: UserStoryMap | BusinessModelCanvas | OpportunityCanvas): string {
  return 'activities' in definition
    ? userStoryMap2Text(definition)
    : 'keyPartners' in definition
    ? businessModelCanvas2Text(definition)
    : 'problems' in definition
    ? opportunityCanvas2Text(definition)
    : '';
}

export function toTypeString(definition: UserStoryMap | BusinessModelCanvas | OpportunityCanvas): string {
  return 'activities' in definition
    ? 'UserStoryMap'
    : 'keyPartners' in definition
    ? 'BusinessModelCanvas'
    : 'problems' in definition
    ? 'OpportunityCanvas'
    : 'UserStoryMap';
}

function concat<T>(x: T[], y: T[]): T[] {
  return x.concat(y);
}

function flatMap<T, U>(f: (x: T) => U[], xs: T[]): U[] {
  return xs.map(f).reduce(concat, []);
}

function canvas2Text(item: CanvasItem) {
  return `${item.title}
${item.text
  .map(line => {
    return `    ${line}`;
  })
  .join('\n')}
`;
}

function businessModelCanvas2Text(businessModelCanvas: BusinessModelCanvas): string {
  const items = [
    'keyPartners',
    'customerSegments',
    'valueProposition',
    'keyActivities',
    'channels',
    'revenueStreams',
    'costStructure',
    'keyResources',
    'customerRelationships'
  ];

  return items
    .map(item => {
      return canvas2Text(businessModelCanvas[item]);
    })
    .join('\n');
}

function opportunityCanvas2Text(opportunityCanvas: OpportunityCanvas): string {
  const items = [
    'problems',
    'solutionIdeas',
    'usersAndCustomers',
    'solutionsToday',
    'businessChallenges',
    'howWillUsersUseSolution',
    'userMetrics',
    'adoptionStrategy',
    'businessBenefitsAndMetrics',
    'budget'
  ];

  return items
    .map(item => {
      return canvas2Text(opportunityCanvas[item]);
    })
    .join('\n');
}

function userStoryMap2Text(userStoryMap: UserStoryMap): string {
  const labels =
    userStoryMap.labels && userStoryMap.labels.length > 0 ? `#labels: ${userStoryMap.labels.join(',')}` : '';
  return `${labels}\n${flatMap(activity => {
    return [activity.name].concat(
      flatMap(task => {
        return ['    ' + task.name].concat(
          flatMap(story => {
            return ['    '.repeat(story.release + 1) + story.name];
          }, task.stories)
        );
      }, activity.tasks)
    );
  }, userStoryMap.activities).join('\n')}`;
}
