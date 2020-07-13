type MindMap = {
  name: "MindMap";
  node: MapNode;
};

type MapNode = {
  text: string;
  children: MapNode[];
};

type SiteMap = MindMap;

type ImpactMap = MindMap;

export { MindMap, MapNode, SiteMap, ImpactMap };
