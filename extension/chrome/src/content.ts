import * as textusm from 'textusm';

interface Config {
  tag: string;
  type: 'BusinessModelCanvas' | 'UserStoryMap' | 'OpportunityCanvas';
}

const config: Config[] = [
  {
    tag: 'textusm',
    type: 'UserStoryMap'
  },
  {
    tag: 'textbmc',
    type: 'BusinessModelCanvas'
  },
  {
    tag: 'textopc',
    type: 'OpportunityCanvas'
  }
];

config.forEach(item => {
  document.querySelectorAll(`[lang="${item.tag}"]`).forEach(e => {
    (e as HTMLElement).style.height = '360px';
    (e as HTMLElement).style.overflow = 'hidden';
    const code = e.querySelector('code');
    if (code) {
      const text = code.textContent;
      if (text) {
        textusm.render(code, text, { type: item.type });
      }
    }
  });
});
