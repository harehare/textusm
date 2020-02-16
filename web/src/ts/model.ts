export interface DiagramItem {
    title: string;
    text: string;
    thumbnail: string;
    diagram: string;
    isBookmark: boolean;
    isPublic: boolean;
    createdAt: number;
    updatedAt: number;
}

export interface Diagram {
    id: string;
    title: string;
    text: string;
    diagram: string;
    isPublic: boolean;
    isRemote: boolean;
    isBookmark: boolean;
}

export interface DownloadInfo {
    width: number;
    height: number;
    id: string;
    title: string;
    text: string;
    x: number;
    y: number;
    diagramType: string;
}

export interface Settings {
    font: string;
    position: number;
    text: string;
    title: string | null;
    diagramId: string | null;
    storyMap: DiagramSettings;
}

export interface DiagramSettings {
    font: string;
    size: Size;
    color: ColorSettings;
    backgroundColor: string;
}

export interface Size {
    width: number;
    height: number;
}

export interface ColorSettings {
    activity: Color;
    task: Color;
    story: Color;
    line: string;
    label: string;
    text: string;
}

export interface Color {
    color: string;
    backgroundColor: string;
}
