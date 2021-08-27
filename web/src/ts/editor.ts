import * as monaco from 'monaco-editor';

import { ElmApp } from './elm';

let monacoEditor: monaco.editor.IStandaloneCodeEditor | null = null;
let updateTextInterval: number | null = null;
let _app: ElmApp | null;

const focusEditor = () => {
    setTimeout(() => {
        monacoEditor?.focus();
    }, 100);
};

export const setElmApp = (app: ElmApp): void => {
    _app = app;
    _app.ports.focusEditor.unsubscribe(focusEditor);
    _app.ports.focusEditor.subscribe(focusEditor);
};

monaco.languages.register({
    id: 'userStoryMap',
});

monaco.languages.setMonarchTokensProvider('userStoryMap', {
    tokenizer: {
        root: [
            [/^ *#.+/, 'comment'],
            [/^[^ ][^#:||]+/, 'activity'],
            [/^ {8}[^#:||]+/, 'story'],
            [/^ {4}[^#:||]+/, 'task'],
            [/#.+/, 'color'],
            [/\|[^|]+/, 'color'],
        ],
    },
});

monaco.editor.defineTheme('usmTheme', {
    base: 'vs-dark',
    inherit: true,
    colors: {
        'editor.background': '#273037',
    },
    rules: [
        {
            token: 'comment',
            foreground: '#008800',
        },
        {
            token: 'color',
            foreground: '#323d46',
        },
        {
            token: 'activity',
            foreground: '#439ad9',
        },
        {
            token: 'task',
            foreground: '#3a5aba',
        },
        {
            token: 'story',
            foreground: '#c4c0b9',
        },
    ],
});

export class MonacoEditor extends HTMLElement {
    init: boolean;

    textChanged: boolean;

    editor: monaco.editor.IStandaloneCodeEditor | null;

    constructor() {
        super();
        this.init = false;
        this.editor = null;
        this.textChanged = false;
    }

    static get observedAttributes(): string[] {
        return ['value', 'fontSize', 'wordWrap', 'showLineNumber', 'changed'];
    }

    attributeChangedCallback(
        name: string,
        oldValue: string | boolean | number,
        newValue: string | boolean | number
    ): void {
        if (!this.init) {
            return;
        }
        switch (name) {
            case 'value':
                if (newValue !== this.editor?.getValue()) {
                    const position: monaco.IPosition | null | undefined =
                        this.editor?.getPosition();
                    this.value = newValue as string;
                    if (position) {
                        this.editor?.setPosition(position);
                    }
                }
                break;
            case 'fontSize':
                if (oldValue !== newValue) {
                    this.fontSize = newValue as number;
                }
                break;
            case 'wordWrap':
                if (oldValue !== newValue) {
                    this.wordWrap = newValue === 'true';
                }
                break;
            case 'showLineNumber':
                if (oldValue !== newValue) {
                    this.showLineNumber = newValue === 'true';
                }
                break;
            case 'changed':
                if (oldValue !== newValue) {
                    this.changed = newValue === 'true';
                }
                break;
            default:
                throw new Error(`Unknown attribute ${name}`);
        }
    }

    set value(value: string) {
        this.editor?.setValue(value);
    }

    set fontSize(value: number) {
        this.editor?.updateOptions({ fontSize: value });
    }

    set wordWrap(value: boolean) {
        this.editor?.updateOptions({ wordWrap: value ? 'on' : 'off' });
    }

    set showLineNumber(value: boolean) {
        this.editor?.updateOptions({ lineNumbers: value ? 'on' : 'off' });
    }

    set changed(value: boolean) {
        this.textChanged = value;
        window.onbeforeunload = this.textChanged
            ? () => {
                  return true;
              }
            : null;
    }

    async connectedCallback(): Promise<void> {
        const editor = document.getElementById('editor') as HTMLElement | null;
        if (editor) {
            this.editor = monaco.editor.create(editor, {
                language: 'userStoryMap',
                theme: 'usmTheme',
                lineNumbers:
                    this.getAttribute('showLineNumber') === 'true'
                        ? 'on'
                        : 'off',
                wordWrap:
                    this.getAttribute('wordWrap') === 'true' ? 'on' : 'off',
                minimap: {
                    enabled: false,
                },
                fontSize: 14,
                mouseWheelZoom: true,
                automaticLayout: true,
                scrollbar: {
                    verticalScrollbarSize: 6,
                    horizontalScrollbarSize: 6,
                },
                renderLineHighlight: 'none',
            });

            this.editor.addAction({
                id: 'open',
                label: 'open',
                keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_O],
                contextMenuOrder: 1,
                run: () => {
                    _app?.ports.shortcuts.send('open');
                },
            });

            this.editor.addAction({
                id: 'save-to-local',
                label: 'save',
                keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KEY_S],
                contextMenuOrder: 2,
                run: () => {
                    _app?.ports.shortcuts.send('save');
                },
            });

            this.editor.onDidChangeModelContent((e) => {
                if (e.changes.length > 0) {
                    if (updateTextInterval) {
                        window.clearTimeout(updateTextInterval);
                        updateTextInterval = null;
                    }
                    updateTextInterval = window.setTimeout(() => {
                        if (this.editor) {
                            _app?.ports.changeText.send(this.editor.getValue());
                        }
                    }, 300);
                }
            });

            if (this.hasAttribute('value')) {
                const value = this.getAttribute('value');
                if (value) {
                    this.value = value;
                }
            }

            if (this.hasAttribute('fontSize')) {
                const fontSize = this.getAttribute('fontSize');
                if (fontSize) {
                    this.fontSize = parseInt(fontSize, 10);
                }
            }

            this.init = true;
            monacoEditor = this.editor;
        }
    }
}

customElements.define('monaco-editor', MonacoEditor);
