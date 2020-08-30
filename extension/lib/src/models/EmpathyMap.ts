import { CanvasItem, toString as canvasItemToString } from "./CancasItem";

type EmpathyMap = {
  name: "EmpathyMap";
  imageUrl: string;
  says: CanvasItem;
  thinks: CanvasItem;
  does: CanvasItem;
  feels: CanvasItem;
};

function toString(empathyMap: EmpathyMap): string {
  const items = ["says", "thinks", "does", "feels"];

  return `${empathyMap.imageUrl}\n${items
    .map((item) => {
      return canvasItemToString(empathyMap[item]);
    })
    .join("")}`;
}

export { EmpathyMap, toString };
