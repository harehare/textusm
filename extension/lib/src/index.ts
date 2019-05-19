import { Elm } from './js/elm';

interface Settings {
  font?: string;
  size?: Size;
  color?: ColorSettings;
  backgroundColor?: string;
}

interface ColorSettings {
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

const defaultSettings: Settings = {
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

export const render = (id: string, text: string, size?: Size, settings?: Settings) => {
  const elm = document.getElementById(id);

  if (!elm) {
    throw new Error(`Element "${id}" is not found.`);
  }

  settings.color = Object.assign(defaultSettings.color, settings.color);
  settings.size = Object.assign(defaultSettings.size, settings.size);

  Elm.Extension.Lib.init({
    node: elm,
    flags: {
      text,
      width: size ? size.width : 1024,
      height: size ? size.height : 1024,
      settings: Object.assign(defaultSettings, settings)
    }
  });
};
