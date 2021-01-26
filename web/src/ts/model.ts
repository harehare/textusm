type DiagramItem = {
    id: string;
    title: string;
    text: string;
    thumbnail: string;
    diagram: string;
    isBookmark: boolean;
    isPublic: boolean;
    isRemote: boolean;
    tags: string[] | null;
    createdAt: number;
    updatedAt: number;
};

type Diagram = {
    id: string;
    title: string;
    text: string;
    diagram: string;
    isPublic: boolean;
    isRemote: boolean;
    isBookmark: boolean;
    tags: string[] | null;
};

type DownloadInfo = {
    width: number;
    height: number;
    id: string;
    title: string;
    text: string;
    x: number;
    y: number;
    diagramType: string;
};

type ImageInfo = {
    id: string;
    width: number;
    height: number;
    scale: number;
    callback: (url: string) => void;
};

type Settings = {
    font: string;
    position: number;
    text: string;
    title: string | null;
    diagramId: string | null;
    storyMap: DiagramSettings;
    diagram: Diagram | null;
};

type DiagramSettings = {
    font: string;
    size: Size;
    color: ColorSettings;
    backgroundColor: string;
    zoomControl: boolean;
    scale: number;
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

export {
    ImageInfo,
    Settings,
    Diagram,
    DownloadInfo,
    Color,
    ColorSettings,
    Size,
    DiagramSettings,
    DiagramItem,
};
