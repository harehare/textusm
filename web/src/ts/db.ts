import { v4 as uuidv4 } from "uuid";
import Dexie from "dexie";
import { Diagram, DiagramItem } from "./model";
import { ElmApp } from "./elm";

export const initDB = (app: ElmApp): void => {
    const lazyDB = () => {
        let db: Dexie | null = null;

        return async (): Promise<Dexie> => {
            if (!db) {
                db = new (await import("dexie")).default("textusm");
                db.version(2).stores({
                    diagrams:
                        "++id,title,text,thumbnail,diagramPath,createdAt,updatedAt",
                });

                db.version(2)
                    .stores({
                        diagrams:
                            "++id,title,text,thumbnail,diagram,isBookmark,createdAt,updatedAt",
                    })
                    .upgrade((trans) => {
                        return (
                            // @ts-ignore
                            trans.diagrams
                                .toCollection()
                                // @ts-ignore
                                .modify((d) => {
                                    d.diagram = d.diagramPath;
                                    d.isBookmark = false;
                                    delete d.diagramPath;
                                })
                        );
                    });
                db.version(3).upgrade((trans) => {
                    return (
                        // @ts-ignore
                        trans.diagrams
                            .toCollection()
                            // @ts-ignore
                            .modify((d) => {
                                d.diagram = d.diagram === "cjm" ? "table" : "";
                            })
                    );
                });
            }
            return db;
        };
    };
    const db = lazyDB();
    const svg2base64 = (id: string) => {
        const svg = document.createElementNS(
            "http://www.w3.org/2000/svg",
            "svg"
        );
        svg.setAttribute("viewBox", `0 0 1280 960`);
        svg.setAttribute("width", "320");
        svg.setAttribute("height", "240");
        svg.setAttribute("style", "background-color: #F5F5F6;");
        const elm = document.querySelector(`#${id}`);

        if (elm) {
            svg.innerHTML = elm.innerHTML;
        }

        return `data:image/svg+xml;base64,${window.btoa(
            unescape(
                encodeURIComponent(new XMLSerializer().serializeToString(svg))
            )
        )}`;
    };

    app.ports.saveDiagram.subscribe(
        async ({
            id,
            title,
            text,
            diagram,
            isPublic,
            isBookmark,
            isRemote,
            tags,
        }: Diagram) => {
            const thumbnail = svg2base64("usm");
            const createdAt = new Date().getTime();
            const diagramItem: DiagramItem = {
                id,
                title,
                text,
                thumbnail,
                diagram,
                isPublic,
                isRemote,
                isBookmark,
                tags,
                createdAt,
                updatedAt: createdAt,
            };

            if (isRemote) {
                app.ports.saveToRemote.send({
                    ...diagramItem,
                    isRemote: true,
                    id,
                    isPublic,
                });
                if (id) {
                    // @ts-ignore
                    await (await db()).diagrams.delete(id);
                }
            } else {
                const newId = id ?? uuidv4();
                // @ts-ignore
                await (await db()).diagrams.put({
                    ...diagramItem,
                    id: newId,
                    isPublic: false,
                });
                app.ports.saveToLocalCompleted.send({
                    ...diagramItem,
                    isRemote: false,
                    id: newId,
                    isPublic: false,
                });
            }
        }
    );

    app.ports.importDiagram.subscribe(async (diagrams: DiagramItem[]) => {
        // @ts-ignore
        await (await db()).diagrams.bulkPut(diagrams);
        app.ports.reload.send("");
    });

    app.ports.removeDiagrams.subscribe(async (diagram: Diagram) => {
        const { id, title, isRemote } = diagram;
        if (
            window.confirm(
                `Are you sure you want to delete "${title}" diagram?`
            )
        ) {
            if (isRemote) {
                app.ports.removeRemoteDiagram.send(diagram);
            } else {
                // @ts-ignore
                await (await db()).diagrams.delete(id);
                app.ports.reload.send("");
            }
        }
    });

    app.ports.getDiagram.subscribe(async (diagramId: string) => {
        // @ts-ignore
        const diagram = await (await db()).diagrams.get(diagramId);
        app.ports.gotLocalDiagramJson.send({
            ...diagram,
            isPublic: false,
            isRemote: false,
        });
    });

    app.ports.getDiagrams.subscribe(async () => {
        // @ts-ignore
        const diagrams = await (await db()).diagrams
            .orderBy("updatedAt")
            .reverse()
            .toArray();
        app.ports.gotLocalDiagramsJson.send(
            diagrams.map((d: Diagram) => ({
                ...d,
                isPublic: false,
                isRemote: false,
            }))
        );
    });
};
