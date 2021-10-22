import { ElmApp } from './elm';

export const canUseNativeFileSystem = 'showOpenFilePicker' in window;

export const openFile = async () => {
    // @ts-expect-error
    const [handle] = await window.showOpenFilePicker();
    const file = await handle.getFile();
    return [handle, await file.text()];
};

export const saveFile = async (text: string, fileHandle?: any) => {
    const handle = fileHandle
        ? fileHandle
        : // @ts-expect-error
          await window.showSaveFilePicker({
              types: [
                  {
                      description: 'Text Files',
                      accept: {
                          'text/plain': ['.txt', '.md', '.usm'],
                      },
                  },
              ],
          });
    // @ts-expect-error
    await writeFile(handle, text);
    return handle;
};

export const initFile = (app: ElmApp): void => {
    // let openFileHandle = null;
};
