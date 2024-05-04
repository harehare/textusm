import * as monaco from 'monaco-editor';
import type { Settings, DiagramType } from '../model';
import { isDarkMode } from '../utils';

export const loadEditor = (settings: Settings) => {
  const isDark = settings.theme === 'dark' || ((settings.theme ?? 'system') === 'system' && isDarkMode);

  monaco.editor.defineTheme('default', {
    base: isDark ? 'vs-dark' : 'vs',
    inherit: true,
    colors: {
      'editor.background': isDark ? '#273037' : '#FEFEFE',
    },
    rules: [
      {
        token: 'comment',
        foreground: '#008800',
      },
      {
        token: 'hidden',
        foreground: '#323d46',
      },
      {
        token: 'indent1',
        foreground: '#439ad9',
        fontStyle: 'bold',
      },
      {
        token: 'indent2',
        foreground: '#3a5aba',
      },
      {
        token: 'indent3',
        foreground: isDark ? '#c4c0b9' : '#000000',
      },
      {
        token: 'attribute',
        foreground: '#ce9887',
        fontStyle: 'bold',
      },
      {
        token: 'property',
        foreground: '#f9c859',
        fontStyle: 'bold',
      },
      {
        token: 'constant',
        foreground: '#9f7efe',
        fontStyle: 'bold',
      },
    ],
  });
};

export const registerLang = () => {
  const tokenizerForMap: monaco.languages.IMonarchLanguage = {
    tokenizer: {
      root: [
        [/#[^.*#[^:]+:.+$/, 'property'],
        [/#[^#|]+/, 'comment'],
        [/^[^ ][^#:|]+/, 'indent1'],
        [/^ {20}[^#:|]+/, 'indent3'],
        [/^ {12}[^#:|]+/, 'indent1'],
        [/^ {16}[^#:|]+/, 'indent2'],
        [/^ {8}[^#:|]+/, 'indent3'],
        [/^ {4}[^#:|]+/, 'indent2'],
        [/\|[^|]+/, 'hidden'],
      ],
    },
  };
  const tokenizerForCanvas: monaco.languages.IMonarchLanguage = {
    tokenizer: {
      root: [
        [/#[^.*#[^:]+:[^:]+$/, 'property'],
        [/#[^#|]+/, 'comment'],
        [/^[^ ][^#:|]+/, 'indent1'],
        [/\|[^|]+/, 'hidden'],
      ],
    },
  };
  const tokenizerForGantt: monaco.languages.IMonarchLanguage = {
    tokenizer: {
      root: [
        [/#[^#|]+/, 'comment'],
        [/^ {8}[^#:|]+/, 'indent3'],
        [/^ {4}[^#:|]+/, 'indent2'],
        [/\d{4}-\d{2}-\d{2}.*/, 'attribute'],
      ],
    },
  };
  const tokenizerForKeyboardLayout: monaco.languages.IMonarchLanguage = {
    tokenizer: {
      root: [
        [/#[^.*#[^:]+:.+$/, 'property'],
        [/#[^#|]+/, 'comment'],
        [/^[^ ][^#:|]+/, 'indent1'],
        [/^ {4}[^#:|]+/, 'indent3'],
        [/\|[^|]+/, 'hidden'],
      ],
    },
  };

  const map: ReadonlyArray<[DiagramType, monaco.languages.IMonarchLanguage]> = [
    ['BusinessModelCanvas', tokenizerForCanvas],
    ['OpportunityCanvas', tokenizerForCanvas],
    ['Fourls', tokenizerForCanvas],
    ['StartStopContinue', tokenizerForCanvas],
    ['Kpt', tokenizerForCanvas],
    ['UserStoryMap', tokenizerForMap],
    ['UserPersona', tokenizerForMap],
    ['MindMap', tokenizerForMap],
    ['EmpathyMap', tokenizerForMap],
    ['ErDiagram', tokenizerForMap],
    ['Kanban', tokenizerForMap],
    ['UseCaseDiagram', tokenizerForMap],
    ['SequenceDiagram', tokenizerForMap],
    ['Freeform', tokenizerForMap],
    ['GanttChart', tokenizerForGantt],
    ['KeyboardLayout', tokenizerForKeyboardLayout],
  ];

  for (const [type, tokenizer] of map) {
    monaco.languages.register({
      id: type,
    });

    monaco.languages.setMonarchTokensProvider(type, tokenizer);
  }
};
