export const initDowonlad = app => {
    const createSvg = (id, width, height) => {
        const svg = document.createElementNS(
            "http://www.w3.org/2000/svg",
            "svg"
        );
        svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
        svg.setAttribute("width", width);
        svg.setAttribute("height", height);
        svg.setAttribute("style", "background-color: #F5F5F6;");
        svg.innerHTML = document.querySelector(`#${id}`).innerHTML;

        return svg;
    };
    app.ports.downloadSvg.subscribe(({ id, width, height }) => {
        app.ports.startDownloadSvg.send(
            new XMLSerializer().serializeToString(createSvg(id, width, height))
        );
    });

    app.ports.downloadPng.subscribe(({ id, width, height, title }) => {
        const canvas = document.createElement("canvas");
        canvas.setAttribute("width", width);
        canvas.setAttribute("height", height);
        canvas.style.display = "none";

        const context = canvas.getContext("2d");
        const img = new Image();
        img.addEventListener(
            "load",
            () => {
                context.drawImage(img, 0, 0);

                const a = document.createElement("a");
                const url = canvas.toDataURL("image/png");
                a.setAttribute("download", title);
                a.setAttribute("href", url);
                a.style.display = "none";
                a.click();

                setTimeout(function() {
                    window.URL.revokeObjectURL(url);
                    canvas.remove();
                    a.remove();
                }, 10);
            },
            false
        );
        img.src = `data:image/svg+xml;utf8,${encodeURIComponent(
            new XMLSerializer().serializeToString(createSvg(id, width, height))
        )}`;
    });
};
