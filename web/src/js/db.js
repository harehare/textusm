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

export const setUpDB = app => {
    app.ports.saveDiagram.subscribe(
        async ({ id, title, text, diagramPath }) => {
            const thumbnail = svg2base64("usm");
            const createdAt = new Date().getTime();

            await db.diagrams.put({
                id: id ? id : uuid(),
                title,
                text,
                thumbnail,
                diagramPath,
                createdAt,
                updatedAt: createdAt
            });
        }
    );

    app.ports.removeDiagrams.subscribe(async ({ id, title }) => {
        if (
            window.confirm(
                `Are you sure you want to delete "${title}" diagram?`
            )
        ) {
            await db.diagrams.delete(id);
            app.ports.removedDiagram.send(true);
        }
    });

    app.ports.getDiagrams.subscribe(async () => {
        const diagrams = await db.diagrams
            .orderBy("updatedAt")
            .reverse()
            .toArray();
        app.ports.showDiagrams.send(diagrams);
    });
};
