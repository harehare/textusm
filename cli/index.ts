#!/usr/bin/env node
import { OptionValues, createCommand, parse } from "commander";
import * as fs from "fs";
import * as path from "path";
import * as puppeteer from "puppeteer";
import { html, DiagramType, Settings } from "./html";

const diagramMap: { [type: string]: DiagramType } = {
  user_story_map: "UserStoryMap",
  opportunity_canvas: "OpportunityCanvas",
  business_model_canvas: "BusinessModelCanvas",
  "4ls": "4Ls",
  start_stop_continue: "StartStopContinue",
  kpt: "Kpt",
  userpersona: "UserPersona",
  mind_map: "MindMap",
  empathy_map: "EmpathyMap",
  table: "Table",
  site_map: "SiteMap",
  gantt_chart: "GanttChart",
  impact_map: "ImpactMap",
  er_diagram: "ERDiagram",
  kanban: "Kanban",
  sequence_diagram: "SequenceDiagram",
  free_form: "Freeform",
};

const defaultSettings: Settings = {
  font: "Nunito Sans",
  showZoomControl: false,
  scale: 1.0,
  size: {
    width: 1024,
    height: 1024,
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
    line: "#434343",
    label: "#8C9FAE",
    text: "#111111",
  },
  diagramType: "UserStoryMap",
};

const readConfigFile = (file: string | undefined): Settings => {
  if (!file) {
    return defaultSettings;
  }
  try {
    return JSON.parse(fs.readFileSync(file).toString());
  } catch {
    return defaultSettings;
  }
};

const readStdin = async (): Promise<string> => {
  process.stdin.setEncoding("utf8");
  let text = "";
  for await (const chunk of process.stdin) text += chunk;
  return text;
};

interface Options extends OptionValues {
  configFile: string | undefined;
  input: string | undefined;
  width: number | undefined;
  height: number | undefined;
  output: string;
  diagramType: DiagramType | undefined;
}

const program = createCommand();
// @ts-ignore
const options = program
  // @ts-ignore
  .version("0.6.9")
  .option("-c, --configFile [configFile]", "Config file.")
  .option("-i, --input <input>", "Input text file.")
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
  .parse()
  .opts();

const {
  configFile,
  input,
  width,
  height,
  output,
  diagramType,
} = options as Options;

if (diagramType && Object.keys(diagramMap).indexOf(diagramType) === -1) {
  console.error(`Output file must be ${Object.keys(diagramMap).join(", ")}`);
  process.exit(1);
}

if (input && !fs.existsSync(input)) {
  console.error(`${input} is not exists.  -i <input>`);
  process.exit(1);
}

if (output && !/\.(?:svg|png|pdf|html)$/.test(output)) {
  console.error(`Output file must be svg, png, html or pdf.`);
  process.exit(1);
}

const writeResult = (output: string | undefined, result: string): void => {
  if (output) {
    fs.writeFileSync(output, result);
  } else {
    console.log(result);
  }
};

(async () => {
  const browser = await puppeteer.launch();
  const config = readConfigFile(configFile);
  const text = input ? fs.readFileSync(input, "utf-8") : await readStdin();
  const js = fs.readFileSync(
    path.join(
      path.resolve(__dirname),
      path.sep,
      "..",
      path.sep,
      "js",
      path.sep,
      "textusm.js"
    ),
    "utf-8"
  );

  if (text === "") {
    console.error(`${input} is empty file.`);
    process.exit(1);
  }

  try {
    const page = await browser.newPage();
    page.setViewport({
      width: width ?? config.size.width,
      height: height ?? config.size.height,
    });
    config.diagramType = diagramType
      ? diagramMap[diagramType as string]
      : "UserStoryMap";
    await page.setContent(html(text, js, config), { waitUntil: "load" });

    if (!output || output.endsWith(".svg")) {
      const svg = await page.$eval("#usm", (items) => {
        return items.outerHTML;
      });
      writeResult(
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
