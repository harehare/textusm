import { ElmApp } from './elm';

export const canUseNativeFileSystem = 'showOpenFilePicker' in window;

const extensions = [
    '.txt',
    '.usm',
    '.opc',
    '.bmc',
    '.4ls',
    '.ssc',
    '.kpt',
    '.persona',
    '.mmp',
    '.emm',
    '.table',
    '.smp',
    '.gct',
    '.imm',
    '.erd',
    '.kanban',
    '.sed',
    '.free',
    '.ucd',
];

const openFile = async () => {
    try {
        // @ts-expect-error
        const [handle] = await window.showOpenFilePicker({
            types: [
                {
                    description: 'Text Files',
                    accept: {
                        'text/plain': extensions,
                    },
                },
            ],
            excludeAcceptAllOption: true,
            multiple: false,
        });
        const file = await handle.getFile();
        return [handle, file.name, await file.text()];
    } catch {
        return null;
    }
};

const saveFile = async (text: string, fileHandle?: any, title?: string) => {
    try {
        const handle =
            fileHandle && fileHandle.name === title
                ? fileHandle
                : // @ts-expect-error
                  await window.showSaveFilePicker({
                      suggestedName: title,
                      types: [
                          {
                              description: 'Text Files',
                              accept: {
                                  'text/plain': extensions,
                              },
                          },
                      ],
                  });

        const writable = await handle.createWritable();
        await writable.write(text);
        await writable.close();
        return handle;
    } catch {
        return null;
    }
};

export const initFile = (app: ElmApp): void => {
    // @ts-expect-error
    let fileHandle = null;

    app.ports.openLocalFile.subscribe(async () => {
        const file = await openFile();
        if (!file) {
            return;
        }
        const [handle, name, text] = file;
        app.ports.openedLocalFile.send([name, text]);
        fileHandle = handle;
    });

    app.ports.saveLocalFile.subscribe(async (diagram) => {
        // @ts-expect-error
        const handle = await saveFile(diagram.text, fileHandle, diagram.title);
        if (!handle) {
            return;
        }
        fileHandle = handle;
        const file = await handle.getFile();
        app.ports.savedLocalFile.send(file.name);
    });

    app.ports.closeLocalFile.subscribe(() => {
        fileHandle = null;
    });
};
