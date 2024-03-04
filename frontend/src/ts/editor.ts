import * as monaco from 'monaco-editor/esm/vs/editor/editor.api';
import EditorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker';
import { registerLang } from './editor/lang';
import type { ElmApp } from './elm';
import type { DiagramType } from './model';

let monacoEditor: monaco.editor.IStandaloneCodeEditor | undefined;
let updateTextInterval: number | undefined;
let _app: ElmApp | undefined;

self.MonacoEnvironment = {
  getWorker() {
    return new EditorWorker();
  },
};

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
    const t = lines[position.lineNumber - 1] ?? '';
    lines.splice(position.lineNumber - 1, 0, `${' '.repeat(t.length - t.trim().length)}` + text);
  } else {
    lines.splice(position.lineNumber - 1, 0, text);
  }

  monacoEditor.setValue(lines.join('\n'));
  monacoEditor.setPosition(new monaco.Position(position.lineNumber + 1, position.column));
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

class MonacoEditor extends HTMLElement {
  init: boolean;
  textChanged: boolean;
  editor?: monaco.editor.IStandaloneCodeEditor;

  constructor() {
    super();
    this.init = false;
    this.textChanged = false;
  }

  static get observedAttributes(): string[] {
    return ['value', 'fontSize', 'wordWrap', 'showLineNumber', 'changed', 'diagramType'];
  }

  attributeChangedCallback(
    name: 'value' | 'fontSize' | 'wordWrap' | 'showLineNumber' | 'changed' | 'diagramType',
    oldValue: string | boolean | number,
    newValue: string | boolean | number
  ): void {
    if (!this.init) {
      return;
    }

    switch (name) {
      case 'value': {
        if (newValue !== this.editor?.getValue()) {
          const position: monaco.IPosition | undefined = this.editor?.getPosition() ?? undefined;
          this.value = newValue as string;
          if (position) {
            this.editor?.setPosition(position);
          }
        }

        break;
      }

      case 'fontSize': {
        if (oldValue !== newValue) {
          this.fontSize = newValue as number;
        }

        break;
      }

      case 'wordWrap': {
        if (oldValue !== newValue) {
          this.wordWrap = newValue === 'true';
        }

        break;
      }

      case 'showLineNumber': {
        if (oldValue !== newValue) {
          this.showLineNumber = newValue === 'true';
        }

        break;
      }

      case 'changed': {
        if (oldValue !== newValue) {
          this.changed = newValue === 'true';
        }

        break;
      }

      case 'diagramType': {
        if (oldValue !== newValue) {
          this.diagramType = newValue as DiagramType;
        }

        break;
      }
    }
  }

  get value() {
    return this.editor?.getValue() ?? '';
  }

  set value(value: string) {
    this.editor?.setValue(value);
  }

  get fontSize() {
    return this.editor?.getRawOptions().fontSize ?? 0;
  }

  set fontSize(value: number) {
    this.editor?.updateOptions({ fontSize: value });
  }

  get wordWrap() {
    return this.editor?.getRawOptions().wordWrap === 'on';
  }

  set wordWrap(value: boolean) {
    this.editor?.updateOptions({ wordWrap: value ? 'on' : 'off' });
  }

  get showLineNumber() {
    return this.editor?.getRawOptions().lineNumbers === 'on';
  }

  set showLineNumber(value: boolean) {
    this.editor?.updateOptions({ lineNumbers: value ? 'on' : 'off' });
  }

  get changed() {
    return this.textChanged;
  }

  set changed(value: boolean) {
    this.textChanged = value;
    window.addEventListener('beforeunload', () => (this.textChanged ? () => true : null));
  }

  get diagramType() {
    return this.editor?.getModel()?.getLanguageId() as DiagramType;
  }

  set diagramType(value: DiagramType) {
    const model = this.editor?.getModel();
    if (model) {
      monaco.editor.setModelLanguage(model, value);
    }
  }

  async connectedCallback(): Promise<void> {
    const editorElement = document.querySelector('#editor');

    if (!editorElement) {
      return;
    }

    this.editor = monaco.editor.create(editorElement as HTMLElement, {
      language: 'UserStoryMap',
      theme: 'default',
      lineNumbers: this.getAttribute('showLineNumber') === 'true' ? 'on' : 'off',
      wordWrap: this.getAttribute('wordWrap') === 'true' ? 'on' : 'off',
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
      /* eslint  no-bitwise: 0 */
      keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyO],
      contextMenuOrder: 1,
      run() {
        _app?.ports.hotkey.send('open');
      },
    });

    this.editor.addAction({
      id: 'save',
      label: 'save',
      /* eslint  no-bitwise: 0 */
      keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS],
      contextMenuOrder: 2,
      run() {
        _app?.ports.hotkey.send('save');
      },
    });

    this.editor.addAction({
      id: 'find',
      label: 'find',
      /* eslint  no-bitwise: 0 */
      keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyF],
      contextMenuOrder: 3,
      run() {
        _app?.ports.hotkey.send('find');
      },
    });

    this.editor.addAction({
      id: 'focus',
      label: 'focus',
      /* eslint  no-bitwise: 0 */
      keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyE],
      contextMenuOrder: 4,
      run() {
        const currentLineNo = monacoEditor?.getPosition()?.lineNumber ?? -1;

        if (currentLineNo === -1) {
          return;
        }

        _app?.ports.selectItemFromLineNo.send({
          lineNo: currentLineNo - 1,
          text: monacoEditor?.getModel()?.getLineContent(currentLineNo) ?? '',
        });
      },
    });

    this.editor.onDidChangeModelContent((event) => {
      if (event.changes.length > 0) {
        if (updateTextInterval) {
          window.clearTimeout(updateTextInterval);
          updateTextInterval = undefined;
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
        this.fontSize = Number.parseInt(fontSize, 10);
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

customElements.define('monaco-editor', MonacoEditor);
