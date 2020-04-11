export type Kanban = {
  name: "Kanban";
  lists: KanbanList[];
};

export type KanbanList = {
  name: string;
  cards: KanbanCard[];
};

export type KanbanCard = {
  text: string;
};
