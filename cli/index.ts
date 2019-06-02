#!/usr/bin/env node
import * as commander from 'commander';
import * as fs from 'fs';
import * as puppeteer from 'puppeteer';

const width = 1024;
const height = 1024;
const defaultSettings = {
  font: 'Open Sans',
  position: 0,
  text: '',
  title: 'TestUSM',
  storyMap: {
    font: 'Open Sans',
    size: {
      width: 140,
      height: 65
    },
    backgroundColor: '#F5F5F6',
    color: {
      activity: {
        color: '#FFFFFF',
        backgroundColor: '#266B9A'
      },
      task: {
        color: '#FFFFFF',
        backgroundColor: '#3E9BCD'
      },
      story: {
        color: '#000000',
        backgroundColor: '#FFFFFF'
      },
      comment: {
        color: '#000000',
        backgroundColor: '#F1B090'
      },
      backgroundColor: 'F5F6F6',
      line: '#434343',
      label: '#8C9FAE'
    }
  }
};

const readConfigFile = (file: string) => {
  try {
    return JSON.parse(fs.readFileSync(file).toString());
  } catch {
    return defaultSettings;
  }
};

const { configFile, input, output } = commander
  .version('0.0.5')
  .option('-c, --configFile [configFile]', 'Config file.')
  .option('-i, --input <input>', 'Input text file. Required.')
  .option('-o, --output [output]', 'Output file. It should be svg, png, pdf or html.')
  .parse(process.argv);

if (!input) {
  console.error('Input file is required.  -i <input>');
  process.exit(1);
}

if (!output) {
  console.error('Output file is required.  -o <output>');
  process.exit(1);
}

if (!fs.existsSync(input)) {
  console.error(`${input} is not exists.  -i <input>`);
  process.exit(1);
}

if (output && !/\.(?:svg|png|pdf|html)$/.test(output)) {
  console.error(`Output file must be svg, png or pdf.`);
  process.exit(1);
}

(async () => {
  const browser = await puppeteer.launch();
  const configJson = readConfigFile(configFile);
  configJson.text = fs.readFileSync(input, 'utf-8');

  if (configJson.text === '') {
    console.error(`${input} is empty file.`);
    process.exit(1);
  }

  try {
    const page = await browser.newPage();
    page.setViewport({
      width,
      height
    });
    await page.goto(`https://textusm.web.app/view/${encodeURIComponent(JSON.stringify(configJson))}`);

    await page.waitForSelector('#usm', {
      timeout: 10000,
      visible: true
    });

    if (output.endsWith('svg')) {
      const svg = await page.$eval('#usm-area', item => {
        return item.innerHTML;
      });
      fs.writeFileSync(
        output,
        `<?xml version="1.0"?>
                ${svg
                  .replace('<div></div>', '')
                  .replace('<svg', '<svg xmlns="http://www.w3.org/2000/svg" ')
                  .split('<div')
                  .join('<div xmlns="http://www.w3.org/1999/xhtml"')}`
      );
    } else if (output.endsWith('png')) {
      const clip = await page.$eval('#usm', svg => {
        const rect = svg.getBoundingClientRect();
        return {
          x: rect.left,
          y: rect.top,
          width: rect.width,
          height: rect.height
        };
      });
      await page.screenshot({
        path: output,
        clip,
        omitBackground: true
      });
    } else if (output.endsWith('pdf')) {
      await page.pdf({
        path: output,
        landscape: true,
        printBackground: false
      });
    } else if (output.endsWith('html')) {
      const html = await page.evaluate(() => {
        const doc = document.documentElement;
        console.log(doc.querySelectorAll('script'));
        doc.querySelectorAll('script').forEach(e => {
          e.remove();
        });
        doc.querySelectorAll('link').forEach(e => {
          e.remove();
        });
        return `<html>${doc.innerHTML}</html>`;
      });
      fs.writeFileSync(output, html);
    }

    browser.close();
  } catch (e) {
    console.log(e);
    console.error('Internal error.');
    browser.close();
  }
})().catch(e => {
  console.log(e);
  console.error('Internal error.');
});
