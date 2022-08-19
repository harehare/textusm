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

const openFile = async (): Promise<[FileSystemFileHandle, string, string] | undefined> => {
  try {
    const [handle]: [FileSystemFileHandle] = await showOpenFilePicker({
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
    return undefined;
  }
};

const saveFile = async (text: string, fileHandle: FileSystemFileHandle, title: string) => {
  try {
    const handle =
      fileHandle?.name === title
        ? fileHandle
        : await showSaveFilePicker({
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

    if (!handle) {
      return null;
    }

    const writable = await handle.createWritable();
    await writable.write(text);
    await writable.close();
    return handle;
  } catch {
    return null;
  }
};

export const initFile = (app: ElmApp): void => {
  let fileHandle: FileSystemFileHandle | undefined;

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
    if (!fileHandle) {
      return;
    }

    const handle = await saveFile(diagram.text, fileHandle, diagram.title);
    if (!handle) {
      return;
    }

    fileHandle = handle;
    const file = await handle.getFile();
    app.ports.savedLocalFile.send(file.name);
  });

  app.ports.closeLocalFile.subscribe(() => {
    fileHandle = undefined;
  });
};
