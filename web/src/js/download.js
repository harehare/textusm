import * as jsPDF from "jspdf";
import html2canvas from "html2canvas";

window.html2canvas = html2canvas;

export const initDowonlad = app => {
    const createSvg = (id, width, height) => {
        const svg = document.createElementNS(
            "http://www.w3.org/2000/svg",
            "svg"
        );
        const svgWidth = width;
        const svgHeight = height;
        svg.setAttribute("viewBox", `0 0 ${svgWidth} ${svgHeight}`);
        svg.setAttribute("width", width);
        svg.setAttribute("height", height);
        svg.setAttribute("style", "background-color: transparent;");
        svg.innerHTML = document.querySelector(`#${id}`).innerHTML;

        return svg;
    };

    const createImage = ({ id, width, height, scale = 1, callback }) => {
        const canvas = document.createElement("canvas");
        const svgWidth = width;
        const svgHeight = height;
        canvas.setAttribute("width", svgWidth * scale);
        canvas.setAttribute("height", svgHeight * scale);
        canvas.style.display = "none";

        const context = canvas.getContext("2d");
        context.scale(scale, scale);
        const img = new Image();
        img.addEventListener(
            "load",
            () => {
                context.drawImage(img, 0, 0);
                const url = canvas.toDataURL("image/png");
                callback(url);
            },
            false
        );
        img.src = `data:image/svg+xml;utf8,${encodeURIComponent(
            new XMLSerializer().serializeToString(createSvg(id, width, height))
        )}`;
    };
    app.ports.downloadSvg.subscribe(({ id, width, height, x, y }) => {
        app.ports.startDownloadSvg.send(
            new XMLSerializer().serializeToString(createSvg(id, width, height))
        );
        app.ports.downloadCompleted.send([x, y]);
    });

    app.ports.downloadPdf.subscribe(({ id, width, height, title, x, y }) => {
        if (location.pathname === "/md") {
            const doc = new jsPDF({
                orientation: "p",
                unit: "px",
                compress: true
            });
            const pageWidth = doc.internal.pageSize.width;
            const pageHeight = doc.internal.pageSize.height;
            const rate = pageWidth / width;
            const canvasHeight = height * rate;

            createImage({
                id,
                width,
                height,
                scale: 1.1,
                callback: url => {
                    const printPage = printedHeight => {
                        if (printedHeight > canvasHeight) {
                            return;
                        }

                        if (printedHeight > 0) {
                            doc.addPage();
                        }
                        doc.addImage(
                            url,
                            "PNG",
                            8,
                            printedHeight * -1,
                            width,
                            0
                        );
                        printPage(printedHeight + pageHeight);
                    };

                    printPage(0);
                    doc.save(title);
                    app.ports.downloadCompleted.send([x, y]);
                }
            });
        } else {
            createImage({
                id,
                width,
                height,
                scale: 2,
                callback: url => {
                    const doc = new jsPDF({
                        orientation: "l",
                        unit: "px",
                        compress: true
                    });
                    const pageWidth = doc.internal.pageSize.getWidth();
                    doc.addImage(
                        url,
                        "PNG",
                        0,
                        0,
                        width * (pageWidth / width),
                        height * (pageWidth / width)
                    );
                    doc.save(title);
                    app.ports.downloadCompleted.send([x, y]);
                }
            });
        }
    });

    app.ports.downloadPng.subscribe(({ id, width, height, title, x, y }) => {
        createImage({
            id,
            width,
            height,
            scale: 2,
            callback: url => {
                const a = document.createElement("a");
                a.setAttribute("download", title);
                a.setAttribute("href", url);
                a.style.display = "none";
                a.click();

                setTimeout(function() {
                    window.URL.revokeObjectURL(url);
                    a.remove();
                }, 10);
                app.ports.downloadCompleted.send([x, y]);
            }
        });
    });
};
