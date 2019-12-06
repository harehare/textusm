import Dexie from "dexie";
import * as uuid from "uuid/v4";
import { Diagram, DiagramItem } from "./model";

const Version = 1;
const db = new Dexie("textusm");
const svg2base64 = (id: string) => {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("viewBox", `0 0 1280 960`);
    svg.setAttribute("width", "320");
    svg.setAttribute("height", "240");
    svg.setAttribute("style", "background-color: #F5F5F6;");
    const elm = document.querySelector(`#${id}`);

    if (elm) {
        svg.innerHTML = elm.innerHTML;
    }

    return `data:image/svg+xml;base64,${window.btoa(
        unescape(encodeURIComponent(new XMLSerializer().serializeToString(svg)))
    )}`;
};

db.version(Version).stores({
    diagrams: "++id,title,text,thumbnail,diagramPath,createdAt,updatedAt"
});

// @ts-ignore
export const initDB = app => {
    app.ports.saveDiagram.subscribe(
        async ({
            id,
            title,
            text,
            diagramPath,
            isPublic,
            isRemote
        }: Diagram) => {
            const thumbnail = svg2base64("usm");
            const createdAt = new Date().getTime();
            const diagramItem: DiagramItem = {
                title,
                text,
                thumbnail,
                diagramPath,
                createdAt,
                updatedAt: createdAt
            };

            if (isRemote) {
                app.ports.saveToRemote.send({
                    isRemote: true,
                    id,
                    isPublic,
                    ownerId: null,
                    users: null,
                    ...diagramItem
                });
                // @ts-ignore
                await db.diagrams.delete(diagramItem.id).catch(e => {
                    console.error(e);
                });
            } else {
                // @ts-ignore
                await db.diagrams.put({ id: id ? id : uuid(), ...diagramItem });
            }
        }
    );

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
                await db.diagrams.delete(id);
                app.ports.removedDiagram.send([diagram, true]);
            }
        }
    });

    app.ports.getDiagrams.subscribe(async () => {
        // @ts-ignore
        const diagrams = await db.diagrams
            .orderBy("updatedAt")
            .reverse()
            .toArray();
        app.ports.gotLocalDiagrams.send(
            diagrams.map((d: Diagram) => ({
                users: null,
                ownerId: null,
                isPublic: false,
                isRemote: false,
                ...d
            }))
        );
    });
};
