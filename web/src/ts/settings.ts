import { Settings } from './model';

const SettingsKey = 'textusm:settings';

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
        scale: 1.0,
        toolbar: true,
    },
    position: -10,
    text: '',
    title: null,
    editor: {
        fontSize: 12,
        wordWrap: false,
        showLineNumber: true,
    },
    diagramId: null,
    diagram: null,
});

const loadSettings = (isDarkMode: boolean): Settings => {
    const settings = localStorage.getItem(SettingsKey);
    const defaultSettings = getDefaultSettings(isDarkMode);

    if (settings) {
        const settingsObject = JSON.parse(settings);

        return {
            ...defaultSettings,
            ...settingsObject,
            storyMap: {
                ...defaultSettings.storyMap,
                ...settingsObject.storyMap,
                color: {
                    ...defaultSettings.storyMap.color,
                    ...settingsObject.storyMap.color,
                },
            },
        };
    }

    return defaultSettings;
};

const saveSettings = (settings: Settings): void => {
    localStorage.setItem(SettingsKey, JSON.stringify(settings));
};

export { loadSettings, saveSettings };
