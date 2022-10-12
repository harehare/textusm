export type DiagramItem = {
  id: string;
  title: string;
  text: string;
  thumbnail: string;
  diagram: string;
  isBookmark: boolean;
  isPublic: boolean;
  isRemote: boolean;
  location: 'local' | 'gist' | 'system' | 'googledrive';
  createdAt: number;
  updatedAt: number;
};

export type Diagram = {
  id: string;
  title: string;
  text: string;
  diagram: string;
  isPublic: boolean;
  isRemote: boolean;
  isBookmark: boolean;
  location: 'local' | 'gist' | 'system' | 'googledrive';
};

export type Theme = 'system' | 'dark' | 'light';

export type DiagramLocation = 'gist' | 'local' | 'localfilesystem' | 'remote';

export type DiagramType =
  | 'UserStoryMap'
  | 'OpportunityCanvas'
  | 'BusinessModelCanvas'
  | 'Fourls'
  | 'StartStopContinue'
  | 'Kpt'
  | 'UserPersona'
  | 'MindMap'
  | 'EmpathyMap'
  | 'SiteMap'
  | 'GanttChart'
  | 'ImpactMap'
  | 'ErDiagram'
  | 'Kanban'
  | 'Table'
  | 'SequenceDiagram'
  | 'Freeform'
  | 'UseCaseDiagram';

export type ExportInfo = {
  width: number;
  height: number;
  id: string;
  title: string;
  text: string;
  x: number;
  y: number;
  diagramType: string;
};

export type ImageInfo = {
  id: string;
  width: number;
  height: number;
  scale: number;
  callback: (url: string) => void;
};

export type Settings = {
  font: string;
  position: number;
  text: string;
  title: string | undefined;
  diagramId: string | undefined;
  storyMap: DiagramSettings;
  diagram: Diagram | undefined;
  location: DiagramLocation | undefined;
  theme: Theme | undefined;
};

export type DiagramSettings = {
  font: string;
  size: Size;
  color: ColorSettings;
  backgroundColor: string;
  zoomControl: boolean;
  scale: number;
  toolbar: boolean;
};

export type Size = {
  width: number;
  height: number;
};

export type ColorSettings = {
  activity: Color;
  task: Color;
  story: Color;
  line: string;
  label: string;
  text: string;
};

export type Color = {
  color: string;
  backgroundColor: string;
};
