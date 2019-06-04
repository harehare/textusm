import * as textusm from 'textusm';

document.querySelectorAll('[lang="textusm"]').forEach(e => {
  (e as HTMLElement).style.height = '360px';
  (e as HTMLElement).style.overflow = 'hidden';
  const code = e.querySelector('code');
  if (code) {
    const text = code.textContent;
    if (text) {
      textusm.render(code, text);
    }
  }
});
