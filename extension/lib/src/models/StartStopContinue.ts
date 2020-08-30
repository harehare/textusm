import { CanvasItem, toString as canvasItemToString } from "./CancasItem";

type StartStopContinue = {
  name: "StartStopContinue";
  start: CanvasItem;
  stop: CanvasItem;
  continue: CanvasItem;
};

function toString(startStopContinue: StartStopContinue): string {
  const items = ["start", "stop", "continue"];

  return items
    .map((item) => {
      return canvasItemToString(startStopContinue[item]);
    })
    .join("");
}

export { StartStopContinue, toString };
