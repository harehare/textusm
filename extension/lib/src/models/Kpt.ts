import { CanvasItem, toString as canvasItemToString } from "./CancasItem";

type Kpt = {
  name: "Kpt";
  keep: CanvasItem;
  problem: CanvasItem;
  try: CanvasItem;
};

function toString(kpt: Kpt): string {
  const items = ["keep", "problem", "try"];

  return items
    .map((item) => {
      return canvasItemToString(kpt[item]);
    })
    .join("");
}

export { Kpt, toString };
