const SettingsKey = "textusm:settings";

const loadSettings = () => {
    const settings = localStorage.getItem(SettingsKey);
    return settings
        ? Object.assign(defaultSettings, JSON.parse(settings))
        : defaultSettings;
};

const defaultSettings = {
    font: "Roboto",
    storyMap: {
        font: "Roboto",
        size: {
            width: 140,
            height: 65
        },
        color: {
            activity: {
                color: "#FFFFFF",
                backgroundColor: "#266B9A"
            },
            task: {
                color: "#FFFFFF",
                backgroundColor: "#3E9BCD"
            },
            story: {
                color: "#333333",
                backgroundColor: "#FFFFFF"
            },
            line: "#434343",
            label: "#8C9FAE"
        },
        backgroundColor: "#F4F4F5"
    },
    position: -10,
    text: "",
    title: null,
    miniMap: true,
    diagramId: null,
    github: null
};

const saveSettings = settings => {
    localStorage.setItem(SettingsKey, JSON.stringify(settings));
};

export { loadSettings, saveSettings };
