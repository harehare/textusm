import { CanvasItem, toString as canvasItemToString } from "./CancasItem";

type FourLs = {
  name: "4Ls";
  liked: CanvasItem;
  learned: CanvasItem;
  lacked: CanvasItem;
  longedFor: CanvasItem;
};

function toString(fourls: FourLs): string {
  const items = ["liked", "learned", "lacked", "longedFor"];

  return items
    .map((item) => {
      return canvasItemToString(fourls[item]);
    })
    .join("");
}

export { FourLs, toString };
