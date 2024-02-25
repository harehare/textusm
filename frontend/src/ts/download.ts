import { optimize } from 'svgo';
import JsPdf from 'jspdf';
import type { ElmApp } from './elm';
import type { ExportInfo, ImageInfo } from './model';

export const initDownload = (app: ElmApp): void => {
  const createSvg = async (id: string, width: number, height: number): Promise<string> => {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    const element = document.querySelector(`#${id}`);
    svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
    svg.setAttribute('width', width.toString());
    svg.setAttribute('height', height.toString());

    if (element) {
      element.querySelector('#pattern')?.remove();
      element.querySelector('#pattern-rect')?.remove();
      svg.setAttribute('style', element.getAttribute('style') ?? '');
      svg.innerHTML = element.innerHTML;
    }

    return optimize(new XMLSerializer().serializeToString(svg), {
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
    }).data.replace(/ style="background-color:[^"]+"/, '');
  };

  const createImage = async ({ id, width, height, scale = 1, callback }: ImageInfo) => {
    const canvas = document.createElement('canvas');
    const svgWidth = width;
    const svgHeight = height;
    canvas.setAttribute('width', (svgWidth * scale).toString());
    canvas.setAttribute('height', (svgHeight * scale).toString());
    canvas.style.display = 'none';

    const context = canvas.getContext('2d');

    if (context) {
      context.scale(scale, scale);
      const img = new Image();
      img.addEventListener(
        'load',
        () => {
          context.drawImage(img, 0, 0, width, height);
          const url = canvas.toDataURL('image/png');
          callback(url);
        },
        false
      );
      img.src = `data:image/svg+xml;utf8,${encodeURIComponent(await createSvg(id, width, height))}`;
    }
  };

  app.ports.downloadSvg.subscribe(async ({ id, width, height, x, y }: ExportInfo) => {
    app.ports.startDownload.send({
      content: await createSvg(id, width, height),
      extension: '.svg',
      mimeType: 'image/svg+xml',
    });
    app.ports.downloadCompleted.send([Math.floor(x), Math.floor(y)]);
  });

  app.ports.downloadPdf.subscribe(async ({ id, width, height, title, x, y }: ExportInfo) => {
    const html2canvas = await import('html2canvas').catch(() => null);

    if (!html2canvas) {
      app.ports.sendErrorNotification.send('Failed to load chunks. Please reload.');
    }

    // @ts-expect-error: Unreachable code error
    window.html2canvas = html2canvas.default;

    if (window.location.pathname === '/md') {
      const pdfDocument = new JsPdf({
        orientation: 'p',
        unit: 'px',
        compress: true,
      });
      const pageWidth = pdfDocument.internal.pageSize.width;
      const pageHeight = pdfDocument.internal.pageSize.height;
      const rate = pageWidth / width;
      const canvasHeight = height * rate;

      await createImage({
        id,
        width,
        height,
        scale: 1.1,
        callback(url: string) {
          const printPage = (printedHeight: number) => {
            if (printedHeight > canvasHeight) {
              return;
            }

            if (printedHeight > 0) {
              pdfDocument.addPage();
            }

            pdfDocument.addImage(url, 'PNG', 8, printedHeight * -1, width, 0);
            printPage(printedHeight + pageHeight);
          };

          printPage(0);
          pdfDocument.save(title);
          app.ports.downloadCompleted.send([Math.floor(x), Math.floor(y)]);
        },
      }).catch(() => {
        app.ports.sendErrorNotification.send('Failed to create image.');
      });
    } else {
      await createImage({
        id,
        width,
        height,
        scale: 3,
        callback(url: string) {
          const pdfDocument = new JsPdf({
            orientation: 'l',
            unit: 'px',
            compress: true,
          });
          const pageWidth = pdfDocument.internal.pageSize.getWidth();
          pdfDocument.addImage(url, 'PNG', 0, 0, width * (pageWidth / width), height * (pageWidth / width));
          pdfDocument.save(title);
          app.ports.downloadCompleted.send([Math.floor(x), Math.floor(y)]);
        },
      }).catch(() => {
        app.ports.sendErrorNotification.send('Failed to create image.');
      });
    }
  });

  app.ports.downloadPng.subscribe(async ({ id, width, height, title, x, y }: ExportInfo) => {
    await createImage({
      id,
      width,
      height,
      scale: 2,
      callback(url: string) {
        const a = document.createElement('a');
        a.setAttribute('download', title);
        a.setAttribute('href', url);
        a.style.display = 'none';
        a.click();

        setTimeout(() => {
          window.URL.revokeObjectURL(url);
          a.remove();
        }, 10);
        app.ports.downloadCompleted.send([Math.floor(x), Math.floor(y)]);
      },
    }).catch(() => {
      app.ports.sendErrorNotification.send('Failed to create image.');
    });
  });

  app.ports.copyToClipboardPng.subscribe(async ({ id, width, height, x, y }: ExportInfo) => {
    await createImage({
      id,
      width,
      height,
      scale: 2,
      async callback(url: string) {
        const dataUrl = url.split(',')[1];
        if (!dataUrl) {
          return;
        }

        const binay = window.atob(dataUrl);
        const buffer = new Uint8Array(binay.length);
        for (let i = 0; i < binay.length; i++) {
          buffer[i] = binay.codePointAt(i) ?? 0;
        }

        const blob = new Blob([buffer.buffer], {
          type: 'image/png',
        });
        await navigator.clipboard.write([
          new ClipboardItem({
            [blob.type]: blob,
          }),
        ]);
        window.URL.revokeObjectURL(url);
        app.ports.downloadCompleted.send([Math.floor(x), Math.floor(y)]);
      },
    }).catch(() => {
      app.ports.sendErrorNotification.send('Failed to create image.');
    });
  });

  app.ports.downloadHtml.subscribe(() => {
    const documentElement = document.documentElement;

    if (!documentElement) {
      return;
    }

    const element = documentElement.querySelector('#usm-area');

    if (element) {
      const elm = element.cloneNode(true) as Element;
      const minimap = elm.querySelector('.minimap');
      const zoomControl = elm.querySelector('#zoom-control');

      if (minimap) {
        minimap.remove();
      }

      if (zoomControl) {
        zoomControl.remove();
      }

      app.ports.startDownload.send({
        content: `<html>${elm.outerHTML}</html>`,
        extension: '.html',
        mimeType: 'text/html',
      });
    }
  });

  app.ports.copyBase64.subscribe(async ({ id, width, height, x, y }: ExportInfo) => {
    const svg = `data:image/svg+xml;utf8,${encodeURIComponent(await createSvg(id, width, height))}`;
    const item = new ClipboardItem({
      //
      'text/plain': new Blob([svg], {
        type: 'text/plain',
      }),
    });
    await navigator.clipboard.write([item]);
    app.ports.downloadCompleted.send([Math.floor(x), Math.floor(y)]);
  });
};
