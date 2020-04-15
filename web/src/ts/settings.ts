import { Settings } from "./model";

const SettingsKey = "textusm:settings";

const loadSettings = (): Settings => {
    const settings = localStorage.getItem(SettingsKey);

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

const defaultSettings = {
    font: "Roboto",
    storyMap: {
        font: "Roboto",
        size: {
            width: 140,
            height: 65,
        },
        color: {
            activity: {
                color: "#FFFFFF",
                backgroundColor: "#266B9A",
            },
            task: {
                color: "#FFFFFF",
                backgroundColor: "#3E9BCD",
            },
            story: {
                color: "#333333",
                backgroundColor: "#FFFFFF",
            },
            line: "#434343",
            label: "#8C9FAE",
            text: "#111111",
        },
        backgroundColor: "#F4F4F5",
        zoomControl: true,
    },
    position: -10,
    text: "",
    title: null,
    editor: {
        fontSize: 12,
        wordWrap: false,
        showLineNumber: true,
    },
    diagramId: null,
    diagram: null,
};

const saveSettings = (settings: Settings) => {
    localStorage.setItem(SettingsKey, JSON.stringify(settings));
};

export { loadSettings, saveSettings };
