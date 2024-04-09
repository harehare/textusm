export type DiagramItem = {
  id: string;
  title: string;
  text: string;
  thumbnail: string;
  diagram: string;
  isBookmark: boolean;
  isPublic: boolean;
  location: DiagramLocation;
  createdAt: number;
  updatedAt: number;
};

type Theme = 'system' | 'dark' | 'light';
type DiagramLocation = 'gist' | 'local' | 'localfilesystem' | 'remote';

export type Diagram = Omit<DiagramItem, 'createdAt' | 'updatedAt' | 'thumbnail'>;

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
  | 'KeyboardLayout'
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
  diagramSettings?: DiagramSettings;
  storyMap?: DiagramSettings;
  diagram: Diagram | undefined;
  location: DiagramLocation | undefined;
  theme: Theme | undefined;
  editor: {
    fontSize: number;
    wordWrap: boolean;
    showLineNumber: boolean;
  };
  splitDirection: 'vertical' | 'horizontal';
};

export type DiagramSettings = {
  font: string;
  size: Size;
  color: ColorSettings;
  backgroundColor: string;
  zoomControl: boolean;
  scale: number;
  toolbar: boolean;
  lockEditing: boolean;
};

type Size = {
  width: number;
  height: number;
};

type ColorSettings = {
  activity: Color;
  task: Color;
  story: Color;
  line: string;
  label: string;
  text: string;
};

type Color = {
  color: string;
  backgroundColor: string;
};
