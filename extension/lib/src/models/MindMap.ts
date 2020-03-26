export type MindMap = {
  name: "MindMap";
  node: MapNode;
};

export type MapNode = {
  text: string;
  children: MapNode[];
};

export type SiteMap = MindMap;

export type ImpactMap = MindMap;
