import * as monaco from 'monaco-editor';

import { registerLang } from './editor/lang';
// @ts-ignore
import { ElmApp } from './elm';
import { DiagramType } from './model';

let monacoEditor: monaco.editor.IStandaloneCodeEditor | null = null;
let updateTextInterval: number | null = null;
let _app: ElmApp | null;

const focusEditor = () => {
    setTimeout(() => {
        monacoEditor?.focus();
    }, 100);
};

const insertText = (text: string) => {
    if (!monacoEditor) {
        return;
    }

    const position = monacoEditor.getPosition();
    const lines = monacoEditor.getValue().split('\n');
    if (!position) {
        return;
    }

    if (lines[position.lineNumber - 1]) {
        const t = lines[position.lineNumber - 1] || '';
        lines.splice(
            position.lineNumber - 1,
            0,
            `${' '.repeat(t.length - t.trim().length)}` + text
        );
    } else {
        lines.splice(position.lineNumber - 1, 0, text);
    }

    monacoEditor.setValue(lines.join('\n'));
    monacoEditor.setPosition(
        new monaco.Position(position.lineNumber + 1, position.column)
    );
};

export const setElmApp = (app: ElmApp): void => {
    if (_app) {
        _app.ports.focusEditor.unsubscribe(focusEditor);
        _app.ports.insertText.unsubscribe(insertText);
    }
    _app = app;
    _app.ports.focusEditor.subscribe(focusEditor);
    _app.ports.insertText.subscribe(insertText);
};

registerLang();

const ENABLED_LANG_DIAGRAM_TYPE: { [v in DiagramType]: DiagramType } = {
    UserStoryMap: 'UserStoryMap',
    MindMap: 'UserStoryMap',
    ImpactMap: 'UserStoryMap',
    SiteMap: 'UserStoryMap',
    SequenceDiagram: 'UserStoryMap',
    Freeform: 'UserStoryMap',
    UseCaseDiagram: 'UserStoryMap',
    ErDiagram: 'UserStoryMap',
    GanttChart: 'GanttChart',
    BusinessModelCanvas: 'BusinessModelCanvas',
    OpportunityCanvas: 'BusinessModelCanvas',
    Fourls: 'BusinessModelCanvas',
    StartStopContinue: 'BusinessModelCanvas',
    Kpt: 'BusinessModelCanvas',
    UserPersona: 'BusinessModelCanvas',
    EmpathyMap: 'BusinessModelCanvas',
    Kanban: 'BusinessModelCanvas',
    Table: 'BusinessModelCanvas',
};
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
        return [
            'value',
            'fontSize',
            'wordWrap',
            'showLineNumber',
            'changed',
            'diagramType',
        ];
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
            case 'diagramType':
                if (oldValue !== newValue) {
                    this.diagramType = newValue as DiagramType;
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

    set diagramType(value: DiagramType) {
        const model = this.editor?.getModel();
        if (model) {
            monaco.editor.setModelLanguage(
                model,
                ENABLED_LANG_DIAGRAM_TYPE[value]
            );
        }
    }

    async connectedCallback(): Promise<void> {
        const editor = document.getElementById('editor') as HTMLElement | null;
        if (editor) {
            this.editor = monaco.editor.create(editor, {
                language: 'UserStoryMap',
                theme: 'default',
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
                keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyO],
                contextMenuOrder: 1,
                run: () => {
                    _app?.ports.shortcuts.send('open');
                },
            });

            this.editor.addAction({
                id: 'save-to-local',
                label: 'save',
                keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS],
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

            if (this.hasAttribute('diagramType')) {
                const d = this.getAttribute('diagramType');
                if (d) {
                    this.diagramType = d as DiagramType;
                }
            }

            this.init = true;
            monacoEditor = this.editor;
        }
    }
}

customElements.define('monaco-editor', MonacoEditor);
