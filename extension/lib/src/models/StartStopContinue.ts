import { CanvasItem } from "./CanvasItem";

type StartStopContinue = {
  name: "StartStopContinue";
  start: CanvasItem;
  stop: CanvasItem;
  continue: CanvasItem;
};

let StartStopContinue = {
  toString: (startStopContinue: StartStopContinue): string => {
    const items = ["start", "stop", "continue"];

    return items
      .map((item) => {
        return CanvasItem.toString(startStopContinue[item]);
      })
      .join("");
  },
};

export { StartStopContinue };
