import Dexie from "dexie";
import * as uuid from "uuid/v4";

const Version = 1;
const db = new Dexie("textusm");
const svg2base64 = id => {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("viewBox", `0 0 1280 1024`);
    svg.setAttribute("width", "250");
    svg.setAttribute("height", "150");
    svg.setAttribute("style", "background-color: #F5F5F6;");
    svg.innerHTML = document.querySelector(`#${id}`).innerHTML;

    return `data:image/svg+xml;base64,${window.btoa(
        unescape(encodeURIComponent(new XMLSerializer().serializeToString(svg)))
    )}`;
};

db.version(Version).stores({
    diagrams: "++id,title,text,thumbnail,diagramPath,createdAt,updatedAt"
});

export const initDB = app => {
    app.ports.saveDiagram.subscribe(
        async ([
            { id, title, text, diagramPath, isPublic, isRemote },
            nextUrl
        ]) => {
            const thumbnail = svg2base64("usm");
            const createdAt = new Date().getTime();
            const diagramItem = {
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
                await db.diagrams.delete(diagramItem.id).catch(e => {
                    console.error(e);
                });
            } else {
                await db.diagrams.put({ id: id ? id : uuid(), ...diagramItem });
            }

            if (nextUrl) {
                app.ports.moveTo.send(nextUrl);
            }
        }
    );

    app.ports.removeDiagrams.subscribe(async diagram => {
        const { id, title, isRemote } = diagram;
        if (
            window.confirm(
                `Are you sure you want to delete "${title}" diagram?`
            )
        ) {
            if (isRemote) {
                app.ports.removeRemoteDiagram.send(diagram);
            } else {
                await db.diagrams.delete(id);
                app.ports.removedDiagram.send([diagram, true]);
            }
        }
    });

    app.ports.getDiagrams.subscribe(async () => {
        const diagrams = await db.diagrams
            .orderBy("updatedAt")
            .reverse()
            .toArray();
        app.ports.loadLocalDiagrams.send(
            diagrams.map(d => ({
                users: null,
                ownerId: null,
                isPublic: false,
                isRemote: false,
                ...d
            }))
        );
    });
};
