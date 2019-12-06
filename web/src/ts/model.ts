export interface DiagramItem {
    title: string;
    text: string;
    thumbnail: string;
    diagramPath: string;
    createdAt: number;
    updatedAt: number;
}

export interface Diagram {
    id: string;
    title: string;
    text: string;
    diagramPath: string;
    isPublic: boolean;
    isRemote: boolean;
}

export interface Settings {
    font: string;
    position: number;
    text: string;
    title: string | null;
    miniMap: boolean;
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
