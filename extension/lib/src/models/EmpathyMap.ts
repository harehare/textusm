import { CanvasItem } from "./CanvasItem";

type EmpathyMap = {
  name: "EmpathyMap";
  imageUrl: string;
  says: CanvasItem;
  thinks: CanvasItem;
  does: CanvasItem;
  feels: CanvasItem;
};

let EmpathyMap = {
  toString: (empathyMap: EmpathyMap): string => {
    const items = ["says", "thinks", "does", "feels"];

    return `${empathyMap.imageUrl}\n${items
      .map((item) => {
        return CanvasItem.toString(empathyMap[item]);
      })
      .join("")}`;
  },
};

export { EmpathyMap };
