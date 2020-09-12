import { CanvasItem } from "./CanvasItem";

type FourLs = {
  name: "4Ls";
  liked: CanvasItem;
  learned: CanvasItem;
  lacked: CanvasItem;
  longedFor: CanvasItem;
};

let FourLs = {
  toString: (fourls: FourLs): string => {
    const items = ["liked", "learned", "lacked", "longedFor"];

    return items
      .map((item) => {
        return CanvasItem.toString(fourls[item]);
      })
      .join("");
  },
};

export { FourLs };
