type Kanban = {
  name: "Kanban";
  lists: KanbanList[];
};

type KanbanList = {
  name: string;
  cards: KanbanCard[];
};

type KanbanCard = {
  text: string;
};

export { Kanban, KanbanList, KanbanCard };
