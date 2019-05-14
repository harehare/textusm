import * as monaco from 'monaco-editor';

const SettingsKey = 'textusm:settings';

const loadSettings = () => {
    const settings = localStorage.getItem(SettingsKey)
    return settings ? JSON.parse(settings) : defaultSettings
};

const modelUri = monaco.Uri.parse('usm://settings.json')
const model = monaco.editor.createModel('', 'json', modelUri)

const setUpSettings = app => {
    const settingsEditor = document.getElementById('settings')

    if (!settingsEditor || settingsEditor.innerHTML !== '') {
        return
    }

    monaco.languages.json.jsonDefaults.setDiagnosticsOptions({
        validate: true,
        schemas: [{
            fileMatch: [modelUri.toString()],
            schema: {
                type: 'object',
                properties: {
                    font: {
                        type: 'string'
                    },
                    storyMap: {
                        type: 'object',
                        properties: {
                            font: {
                                type: 'string'
                            },
                            size: {
                                type: 'object',
                                properties: {
                                    width: {
                                        type: 'integer'
                                    },
                                    height: {
                                        type: 'integer'
                                    }
                                }
                            },
                            color: {
                                type: 'object',
                                properties: {
                                    activity: {
                                        type: 'object',
                                        properties: {
                                            color: {
                                                type: 'string',
                                                description: 'RGB color',
                                                pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                            },
                                            backgroundColor: {
                                                type: 'string',
                                                description: 'RGB color',
                                                pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                            }
                                        }
                                    },
                                    task: {
                                        type: 'object',
                                        properties: {
                                            color: {
                                                type: 'string',
                                                description: 'RGB color',
                                                pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                            },
                                            backgroundColor: {
                                                type: 'string',
                                                description: 'RGB color',
                                                pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                            }
                                        }
                                    },
                                    story: {
                                        type: 'object',
                                        properties: {
                                            color: {
                                                type: 'string',
                                                description: 'RGB color',
                                                pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                            },
                                            backgroundColor: {
                                                type: 'string',
                                                description: 'RGB color',
                                                pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                            }
                                        }
                                    },
                                    comment: {
                                        type: 'object',
                                        properties: {
                                            color: {
                                                type: 'string',
                                                description: 'RGB color',
                                                pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                            },
                                            backgroundColor: {
                                                type: 'string',
                                                description: 'RGB color',
                                                pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                            }
                                        }
                                    },
                                    line: {
                                        type: 'string',
                                        description: 'RGB color',
                                        pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                    },
                                    label: {
                                        type: 'string',
                                        description: 'RGB color',
                                        pattern: '^#([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$'
                                    }
                                }
                            },
                            backgroundColor: {
                                type: 'string'
                            },
                        }
                    },
                    position: {
                        type: 'integer'
                    },
                    text: {
                        type: 'string'
                    },
                    title: {
                        type: 'string'
                    }
                }
            }
        }]
    });
    const monacoEditor = monaco.editor.create(
        document.getElementById('settings'), {
            model: model,
            lineNumbers: 'off',
            minimap: {
                enabled: false
            }
        }
    );

    monacoEditor.onDidChangeModelContent(() => {
        try {
            const json = JSON.parse(monacoEditor.getValue());
            app.ports.applySettings.send(json);
            saveSettings(json);
        } catch (e) {}
    });

    app.ports.editSettings.subscribe(settings => {
        setTimeout(() => {
            monacoEditor.layout();
        }, 100);
        monacoEditor.setValue(JSON.stringify(settings, null, '    '));
    });
};

const defaultSettings = {
    font: 'Open Sans',
    storyMap: {
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
    },
    position: 0,
    text: '',
    title: ''
}

const saveSettings = settings => {
    localStorage.setItem(SettingsKey, JSON.stringify(settings));
}

export {
    loadSettings,
    setUpSettings,
    saveSettings
};