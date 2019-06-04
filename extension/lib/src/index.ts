import { Elm } from './js/elm';

interface UserStoryMap {
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
  font: 'Open Sans',
  size: {
    width: 140,
    height: 65
  },
  color: {
    activity: {
      color: '#FFFFFF',
      backgroundColor: '#266B9A'
    },
    task: {
      color: '#FFFFFF',
      backgroundColor: '#3E9BCD'
    },
    story: {
      color: '#000000',
      backgroundColor: '#FFFFFF'
    },
    comment: {
      color: '#000000',
      backgroundColor: '#F1B090'
    },
    line: '#434343',
    label: '#8C9FAE'
  },
  backgroundColor: '#F5F5F6'
};

function concat<T>(x: T[], y: T[]): T[] {
  return x.concat(y);
}

function flatMap<T, U>(f: (x: T) => U[], xs: T[]): U[] {
  return xs.map(f).reduce(concat, []);
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

function render(
  idOrElm: string | HTMLElement,
  definition: string | UserStoryMap,
  options?: { size?: Size; showZoomControl?: boolean },
  config?: Config
) {
  const elm = typeof idOrElm === 'string' ? document.getElementById(idOrElm) : idOrElm;

  if (!elm) {
    throw new Error(typeof idOrElm === 'string' ? `Element "${idOrElm}" is not found.` : `Element is not found.`);
  }

  options = options ? options : {};
  config = config ? config : {};
  config.color = Object.assign(defaultConfig.color, config.color);
  config.size = Object.assign(defaultConfig.size, config.size);

  const text = typeof definition === 'string' ? definition : userStoryMap2Text(definition);

  Elm.Extension.Lib.init({
    node: elm,
    flags: {
      text,
      width: options.size ? options.size.width : 1024,
      height: options.size ? options.size.height : 1024,
      settings: Object.assign(defaultConfig, config),
      showZoomControl: options.showZoomControl !== undefined ? options.showZoomControl : true
    }
  });
}

export { render };
