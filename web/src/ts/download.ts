import { DownloadInfo, ImageInfo } from "./model";
import { ElmApp } from "./elm";

export const initDownload = (app: ElmApp): void => {
    const createSvg = (id: string, width: number, height: number) => {
        const svg = document.createElementNS(
            "http://www.w3.org/2000/svg",
            "svg"
        );
        const element = document.querySelector(`#${id}`);
        svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
        svg.setAttribute("width", width.toString());
        svg.setAttribute("height", height.toString());

        if (element) {
            svg.setAttribute("style", element.getAttribute("style") ?? "");
            svg.innerHTML = element.innerHTML;
        }

        return svg;
    };

    const createImage = ({
        id,
        width,
        height,
        scale = 1,
        callback,
    }: ImageInfo) => {
        const canvas = document.createElement("canvas");
        const svgWidth = width;
        const svgHeight = height;
        canvas.setAttribute("width", (svgWidth * scale).toString());
        canvas.setAttribute("height", (svgHeight * scale).toString());
        canvas.style.display = "none";

        const context = canvas.getContext("2d");

        if (context) {
            context.scale(scale, scale);
            const img = new Image();
            img.addEventListener(
                "load",
                () => {
                    context.drawImage(img, 0, 0, width, height);
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
                mimeType: "image/svg+xml",
            });
            app.ports.downloadCompleted.send([Math.floor(x), Math.floor(y)]);
        }
    );

    app.ports.downloadPdf.subscribe(
        async ({ id, width, height, title, x, y }: DownloadInfo) => {
            // @ts-ignore
            window.html2canvas = (await import("html2canvas")).default;
            const JsPdf = (await import("jspdf")).default;

            if (window.location.pathname === "/md") {
                const doc = new JsPdf({
                    orientation: "p",
                    unit: "px",
                    compress: true,
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
                        app.ports.downloadCompleted.send([
                            Math.floor(x),
                            Math.floor(y),
                        ]);
                    },
                });
            } else {
                createImage({
                    id,
                    width,
                    height,
                    scale: 3,
                    callback: (url: string) => {
                        const doc = new JsPdf({
                            orientation: "l",
                            unit: "px",
                            compress: true,
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
                        app.ports.downloadCompleted.send([
                            Math.floor(x),
                            Math.floor(y),
                        ]);
                    },
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

                    setTimeout(() => {
                        window.URL.revokeObjectURL(url);
                        a.remove();
                    }, 10);
                    app.ports.downloadCompleted.send([
                        Math.floor(x),
                        Math.floor(y),
                    ]);
                },
            });
        }
    );

    app.ports.downloadHtml.subscribe(() => {
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
                mimeType: "text/html",
            });
        }
    });
};
