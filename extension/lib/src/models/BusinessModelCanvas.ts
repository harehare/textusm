import { CanvasItem } from "./CanvasItem";

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

let BusinessModelCanvas = {
  toString: (businessModelCanvas: BusinessModelCanvas): string => {
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
        return CanvasItem.toString(businessModelCanvas[item]);
      })
      .join("");
  },
};

export { BusinessModelCanvas };
