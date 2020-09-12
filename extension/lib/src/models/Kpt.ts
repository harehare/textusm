import { CanvasItem } from "./CanvasItem";

type Kpt = {
  name: "Kpt";
  keep: CanvasItem;
  problem: CanvasItem;
  try: CanvasItem;
};

let Kpt = {
  toString: (kpt: Kpt): string => {
    const items = ["keep", "problem", "try"];

    return items
      .map((item) => {
        return CanvasItem.toString(kpt[item]);
      })
      .join("");
  },
};

export { Kpt };
