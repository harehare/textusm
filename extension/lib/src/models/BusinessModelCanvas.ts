import { CanvasItem, toString as canvasItemToString } from "./CancasItem";

type BusinessModelCanvas = {
  name: "BusinessModelCanvas";
  keyPartners: CanvasItem;
  customerSegments: CanvasItem;
  valueProposition: CanvasItem;
  keyActivities: CanvasItem;
  channels: CanvasItem;
  revenueStreams: CanvasItem;
  costStructure: CanvasItem;
  keyResources: CanvasItem;
  customerRelationships: CanvasItem;
};

function toString(businessModelCanvas: BusinessModelCanvas): string {
  const items = [
    "keyPartners",
    "customerSegments",
    "valueProposition",
    "keyActivities",
    "channels",
    "revenueStreams",
    "costStructure",
    "keyResources",
    "customerRelationships",
  ];

  return items
    .map((item) => {
      return canvasItemToString(businessModelCanvas[item]);
    })
    .join("");
}

export { BusinessModelCanvas, toString };
