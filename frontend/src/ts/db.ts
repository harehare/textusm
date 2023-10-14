import Dexie from 'dexie';
import { v4 as uuidv4 } from 'uuid';

import type { ElmApp } from './elm';
import type { Diagram, DiagramItem } from './model';

class LocalDatabase extends Dexie {
  diagrams: Dexie.Table<DiagramItem, string>;

  constructor() {
    super('textusm');
    this.version(2).stores({
      diagrams: '++id,title,text,thumbnail,diagramPath,createdAt,updatedAt',
    });

    this.version(2)
      .stores({
        diagrams: '++id,title,text,thumbnail,diagram,isBookmark,createdAt,updatedAt',
      })
      .upgrade((trans) => {
        // @ts-expect-error: Unreachable code error
        return trans.diagrams.toCollection().modify((d: DiagramItem & { diagramPath?: string }) => {
          d.diagram = d.diagramPath ?? '';
          d.isBookmark = false;
          delete d.diagramPath;
        });
      });
    this.version(3).upgrade((trans) =>
      // @ts-expect-error: Unreachable code error
      trans.diagrams.toCollection().modify((d: DiagramItem) => {
        d.diagram = d.diagram === 'cjm' ? 'table' : '';
      })
    );
    this.diagrams = this.table('diagrams');
  }
}

export const initDB = (app: ElmApp): void => {
  const db = new LocalDatabase();
  const svg2base64 = async (id: string) => {
    // @ts-expect-error: Unreachable code error
    const svgoImport = await import('svgo/dist/svgo.browser.js').catch(() => null);

    if (!svgoImport) {
      app.ports.sendErrorNotification.send('Failed to load chunks. Please reload.');
      return '';
    }

    const svgo = svgoImport.default;
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', '0 0 1280 960');
    svg.setAttribute('width', '320');
    svg.setAttribute('height', '240');
    svg.setAttribute('style', 'background-color: #F5F5F6;');
    const elm = document.querySelector(`#${id}`);

    if (elm) {
      svg.innerHTML = elm.innerHTML;
    }

    return `data:image/svg+xml;base64,${window.btoa(
      unescape(
        encodeURIComponent(
          await svgo.optimize(new XMLSerializer().serializeToString(svg), {
            plugins: [
              {
                name: 'preset-default',
                params: {
                  overrides: {
                    convertShapeToPath: {
                      convertArcs: true,
                    },
                    convertPathData: false,
                  },
                },
              },
            ],
          }).data
        )
      )
    )}`;
  };

  app.ports.saveDiagram.subscribe(async ({ id, title, text, diagram, location, isPublic, isBookmark }: Diagram) => {
    const thumbnail = await svg2base64('usm');
    const createdAt = Date.now();
    const diagramItem: DiagramItem = {
      id,
      title,
      text,
      thumbnail,
      diagram,
      isPublic,
      isBookmark,
      location,
      createdAt,
      updatedAt: createdAt,
    };

    if (location === 'local') {
      const item = {
        ...diagramItem,
        id: id ?? uuidv4(),
        isPublic: false,
      };
      await db.diagrams.put(item);
      app.ports.saveToLocalCompleted.send(item);
    } else {
      app.ports.saveToRemote.send({
        ...diagramItem,
        id,
        isPublic,
      });
    }
  });

  app.ports.importDiagram.subscribe(async (diagrams: DiagramItem[]) => {
    await db.diagrams.bulkPut(diagrams);
    app.ports.reload.send('');
  });

  app.ports.removeDiagrams.subscribe(async (diagram: Diagram) => {
    const { id, location } = diagram;
    if (location === 'remote') {
      app.ports.removeRemoteDiagram.send(diagram);
    } else {
      await db.diagrams.delete(id);
      app.ports.removedLocalDiagram.send(id);
    }
  });

  app.ports.getDiagram.subscribe(async (diagramId: string) => {
    const diagram = await db.diagrams.get(diagramId);

    if (diagram) {
      app.ports.gotLocalDiagramJson.send({
        ...diagram,
        isPublic: false,
      });
    }
  });

  app.ports.getDiagramForCopy.subscribe(async (diagramId: string) => {
    const diagram = await db.diagrams.get(diagramId);

    if (diagram) {
      app.ports.gotLocalDiagramJsonForCopy.send({
        ...diagram,
        isPublic: false,
      });
    }
  });

  app.ports.getDiagrams.subscribe(async () => {
    const diagrams = await db.diagrams.orderBy('updatedAt').reverse().toArray();
    app.ports.gotLocalDiagramsJson.send(
      diagrams.map((d: DiagramItem) => ({
        ...d,
        isPublic: false,
        isRemote: false,
      }))
    );
  });
};
