import type { DiagramSettings, Settings } from './model';

const settingsKey = 'textusm:settings';

const getSettingsKey = (diagram: string) => `${settingsKey}:${diagram}`;

const getDefaultSettings = (isDarkMode: boolean) => ({
  font: 'Nunito Sans',
  storyMap: {
    font: 'Nunito Sans',
    size: {
      width: 140,
      height: 65,
    },
    color: {
      activity: {
        color: '#FFFFFF',
        backgroundColor: '#266B9A',
      },
      task: {
        color: '#FFFFFF',
        backgroundColor: '#3E9BCD',
      },
      story: {
        color: '#333333',
        backgroundColor: '#FFFFFF',
      },
      line: '#434343',
      label: '#8C9FAE',
      text: '#111111',
    },
    backgroundColor: isDarkMode ? '#323d46' : '#F4F4F5',
    zoomControl: true,
    scale: 1,
    toolbar: true,
  },
  position: -10,
  text: '',
  title: undefined,
  editor: {
    fontSize: 12,
    wordWrap: false,
    showLineNumber: true,
  },
  diagramId: undefined,
  diagram: undefined,
});

export const loadSettings = (isDarkMode: boolean, diagram?: string): Settings => {
  const settingsString = localStorage.getItem(settingsKey);
  const diagramSettingsString = diagram ? localStorage.getItem(getSettingsKey(diagram)) : null;
  const defaultSettings = getDefaultSettings(isDarkMode);

  if (settingsString) {
    const diagramSettings = diagramSettingsString
      ? (JSON.parse(diagramSettingsString) as DiagramSettings)
      : { color: {} };
    const settingsObject = JSON.parse(settingsString) as Settings;
    return {
      ...defaultSettings,
      ...settingsObject,
      storyMap: {
        ...defaultSettings.storyMap,
        ...settingsObject.storyMap,
        ...diagramSettings,
        color: {
          ...defaultSettings.storyMap.color,
          ...settingsObject.storyMap.color,
          ...diagramSettings.color,
        },
      },
    };
  }

  return defaultSettings;
};

export const saveSettings = (settings: Settings): void => {
  localStorage.setItem(
    settingsKey,
    JSON.stringify({
      font: settings.font,
      position: settings.position,
      text: settings.text,
      title: settings.title,
      diagramId: settings.diagramId,
      storyMap: settings.storyMap,
      diagram: settings.diagram,
    })
  );

  if (settings.diagram?.diagram) {
    localStorage.setItem(getSettingsKey(settings.diagram?.diagram), JSON.stringify(settings.storyMap));
  }
};
