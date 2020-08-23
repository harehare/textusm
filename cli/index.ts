#!/usr/bin/env node
import { createCommand } from "commander";
import * as fs from "fs";
import * as puppeteer from "puppeteer";

const diagramMap = {
  user_story_map: "usm",
  opportunity_canvas: "opc",
  business_model_canvas: "bmc",
  "4ls": "4ls",
  start_stop_continue: "ssc",
  kpt: "kpt",
  userpersona: "persona",
  mind_map: "mmp",
  empathy_map: "emm",
  table: "table",
  site_map: "smp",
  gantt_chart: "gct",
  impact_map: "imm",
  er_diagram: "erd",
  kanban: "kanban",
  sequence_diagram: "sed",
};

const defaultWidth: number = 1280;
const defaultHeight: number = 1280;
const defaultSettings = {
  diagramId: null,
  editor: {
    fontSize: 12,
    showLineNumber: true,
    wordWrap: false,
  },
  font: "Nunito Sans",
  position: 0,
  text: "",
  title: "TestUSM",
  miniMap: false,
  storyMap: {
    font: "Nunito Sans",
    size: {
      width: 140,
      height: 65,
    },
    backgroundColor: "#F5F5F6",
    color: {
      activity: {
        color: "#FFFFFF",
        backgroundColor: "#266B9A",
      },
      task: {
        color: "#FFFFFF",
        backgroundColor: "#3E9BCD",
      },
      story: {
        color: "#000000",
        backgroundColor: "#FFFFFF",
      },
      comment: {
        color: "#000000",
        backgroundColor: "#F1B090",
      },
      backgroundColor: "F5F6F6",
      line: "#434343",
      label: "#8C9FAE",
    },
    title: null,
  },
};

const readConfigFile = (file: string | undefined) => {
  if (!file) {
    return defaultSettings;
  }
  try {
    return JSON.parse(fs.readFileSync(file).toString());
  } catch {
    return defaultSettings;
  }
};

interface CommandOptions {
  input: string;
  width: number;
  height: number;
  output: string;
  diagramType: keyof typeof diagramMap;
}

const program = createCommand();
const { configFile, input, width, height, output, diagramType } = program
  .version("0.6.2")
  .option("-c, --configFile [configFile]", "Config file.")
  .requiredOption("-i, --input <input>", "Input text file. Required.")
  .option("-w, --width <width>", "Width of the page. Optional. Default: 1024.")
  .option(
    "-H, --height <height>",
    "Height of the page. Optional. Default: 1024."
  )
  .requiredOption(
    "-o, --output [output]",
    "Output file. It should be svg, png, pdf or html."
  )
  .option(
    "-d, --diagramType [diagramType]",
    `Diagram type. It should be one of ${Object.keys(diagramMap).join(", ")}`
  )
  .parse();

if (diagramType && Object.keys(diagramMap).indexOf(diagramType) === -1) {
  console.error(`Output file must be ${Object.keys(diagramMap).join(", ")}`);
  process.exit(1);
}

if (!fs.existsSync(input)) {
  console.error(`${input} is not exists.  -i <input>`);
  process.exit(1);
}

if (output && !/\.(?:svg|png|pdf|html)$/.test(output)) {
  console.error(`Output file must be svg, png, html or pdf.`);
  process.exit(1);
}

const options: CommandOptions = {
  input,
  width: width ? parseInt(width) : defaultWidth,
  height: height ? parseInt(height) : defaultHeight,
  output,
  diagramType: (diagramType ? diagramType : "usm") as keyof typeof diagramMap,
};

(async () => {
  const browser = await puppeteer.launch();
  const configJson = readConfigFile(configFile);
  configJson.text = fs.readFileSync(input, "utf-8");

  if (configJson.text === "") {
    console.error(`${input} is empty file.`);
    process.exit(1);
  }

  try {
    const page = await browser.newPage();
    page.setViewport({
      width: options.width,
      height: options.height,
    });
    await page.goto(
      `https://app.textusm.com/view/${
        diagramMap[options.diagramType]
      }/${encodeURIComponent(JSON.stringify(configJson))}`
    );

    await page.waitForSelector("#usm", {
      timeout: 1000,
      visible: true,
    });

    if (output.endsWith(".svg")) {
      const svg = await page.$eval("#usm-area", (item) => {
        return item.innerHTML;
      });
      fs.writeFileSync(
        output,
        `<?xml version="1.0"?>
                ${svg
                  .replace("<div></div>", "")
                  .replace(
                    "<svg",
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
                  )
                  .split("<div")
                  .join('<div xmlns="http://www.w3.org/1999/xhtml"')
                  .split("<img")
                  .join('<img xmlns="http://www.w3.org/1999/xhtml"')}`
      );
    } else if (output.endsWith(".png")) {
      const clip = await page.$eval("#usm", (svg) => {
        const rect = svg.getBoundingClientRect();
        return {
          x: rect.left,
          y: rect.top,
          width: rect.width,
          height: rect.height,
        };
      });
      await page.screenshot({
        path: output,
        clip,
        omitBackground: true,
      });
    } else if (output.endsWith(".pdf")) {
      await page.pdf({
        path: output,
        landscape: true,
        printBackground: false,
      });
    } else if (output.endsWith(".html")) {
      const html = await page.evaluate(() => {
        const doc = document.documentElement;
        doc.querySelectorAll("script").forEach((e) => {
          e.remove();
        });
        doc.querySelectorAll("link").forEach((e) => {
          e.remove();
        });
        return `<html>${doc.innerHTML}</html>`;
      });
      fs.writeFileSync(output, html);
    }

    browser.close();
  } catch (e) {
    console.log(e);
    console.error("Internal error.");
    browser.close();
  }
})().catch((e) => {
  console.log(e);
  console.error("Internal error.");
});
