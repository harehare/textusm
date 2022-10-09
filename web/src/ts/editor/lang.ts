import * as monaco from 'monaco-editor';

import { isDarkMode } from '../utils';

monaco.editor.defineTheme('default', {
  base: isDarkMode ? 'vs-dark' : 'vs',
  inherit: true,
  colors: {
    'editor.background': isDarkMode ? '#273037' : '#FEFEFE',
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
      foreground: isDarkMode ? '#c4c0b9' : '#000000',
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

const addUserStoryMap = () => {
  monaco.languages.register({
    id: 'UserStoryMap',
  });

  monaco.languages.setMonarchTokensProvider('UserStoryMap', {
    tokenizer: {
      root: [
        [/#[^.*#[^:]+:[^:]+$/, 'property'],
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
  });
};

const addGanttChart = () => {
  monaco.languages.register({
    id: 'GanttChart',
  });

  monaco.languages.setMonarchTokensProvider('GanttChart', {
    tokenizer: {
      root: [
        [/#[^#|]+/, 'comment'],
        [/^ {8}[^#:|]+/, 'indent3'],
        [/^ {4}[^#:|]+/, 'indent2'],
        [/\d{4}-\d{2}-\d{2}.*/, 'attribute'],
      ],
    },
  });
};

const addBusinessModelCanvas = () => {
  monaco.languages.register({
    id: 'BusinessModelCanvas',
  });

  monaco.languages.setMonarchTokensProvider('BusinessModelCanvas', {
    tokenizer: {
      root: [
        [/#[^.*#[^:]+:[^:]+$/, 'property'],
        [/#[^#|]+/, 'comment'],
        [/^[^ ][^#:|]+/, 'indent1'],
        [/\|[^|]+/, 'hidden'],
      ],
    },
  });
};

export const registerLang = () => {
  addUserStoryMap();
  addGanttChart();
  addBusinessModelCanvas();
};
