import { Elm } from './js/elm';
import { UserStoryMap, BusinessModelCanvas, OpportunityCanvas, toString, toTypeString } from './model';

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

function render(
  idOrElm: string | HTMLElement,
  definition: string | UserStoryMap | BusinessModelCanvas | OpportunityCanvas,
  options?: {
    diagramType?: 'UserStoryMap' | 'BusinessModelCanvas' | 'OpportunityCanvas';
    size?: Size;
    showZoomControl?: boolean;
  },
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

  const text = typeof definition === 'string' ? definition : toString(definition);

  Elm.Extension.Lib.init({
    node: elm,
    flags: {
      text,
      diagramType: options.diagramType
        ? options.diagramType
        : typeof definition === 'string'
        ? 'UserStoryMap'
        : toTypeString(definition),
      width: options.size ? options.size.width : 1024,
      height: options.size ? options.size.height : 1024,
      settings: Object.assign(defaultConfig, config),
      showZoomControl: options.showZoomControl !== undefined ? options.showZoomControl : true
    }
  });
}

export { render };
