import * as jsPDF from "jspdf";
import html2canvas from "html2canvas";
import { loadSettings } from "./settings";
import { DownloadInfo } from "./model";

// @ts-ignore
window.html2canvas = html2canvas;

// @ts-ignore
export const initDowonlad = app => {
    const createSvg = (id: string, width: number, height: number) => {
        const svg = document.createElementNS(
            "http://www.w3.org/2000/svg",
            "svg"
        );
        const svgWidth = width;
        const svgHeight = height;
        const element = document.querySelector(`#${id}`);
        svg.setAttribute("viewBox", `0 0 ${svgWidth} ${svgHeight}`);
        svg.setAttribute("width", width.toString());
        svg.setAttribute("height", height.toString());
        svg.setAttribute("style", "background-color: transparent;");

        if (element) {
            svg.innerHTML = element.innerHTML;
        }

        return svg;
    };

    // @ts-ignore
    const createImage = ({ id, width, height, scale = 1, callback }) => {
        const canvas = document.createElement("canvas");
        const svgWidth = width;
        const svgHeight = height;
        // @ts-ignore
        canvas.setAttribute("width", svgWidth * scale);
        // @ts-ignore
        canvas.setAttribute("height", svgHeight * scale);
        canvas.style.display = "none";

        const context = canvas.getContext("2d");

        if (context) {
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
                new XMLSerializer().serializeToString(
                    createSvg(id, width, height)
                )
            )}`;
        }
    };

    app.ports.downloadSvg.subscribe(
        ({ id, width, height, x, y }: DownloadInfo) => {
            app.ports.startDownload.send({
                content: new XMLSerializer().serializeToString(
                    createSvg(id, width, height)
                ),
                extension: ".svg",
                mimeType: "image/svg+xml"
            });
            app.ports.downloadCompleted.send([x, y]);
        }
    );

    app.ports.downloadPdf.subscribe(
        ({ id, width, height, title, x, y }: DownloadInfo) => {
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
                    callback: (url: string) => {
                        const printPage = (printedHeight: number) => {
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
                    callback: (url: string) => {
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
        }
    );

    app.ports.downloadPng.subscribe(
        ({ id, width, height, title, x, y }: DownloadInfo) => {
            createImage({
                id,
                width,
                height,
                scale: 2,
                callback: (url: string) => {
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
        }
    );

    app.ports.downloadHtml.subscribe((_: DownloadInfo) => {
        const doc = document.documentElement;

        if (!doc) return;

        const element = doc.querySelector("#usm-area");

        if (element) {
            const e = element.cloneNode(true);
            const elm = e as Element;

            const minimap = elm.querySelector(".minimap");
            const zoomControl = elm.querySelector("#zoom-control");

            if (minimap) {
                minimap.remove();
            }

            if (zoomControl) {
                zoomControl.remove();
            }
            app.ports.startDownload.send({
                content: `<html>${elm.outerHTML}</html>`,
                extension: ".html",
                mimeType: "text/html"
            });
        }
    });
};
